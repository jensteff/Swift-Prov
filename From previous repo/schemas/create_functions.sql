--Create functions notes

SET search_path = public, pg_catalog;

--
-- Name: compare_run_by_annot_num_type; Type: TYPE; Schema: public; Owner: public
--

CREATE TYPE compare_run_by_annot_num_type AS (
	run_id character varying,
	name character varying,
	value numeric
);


ALTER TYPE public.compare_run_by_annot_num_type OWNER TO public;

--
-- Name: compare_run_by_annot_txt_type; Type: TYPE; Schema: public; Owner: public
--

CREATE TYPE compare_run_by_annot_txt_type AS (
	run_id character varying,
	name character varying,
	value character varying
);


ALTER TYPE public.compare_run_by_annot_txt_type OWNER TO public;

--
-- Name: compare_run_by_key_numeric_type; Type: TYPE; Schema: public; Owner: public
--

CREATE TYPE compare_run_by_key_numeric_type AS (
	run_id character varying,
	name character varying,
	value numeric
);


ALTER TYPE public.compare_run_by_key_numeric_type OWNER TO public;

--
-- Name: compare_run_by_key_text_type; Type: TYPE; Schema: public; Owner: public
--

CREATE TYPE compare_run_by_key_text_type AS (
	run_id character varying,
	name character varying,
	value character varying
);


ALTER TYPE public.compare_run_by_key_text_type OWNER TO public;

--
-- Name: compare_run_by_parameter_type; Type: TYPE; Schema: public; Owner: public
--

CREATE TYPE compare_run_by_parameter_type AS (
	run_id character varying,
	parameter character varying,
	value character varying
);


ALTER TYPE public.compare_run_by_parameter_type OWNER TO public;

--
-- Name: ancestors(character varying); Type: FUNCTION; Schema: public; Owner: public
--

CREATE FUNCTION ancestors(character varying) RETURNS SETOF character varying
    LANGUAGE sql
    AS $_$
  WITH RECURSIVE anc(ancestor,descendant) AS
  (    
       SELECT parent AS ancestor, child AS descendant 
       FROM   provenance_graph_edge 
       WHERE child=$1
     UNION
       SELECT provenance_graph_edge.parent AS ancestor, 
              anc.descendant AS descendant
       FROM   anc, provenance_graph_edge
       WHERE  anc.ancestor=provenance_graph_edge.child
  )
  SELECT ancestor FROM anc
$_$;


ALTER FUNCTION public.ancestors(character varying) OWNER TO public;

--
-- Name: compare_run(character varying[]); Type: FUNCTION; Schema: public; Owner: public
--

CREATE FUNCTION compare_run(VARIADIC args character varying[]) RETURNS SETOF record
    LANGUAGE plpgsql
    AS $$
DECLARE 
  i             INTEGER;
  q             VARCHAR;
  selectq       VARCHAR;
  fromq         VARCHAR;
  property      VARCHAR;
  property_type VARCHAR;
  function_name VARCHAR;
BEGIN 
  selectq := 'SELECT *';
  FOR i IN array_lower(args, 1)..array_upper(args, 1) LOOP
    property_type := split_part(args[i], '=', 1);
    property := split_part(args[i], '=', 2);
    CASE property_type
    WHEN 'parameter_name' THEN
      function_name := 'compare_run_by_parameter';
    WHEN 'annot_num' THEN
      function_name := 'compare_run_by_annot_num';
    WHEN 'annot_text' THEN
      function_name := 'compare_run_by_annot_text';
    END CASE;
    IF i = 1 THEN
      fromq := function_name || '(''' || property || ''') as t' || i;
    ELSE
      fromq := fromq || ' INNER JOIN ' || function_name || '(''' || property || ''') as t' || i || ' USING (run_id)';
    END IF;
  END LOOP;
  q := selectq || ' FROM ' || fromq;
  RETURN QUERY EXECUTE q;
END;
$$;


ALTER FUNCTION public.compare_run(VARIADIC args character varying[]) OWNER TO public;

--
-- Name: compare_run_by_annot_num(character varying); Type: FUNCTION; Schema: public; Owner: public
--

CREATE FUNCTION compare_run_by_annot_num(name character varying) RETURNS SETOF compare_run_by_annot_num_type
    LANGUAGE sql
    AS $_$
    SELECT fun_call.run_id, annot_dataset_num.name, annot_dataset_num.value
    FROM   annot_dataset_num,dataset_io,dataset_containment,fun_call
    WHERE  annot_dataset_num.dataset_id=dataset_containment.in_id AND dataset_containment.out_id=dataset_io.dataset_id AND
           dataset_io.function_call_id=fun_call.id AND annot_dataset_num.name=$1
  UNION
    SELECT fun_call.run_id, annot_dataset_num.name, annot_dataset_num.value 
    FROM   fun_call, dataset_io, annot_dataset_num
    WHERE  fun_call.id=dataset_io.function_call_id and dataset_io.dataset_id=annot_dataset_num.dataset_id and
           annot_dataset_num.name=$1
  UNION
    SELECT fun_call.run_id, annot_function_call_num.name, annot_function_call_num.value 
    FROM   fun_call, annot_function_call_num
    WHERE  fun_call.id=annot_function_call_num.function_call_id and annot_function_call_num.name=$1
  UNION
    SELECT run.id as run_id, annot_script_run_num.name, annot_script_run_num.value 
    FROM   run, annot_script_run_num
    WHERE  run.id=annot_script_run_num.script_run_id and annot_script_run_num.name=$1
$_$;


ALTER FUNCTION public.compare_run_by_annot_num(name character varying) OWNER TO public;

--
-- Name: compare_run_by_annot_txt(character varying); Type: FUNCTION; Schema: public; Owner: public
--

CREATE FUNCTION compare_run_by_annot_txt(name character varying) RETURNS SETOF compare_run_by_annot_txt_type
    LANGUAGE sql
    AS $_$
    SELECT fun_call.run_id, annot_dataset_text.name, annot_dataset_text.value
    FROM   annot_dataset_text,dataset_io,dataset_containment,fun_call
    WHERE  annot_dataset_text.dataset_id=dataset_containment.in_id AND dataset_containment.out_id=dataset_io.dataset_id AND
           dataset_io.function_call_id=fun_call.id AND annot_dataset_text.name=$1
  UNION
    SELECT fun_call.run_id, annot_dataset_text.name, annot_dataset_text.value 
    FROM   fun_call, dataset_io, annot_dataset_text
    WHERE  fun_call.id=dataset_io.function_call_id and dataset_io.dataset_id=annot_dataset_text.dataset_id and
           annot_dataset_text.name=$1
  UNION
    SELECT fun_call.run_id, annot_function_call_text.name, annot_function_call_text.value 
    FROM   fun_call, annot_function_call_text
    WHERE  fun_call.id=annot_function_call_text.function_call_id and annot_function_call_text.name=$1
  UNION
    SELECT run.id as run_id, annot_script_run_text.name, annot_script_run_text.value 
    FROM   run, annot_script_run_text
    WHERE  run.id=annot_script_run_text.script_run_id and annot_script_run_text.name=$1
$_$;


ALTER FUNCTION public.compare_run_by_annot_txt(name character varying) OWNER TO public;

--
-- Name: compare_run_by_key_numeric(character varying); Type: FUNCTION; Schema: public; Owner: public
--

CREATE FUNCTION compare_run_by_key_numeric(name character varying) RETURNS SETOF compare_run_by_key_numeric_type
    LANGUAGE sql
    AS $_$
    SELECT fun_call.run_id, annot_dataset_num.name, annot_dataset_num.value
    FROM   annot_dataset_num,dataset_io,dataset_containment,fun_call
    WHERE  annot_dataset_num.dataset_id=dataset_containment.in_id AND dataset_containment.out_id=dataset_io.dataset_id AND
           dataset_io.function_call_id=fun_call.id AND annot_dataset_num.name=$1
  UNION
    SELECT fun_call.run_id, annot_dataset_num.name, annot_dataset_num.value 
    FROM   fun_call, dataset_io, annot_dataset_num
    WHERE  fun_call.id=dataset_io.function_call_id and dataset_io.dataset_id=annot_dataset_num.dataset_id and
           annot_dataset_num.name=$1
  UNION
    SELECT fun_call.run_id, annot_function_call_num.name, annot_function_call_num.value 
    FROM   fun_call, annot_function_call_num
    WHERE  fun_call.id=annot_function_call_num.function_call_id and annot_function_call_num.name=$1
  UNION
    SELECT run.id as run_id, annot_script_run_num.name, annot_script_run_num.value 
    FROM   run, annot_script_run_num
    WHERE  run.id=annot_script_run_num.script_run_id and annot_script_run_num.name=$1
$_$;


ALTER FUNCTION public.compare_run_by_key_numeric(name character varying) OWNER TO public;

--
-- Name: compare_run_by_key_text(character varying); Type: FUNCTION; Schema: public; Owner: public
--

CREATE FUNCTION compare_run_by_key_text(name character varying) RETURNS SETOF compare_run_by_key_text_type
    LANGUAGE sql
    AS $_$
    SELECT fun_call.run_id, annot_dataset_text.name, annot_dataset_text.value
    FROM   annot_dataset_text,dataset_io,dataset_containment,fun_call
    WHERE  annot_dataset_text.dataset_id=dataset_containment.in_id AND dataset_containment.out_id=dataset_io.dataset_id AND
           dataset_io.function_call_id=fun_call.id AND annot_dataset_text.name=$1
  UNION
    SELECT fun_call.run_id, annot_dataset_text.name, annot_dataset_text.value 
    FROM   fun_call, dataset_io, annot_dataset_text
    WHERE  fun_call.id=dataset_io.function_call_id and dataset_io.dataset_id=annot_dataset_text.dataset_id and
           annot_dataset_text.name=$1
  UNION
    SELECT fun_call.run_id, annot_function_call_text.name, annot_function_call_text.value 
    FROM   fun_call, annot_function_call_text
    WHERE  fun_call.id=annot_function_call_text.function_call_id and annot_function_call_text.name=$1
  UNION
    SELECT run.id as run_id, annot_script_run_text.name, annot_script_run_text.value 
    FROM   run, annot_script_run_text
    WHERE  run.id=annot_script_run_text.script_run_id and annot_script_run_text.name=$1
$_$;


ALTER FUNCTION public.compare_run_by_key_text(name character varying) OWNER TO public;

--
-- Name: compare_run_by_parameter(character varying); Type: FUNCTION; Schema: public; Owner: public
--

CREATE FUNCTION compare_run_by_parameter(parameter_name character varying) RETURNS SETOF compare_run_by_parameter_type
    LANGUAGE sql
    AS $_$
   select run_id, parameter, value
   from   dataset_io,fun_call,primitive
   where  fun_call.id=dataset_io.function_call_id and dataset_io.dataset_id=primitive.id and parameter=$1;
$_$;


ALTER FUNCTION public.compare_run_by_parameter(parameter_name character varying) OWNER TO public;

--
-- Name: correlate_parameter_runtime(character varying); Type: FUNCTION; Schema: public; Owner: public
--

CREATE FUNCTION correlate_parameter_runtime(parameter_name character varying) RETURNS TABLE(run character varying, starttime timestamp with time zone, duration numeric, parameter character varying, value character varying)
    LANGUAGE sql
    AS $_$
	SELECT script_run.id,script_run.start_time,script_run.duration,dataset_io.parameter,dataset.value
	FROM   dataset,dataset_io,fun_call,script_run
	WHERE  dataset.id=dataset_io.dataset_id AND dataset_io.function_call_id=fun_call.id AND 
	       fun_call.run_id=script_run.id AND dataset_io.parameter=$1 
$_$;


ALTER FUNCTION public.correlate_parameter_runtime(parameter_name character varying) OWNER TO public;

SET default_tablespace = '';

SET default_with_oids = false;







table