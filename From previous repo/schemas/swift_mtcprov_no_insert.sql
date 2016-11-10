--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


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

--
-- Name: annot_app_exec_num; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE annot_app_exec_num (
    app_exec_id character varying(256) NOT NULL,
    name character varying(256) NOT NULL,
    value numeric
);


ALTER TABLE public.annot_app_exec_num OWNER TO public;

--
-- Name: annot_app_exec_text; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE annot_app_exec_text (
    app_exec_id character varying(256) NOT NULL,
    name character varying(256) NOT NULL,
    value character varying(2048)
);


ALTER TABLE public.annot_app_exec_text OWNER TO public;

--
-- Name: annot_dataset_num; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE annot_dataset_num (
    dataset_id character varying(256) NOT NULL,
    name character varying(256) NOT NULL,
    value numeric
);


ALTER TABLE public.annot_dataset_num OWNER TO public;

--
-- Name: annot_dataset_text; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE annot_dataset_text (
    dataset_id character varying(256) NOT NULL,
    name character varying(256) NOT NULL,
    value character varying(2048)
);


ALTER TABLE public.annot_dataset_text OWNER TO public;

--
-- Name: annot_function_call_num; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE annot_function_call_num (
    function_call_id character varying(256) NOT NULL,
    name character varying(256) NOT NULL,
    value numeric
);


ALTER TABLE public.annot_function_call_num OWNER TO public;

--
-- Name: annot_function_call_text; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE annot_function_call_text (
    function_call_id character varying(256) NOT NULL,
    name character varying(256) NOT NULL,
    value character varying(2048)
);


ALTER TABLE public.annot_function_call_text OWNER TO public;

--
-- Name: annot_script_run_num; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE annot_script_run_num (
    script_run_id character varying(256) NOT NULL,
    name character varying(256) NOT NULL,
    value numeric
);


ALTER TABLE public.annot_script_run_num OWNER TO public;

--
-- Name: annot_script_run_text; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE annot_script_run_text (
    script_run_id character varying(256) NOT NULL,
    name character varying(256) NOT NULL,
    value character varying(2048)
);


ALTER TABLE public.annot_script_run_text OWNER TO public;

--
-- Name: app_exec; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE app_exec (
    id character varying(256) NOT NULL,
    app_fun_call_id character varying(256),
    start_time numeric,
    duration numeric,
    final_state character varying(32),
    site character varying(256)
);


ALTER TABLE public.app_exec OWNER TO public;

--
-- Name: app_fun_call; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE app_fun_call (
    id character varying(256) NOT NULL,
    name character varying(256),
    start_time numeric,
    duration numeric,
    final_state character varying(32),
    scratch character varying(2048)
);


ALTER TABLE public.app_fun_call OWNER TO public;

--
-- Name: application_execution; Type: VIEW; Schema: public; Owner: public
--

CREATE VIEW application_execution AS
    SELECT app_exec.id, app_exec.app_fun_call_id AS function_call_id, to_timestamp((app_exec.start_time)::double precision) AS start_time, app_exec.duration, app_exec.final_state, app_exec.site FROM app_exec;


ALTER TABLE public.application_execution OWNER TO public;

--
-- Name: dataset_containment; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE dataset_containment (
    out_id character varying(256) NOT NULL,
    in_id character varying(256) NOT NULL
);


ALTER TABLE public.dataset_containment OWNER TO public;

--
-- Name: mapped; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE mapped (
    id character varying(256) NOT NULL,
    filename character varying(2048)
);


ALTER TABLE public.mapped OWNER TO public;

--
-- Name: primitive; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE primitive (
    id character varying(256) NOT NULL,
    value character varying(2048)
);


ALTER TABLE public.primitive OWNER TO public;

--
-- Name: dataset; Type: VIEW; Schema: public; Owner: public
--

CREATE VIEW dataset AS
    (SELECT mapped.id, 'mapped'::text AS type, mapped.filename, NULL::character varying AS value FROM mapped UNION ALL SELECT primitive.id, 'primitive'::text AS type, NULL::character varying AS filename, primitive.value FROM primitive) UNION ALL SELECT dataset_containment.out_id AS id, 'composite'::text AS type, NULL::character varying AS filename, NULL::character varying AS value FROM dataset_containment;


ALTER TABLE public.dataset OWNER TO public;

--
-- Name: dataset_in; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE dataset_in (
    function_call_id character varying(256) NOT NULL,
    dataset_id character varying(256) NOT NULL,
    parameter character varying(256) NOT NULL
);


ALTER TABLE public.dataset_in OWNER TO public;

--
-- Name: dataset_out; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE dataset_out (
    function_call_id character varying(256) NOT NULL,
    dataset_id character varying(256) NOT NULL,
    parameter character varying(256) NOT NULL
);


ALTER TABLE public.dataset_out OWNER TO public;

--
-- Name: dataset_io; Type: VIEW; Schema: public; Owner: public
--

CREATE VIEW dataset_io AS
    SELECT dataset_in.function_call_id, dataset_in.dataset_id, dataset_in.parameter, 'I'::text AS type FROM dataset_in UNION ALL SELECT dataset_out.function_call_id, dataset_out.dataset_id, dataset_out.parameter, 'O'::text AS type FROM dataset_out;


ALTER TABLE public.dataset_io OWNER TO public;

--
-- Name: ds; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE ds (
    id character varying(256) NOT NULL
);


ALTER TABLE public.ds OWNER TO public;

--
-- Name: fun_call; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE fun_call (
    id character varying(256) NOT NULL,
    run_id character varying(256),
    type character varying(16),
    name character varying(256)
);


ALTER TABLE public.fun_call OWNER TO public;

--
-- Name: function_call; Type: VIEW; Schema: public; Owner: public
--

CREATE VIEW function_call AS
    SELECT fun_call.id, fun_call.name, fun_call.type, app_fun_call.name AS app_catalog_name, fun_call.run_id AS script_run_id, to_timestamp((app_fun_call.start_time)::double precision) AS start_time, app_fun_call.duration, app_fun_call.final_state, app_fun_call.scratch FROM (fun_call LEFT JOIN app_fun_call ON (((fun_call.id)::text = (app_fun_call.id)::text)));


ALTER TABLE public.function_call OWNER TO public;

--
-- Name: provenance_graph_edge; Type: VIEW; Schema: public; Owner: public
--

CREATE VIEW provenance_graph_edge AS
    SELECT dataset_out.function_call_id AS parent, dataset_out.dataset_id AS child FROM dataset_out UNION ALL SELECT dataset_in.dataset_id AS parent, dataset_in.function_call_id AS child FROM dataset_in;


ALTER TABLE public.provenance_graph_edge OWNER TO public;

--
-- Name: rt_info; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE rt_info (
    app_exec_id character varying(256) NOT NULL,
    "timestamp" numeric NOT NULL,
    cpu_usage numeric,
    max_phys_mem numeric,
    max_virt_mem numeric,
    io_read numeric,
    io_write numeric
);


ALTER TABLE public.rt_info OWNER TO public;

--
-- Name: run; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE run (
    id character varying(256) NOT NULL,
    log_filename character varying(2048),
    swift_version character varying(16),
    cog_version character varying(16),
    final_state character varying(32),
    start_time numeric,
    duration numeric,
    script_filename character varying(2048),
    script_hash character varying(256),
    tc_file_hash character varying(256),
    sites_file_hash character varying(256)
);


ALTER TABLE public.run OWNER TO public;

--
-- Name: runtime_info; Type: VIEW; Schema: public; Owner: public
--

CREATE VIEW runtime_info AS
    SELECT rt_info.app_exec_id, to_timestamp((rt_info."timestamp")::double precision) AS "timestamp", rt_info.cpu_usage, rt_info.max_phys_mem, rt_info.max_virt_mem, rt_info.io_read, rt_info.io_write FROM rt_info;


ALTER TABLE public.runtime_info OWNER TO public;

--
-- Name: script; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE script (
    hash_value character varying(256) NOT NULL,
    content text
);


ALTER TABLE public.script OWNER TO public;

--
-- Name: script_run; Type: VIEW; Schema: public; Owner: public
--

CREATE VIEW script_run AS
    SELECT run.id, run.log_filename, run.swift_version, run.cog_version, run.final_state, to_timestamp((run.start_time)::double precision) AS start_time, run.duration, run.script_filename, run.script_hash, run.tc_file_hash, run.sites_file_hash FROM run;


ALTER TABLE public.script_run OWNER TO public;

--
-- Name: sites_file; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE sites_file (
    hash_value character varying(256) NOT NULL,
    content text
);


ALTER TABLE public.sites_file OWNER TO public;

--
-- Name: tc_file; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE tc_file (
    hash_value character varying(256) NOT NULL,
    content text
);


ALTER TABLE public.tc_file OWNER TO public;

--
-- Data for Name: annot_app_exec_num; Type: TABLE DATA; Schema: public; Owner: public
--



--
-- Data for Name: annot_app_exec_text; Type: TABLE DATA; Schema: public; Owner: public
--



--
-- Data for Name: annot_dataset_num; Type: TABLE DATA; Schema: public; Owner: public
--



--
-- Data for Name: annot_dataset_text; Type: TABLE DATA; Schema: public; Owner: public
--



--
-- Data for Name: annot_function_call_num; Type: TABLE DATA; Schema: public; Owner: public
--



--
-- Data for Name: annot_function_call_text; Type: TABLE DATA; Schema: public; Owner: public
--



--
-- Data for Name: annot_script_run_num; Type: TABLE DATA; Schema: public; Owner: public
--



--
-- Data for Name: annot_script_run_text; Type: TABLE DATA; Schema: public; Owner: public
--



--
-- Data for Name: app_exec; Type: TABLE DATA; Schema: public; Owner: public
--



--plus a shitload of inserts omfg Luiz

--
-- Data for Name: script; Type: TABLE DATA; Schema: public; Owner: public
--

INSERT INTO script VALUES ('62abd835ec6fc2b9a27f514ac166ec1943f86ff9', 'type file;

app (file o) cat (file i)
{
  cat @i stdout=@o;
}

file out[]<simple_mapper; location=".", prefix="catsn.",suffix=".out">;
foreach j in [1:@toint(@arg("n","10"))] {
  file data<"data.txt">;
  out[j] = cat(data);
}');
INSERT INTO script VALUES ('c05609e8175739435a4500022ad43ff12c8267a8', 'type fastaseq;
type headerfile;
type indexfile;
type seqfile;
type database 
{
  headerfile phr;
  indexfile pin;
  seqfile psq;
}
type query;
type output;
string num_partitions=@arg("n", "8");
string program_name=@arg("p", "blastp");
fastaseq dbin <single_file_mapper;file=@arg("d", "database")>;
query query_file <single_file_mapper;file=@arg("i", "sequence.seq")>;
string expectation_value=@arg("e", "0.1"); 
output blast_output_file <single_file_mapper;file=@arg("o", 
                   "output.html")>;
string filter_query_sequence=@arg("F", "F");
fastaseq partition[] <ext;exec="splitmapper.sh",n=num_partitions>;

app (fastaseq out[]) split_database (fastaseq d, string n)
{
  fastasplitn @filename(d) n;
}

app (database out) formatdb (fastaseq i)
{
  formatdb "-i" @filename(i);
}

app (output o) blastapp(query i, fastaseq d, string p, string e, string f,
      database db)
{
  blastall "-p" p "-i" @filename(i) "-d" @filename(d) "-o" @filename(o) 
           "-e" e "-T" "-F" f;
}

app (output o) blastmerge(output o_frags[])
{
  blastmerge @filename(o) @filenames(o_frags);
}

partition=split_database(dbin, num_partitions);

database formatdbout[] <ext; exec="formatdbmapper.sh",n=num_partitions>;
output out[] <ext; exec="outputmapper.sh",n=num_partitions>;

foreach part,i in partition {
  formatdbout[i] = formatdb(part);
  out[i]=blastapp(query_file, part, program_name, expectation_value, 
      filter_query_sequence, formatdbout[i]);
}

blast_output_file=blastmerge(out);');
INSERT INTO script VALUES ('edb1f2561e7698a14d2992b3f3e57972b88e451d', 'type file;

app (file o) hostname ()
{
  hostname stdout=@o;
}

file out[]<simple_mapper; location="outdir", prefix="f.",suffix=".out">;
foreach j in [1:@toint(@arg("n","1"))] {
  out[j] = hostname();
}');
INSERT INTO script VALUES ('a5a51016bd87cd4cfaf8b6c65f04703d51d373f0', 'type messagefile;

app (messagefile t) greeting (string s) {   
    echo s stdout=@filename(t);
}

messagefile outfile <"parameter.hello.txt">;
outfile = greeting("hello world");');
INSERT INTO script VALUES ('2862e56eb71b6d14c7c90a8d4cd95753e4e78439', 'type messagefile;

app (messagefile t) greeting (string s) {   
    echo s stdout=@filename(t);
}

app (messagefile o) capitalise(messagefile i) {   
    tr "[a-z]" "[A-Z]" stdin=@filename(i) stdout=@filename(o);
}

messagefile hellofile;
messagefile final <"capitalise_anonymous.txt">;
hellofile = greeting("hello from Swift");
final = capitalise(hellofile);');
INSERT INTO script VALUES ('8073d313aa19b60d8edc915080087f121186894d', 'type file;
type imagefile;
type landuse;

app (landuse output) getLandUse (imagefile input, int sortfield)
{
  getlanduse @input sortfield stdout=@output ;
}

app (file output, file tilelist) analyzeLandUse (landuse input[], int usetype, int maxnum)
{
  analyzelanduse @output @tilelist usetype maxnum @filenames(input);
}

app (imagefile output) colormodis (imagefile input)
{
  colormodis @input @output;
}

imagefile geos[]<filesys_mapper; location="/home/public/cenapadrj/swift/bigdata/data/modis/2002", suffix=".tif">;
landuse   land[]<structured_regexp_mapper; source=geos,match="(h..v..)", transform="\\1.landuse.byfreq">;

# Find the land use of each modis tile

foreach g,i in geos {
  land[i] = getLandUse(g,1);
}

# Find the top 10 most urban tiles (by area)

int UsageTypeURBAN=13;
file bigurban<"topurban.txt">;
file urbantiles<"urbantiles.txt">;
(bigurban, urbantiles) = analyzeLandUse(land, UsageTypeURBAN, 10);

# Map the files to an array

string urbanfilenames[] = readData(urbantiles);
imagefile urbanfiles[] <array_mapper;files=urbanfilenames>;

# Create a set of recolored images for just the urban tiles

foreach uf, i in urbanfiles {
  imagefile recoloredImage <single_file_mapper; file=@strcat(@strcut(urbanfilenames[i],"(h..v..)"),".recolored.tif")>;
  recoloredImage = colormodis(uf);
}');
INSERT INTO script VALUES ('0bc5fac6d73ea73daca5ed21b06a9cc15707cc33', 'type messagefile;

app (messagefile t) greeting() { 
    echo "Hello, world!" stdout=@filename(t);
}

messagefile outfile <"hello.txt">;

outfile = greeting();');
INSERT INTO script VALUES ('8971b4adfa40e8aa3965fa586f478f2fac900b67', 'type messagefile;

app (messagefile t) greeting (string s) {   
    echo s stdout=@filename(t);
}

messagefile english <"manyparam.english.txt">;
messagefile french <"manyparam.french.txt">;
messagefile japanese <"manyparam.japanese.txt">;

english = greeting("hello");
french = greeting("bonjour");
japanese = greeting("konnichiwa");');
INSERT INTO script VALUES ('2d065fdedea6f3c52aba287bc325939054dc93e1', 'type scene;
type image;
type scene_template;

int threads;
int steps;
string resolution;

threads = @toint(@arg("threads","1"));
resolution = @arg("resolution","800x600");
steps = @toint(@arg("steps","10"));
scene_template template <"tscene">;

app (scene out) generate (scene_template t, int i, int total)
{
  genscenes i total @filename(t) stdout=@out;
}

app (image o) render (scene i, string r, int t)
{
  cray "-s" r "-t" t stdin=@i stdout=@o;
}

scene scene_files[] <simple_mapper; location=".", prefix="scene.", suffix=".data">;

image image_files[] <simple_mapper; location=".", prefix="scene.", suffix=".ppm">;
 
foreach i in [1:steps] {
  scene_files[i] = generate(template, i, steps);
  image_files[i] = render(scene_files[i], resolution, threads);
}');
INSERT INTO script VALUES ('3775824dda495352035d3d68690c41f4bc20ec35', 'type messagefile;

app (messagefile t) greeting (string s) {
   echo s stdout=@filename(t);
}

messagefile outfile <"if.txt">;

boolean morning = true;

if(morning) {
  outfile = greeting("good morning");
} else {
  outfile = greeting("good afternoon");
}');
INSERT INTO script VALUES ('2ee2926a82baa35dc87c83039b396e23d08cdc56', 'type messagefile; 
type countfile; 

app (countfile t) countwords (messagefile f) {   
     wc "-w" @filename(f) stdout=@filename(t);
}

string inputNames = "foreach.1.txt foreach.2.txt foreach.3.txt";

messagefile inputfiles[] <fixed_array_mapper;files=inputNames>;

foreach f in inputfiles {
  countfile c<regexp_mapper;
      source=@f,
            match="(.*)txt",
            transform="\\1count">;
  c = countwords(f);
}');
INSERT INTO script VALUES ('c3c317469ee740729583ed9236e7c8ef58de551f', 'type messagefile; 
type countfile; 

app (countfile t) countwords (messagefile f) {   
   wc "-w" @filename(f) stdout=@filename(t);
}

string inputNames = "fixed_array_mapper.1.txt fixed_array_mapper.2.txt fixed_array_mapper.3.txt";
string outputNames = "fixed_array_mapper.1.count fixed_array_mapper.2.count fixed_array_mapper.3.count";

messagefile inputfiles[] <fixed_array_mapper;files=inputNames>;
countfile outputfiles[] <fixed_array_mapper;files=outputNames>;

outputfiles[0] = countwords(inputfiles[0]);
outputfiles[1] = countwords(inputfiles[1]);
outputfiles[2] = countwords(inputfiles[2]);');
INSERT INTO script VALUES ('53585e0de01c1e4c6230e8a1d925391ec9a7e5de', 'type file;  
  
app (file f) touch() {  
    touch @f;  
}  
  
app (file f) processL(file inp) {  
    echo "processL" stdout=@f;  
}  
  
app (file f) processR(file inp) {  
    broken "process" stdout=@f;  
}  
  
app (file f) join(file left, file right) {  
    echo "join" @left @right stdout=@f;  
}  
  
file f = touch();  
  
file g = processL(f);  
file h = processR(f);  
  
file i = join(g,h);  ');
INSERT INTO script VALUES ('90f46acde05cd137ceca36b2c7e3521c34a21bfb', 'type counterfile;  
  
app (counterfile t) echo(string m) {   
    echo m stdout=@filename(t);  
}  
  
app (counterfile t) countstep(counterfile i) {  
    wcl @filename(i) @filename(t);  
}  
  
counterfile a[]  <simple_mapper;prefix="sequential_iteration.foldout">;  
  
a[0] = echo("793578934574893");  
  
iterate v {  
  a[v+1] = countstep(a[v]);  
 trace("extract int value ",@extractint(a[v+1]));  
} until (@extractint(a[v+1]) <= 1);  ');
INSERT INTO script VALUES ('1bf282575369d5bb85ea3ee17b9edb5d16ae72f0', 'type messagefile; 

app (messagefile t) greeting (string s[]) {   
     echo s[0] s[1] s[2] stdout=@filename(t);
}

messagefile outfile <"arrays.txt">;

string words[] = ["how","are","you"];

outfile = greeting(words);');
INSERT INTO script VALUES ('ec4cce06002a5e118d4910d3d685fc90f77db512', 'type file;

app (file t) echo_wildcard (string s[]) {
        echo s[*] stdout=@filename(t);
}

string greetings[] = ["how","are","you"];
file hw = echo_wildcard(greetings); ');
INSERT INTO script VALUES ('5a5ebb5d67c6ba04a54f3bed25027c8dbffff51f', 'type messagefile;

app (messagefile t) greeting (string s) {   
    echo s stdout=@filename(t);
}

app (messagefile o) capitalise(messagefile i) {   
    tr "[a-z]" "[A-Z]" stdin=@filename(i) stdout=@filename(o);
}

messagefile hellofile <"capitalise.1.txt">;
messagefile final <"capitalise.2.txt">;
hellofile = greeting("hello from Swift");
final = capitalise(hellofile);');
INSERT INTO script VALUES ('9e9c8fc1445cefc5f44da53171658bd547b20f73', 'type messagefile; 
type countfile; 

app (countfile t) countwords (messagefile f) {   
  wc "-w" @filename(f) stdout=@filename(t);
}

messagefile inputfile <"regexp_mapper.words.txt">;

countfile c <regexp_mapper;
      source=@inputfile,
            match="(.*)txt",
            transform="\\1count">;

c = countwords(inputfile);');
INSERT INTO script VALUES ('036f3a61cec15b5ca7a638460a2b30a7db9030b5', 'type file;

app (file t) echo_array (string s[]) {
        echo s[0] s[1] s[2] stdout=@filename(t);
}

string greetings[] = ["how","are","you"];
file hw = echo_array(greetings);');
INSERT INTO script VALUES ('4d428c4ad6c308ac74c29ed370a73f5b450f129b', 'type file;

// s has a default value
app (file t) echo (string s="hello world") { 
        echo s stdout=@filename(t);   
}

file hw1<"default.1.txt">;
file hw2<"default.2.txt">;

// procedure call using the default value
hw1 = echo();   

// using a different value
hw2 = echo(s="hello again"); ');


--
-- Data for Name: sites_file; Type: TABLE DATA; Schema: public; Owner: public
--

INSERT INTO sites_file VALUES ('da39a3ee5e6b4b0d3255bfef95601890afd80709', '');
INSERT INTO sites_file VALUES ('e9f6891ac51ea88785020bacc12d8944df603de9', '<config>
  <pool handle="localhost" sysinfo="INTEL32::LINUX">
    <gridftp url="local://localhost" />
    <execution provider="local" url="none" />
    <workdirectory>/prj/prjssi/public/swiftwork</workdirectory>
    <!-- <profile namespace="karajan" key="maxSubmitRate">1</profile> -->
    <profile namespace="karajan" key="jobThrottle">0.03</profile>
    <profile namespace="swift"   key="stagingMethod">file</profile>
  </pool>


  <pool handle="sunhpc.lncc.br-sge-local-coasters">
    <gridftp url="local://localhost" />
    <!-- <execution provider="sge" url="localhost" /> -->
    <execution jobmanager="local:sge" provider="coaster"/>
  <profile key="jobsPerNode" namespace="globus">8</profile>
  <profile key="slots" namespace="globus">128</profile>
  <profile key="nodeGranularity" namespace="globus">1</profile>
  <profile key="maxNodes" namespace="globus">16</profile>
  <profile namespace="globus" key="maxtime">36000</profile>
    <profile namespace="globus" key="pe">mpi</profile> 
    <profile namespace="globus" key="queue">linux.q</profile>
    <profile key="jobThrottle" namespace="karajan">1.27</profile>
    <profile namespace="karajan" key="initialScore">10000</profile>
    <filesystem provider="local" url="none" />
    <workdirectory>/prj/prjssi/public/swiftwork</workdirectory> 
  </pool> 

  <pool handle="sge-local">
    <gridftp url="local://localhost" />
   <execution provider="sge" url="localhost" /> 
    <profile namespace="globus" key="pe">mpi1</profile>
    <profile namespace="globus" key="queue">linux.q</profile>
    <profile key="jobThrottle" namespace="karajan">0.63</profile>
    <profile namespace="karajan" key="initialScore">10000</profile>
   <profile namespace="globus" key="jobsPerNode">1</profile>
   <profile namespace="globus" key="slots">1</profile>
    <filesystem provider="local" url="none" />
    <workdirectory>/prj/prjssi/public/swiftwork</workdirectory>
  </pool>

</config>');
INSERT INTO sites_file VALUES ('902186eeb2e8e9aa23dde4e66cac1be60a0a0ebe', '<config>
  <pool handle="localhost" sysinfo="INTEL32::LINUX">
    <gridftp url="local://localhost" />
    <execution provider="local" url="none" />
    <!-- <profile namespace="karajan" key="maxSubmitRate">1</profile> -->
    <profile namespace="karajan" key="jobThrottle">0.29</profile>
    <profile namespace="swift"   key="stagingMethod">file</profile>
    <workdirectory>/tmp/public/swiftwork</workdirectory>
  </pool>


  <pool handle="sge-local">
    <execution provider="sge" url="none" />
    <profile namespace="globus" key="pe">threads</profile>
    <profile key="jobThrottle" namespace="karajan">6.23</profile>
    <profile namespace="karajan" key="initialScore">10000</profile>
    <filesystem provider="local" url="none" />
  </pool>

  <pool handle="coaster-pbs-local">
    <execution provider="coaster" jobmanager="local:pbs" url="none" />
    <profile namespace="globus" key="queue">batch</profile>
    <profile key="jobThrottle" namespace="karajan">0.29</profile>
    <profile namespace="karajan" key="initialScore">10000</profile>
    <filesystem provider="local" url="none" />
    <workdirectory>/prj/prjssi/public/swiftwork</workdirectory>
  </pool>

  <pool handle="pbs-local">
    <execution provider="pbs" url="none" />
    <profile namespace="globus" key="queue">batch</profile>
    <profile key="jobThrottle" namespace="karajan">0.29</profile>
    <profile namespace="karajan" key="initialScore">10000</profile>
    <filesystem provider="local" url="none" />
    <workdirectory>/prj/prjssi/public/swiftwork</workdirectory>
  </pool>


  <pool handle="ssh-lab5-01">
    <execution provider="ssh" url="lab5-01.lncc.br" />
    <profile key="jobThrottle" namespace="karajan">0.11</profile>
    <filesystem provider="ssh" url="lab5-01.lncc.br" />
    <workdirectory>/tmp/verao2012/swiftwork</workdirectory>
  </pool>


</config>');
INSERT INTO sites_file VALUES ('947ad44dce074f9ddfa65718153a2085a1ec7130', '<config>
  <pool handle="cipher.lncc.br-localhost" sysinfo="INTEL32::LINUX">
    <gridftp url="local://localhost" />
    <execution provider="local" url="none" />
    <workdirectory>/tmp/public</workdirectory>
    <!-- <profile namespace="karajan" key="maxSubmitRate">1</profile> -->
    <profile namespace="karajan" key="jobThrottle">0.03</profile>
    <profile namespace="swift"   key="stagingMethod">file</profile>
</pool>
</config>');


--
-- Data for Name: tc_file; Type: TABLE DATA; Schema: public; Owner: public
--

INSERT INTO tc_file VALUES ('3e75d4ed59090c96609a7f2fc9018bbb6d3936bf', '#This is the transformation catalog.
#
#It comes pre-configured with a number of simple transformations with
#paths that are likely to work on a linux box. However, on some systems,
#the paths to these executables will be different (for example, sometimes
#some of these programs are found in /usr/bin rather than in /bin)
#
#NOTE WELL: fields in this file must be separated by tabs, not spaces; and
#there must be no trailing whitespace at the end of each line.
#
# sitename  transformation  path   INSTALLED  platform  profiles
sunhpc.lncc.br-localhost  echo    /bin/echo INSTALLED INTEL32::LINUX  null
sunhpc.lncc.br-localhost  cat     /bin/cat  INSTALLED INTEL32::LINUX  null
sunhpc.lncc.br-localhost  ls    /bin/ls   INSTALLED INTEL32::LINUX  null
sunhpc.lncc.br-localhost  grep    /bin/grep INSTALLED INTEL32::LINUX  null
sunhpc.lncc.br-localhost  sort    /bin/sort INSTALLED INTEL32::LINUX  null
sunhpc.lncc.br-localhost  paste     /bin/paste  INSTALLED INTEL32::LINUX  null
sunhpc.lncc.br-localhost  cp    /bin/cp         INSTALLED INTEL32::LINUX  null
sunhpc.lncc.br-localhost  touch     /bin/touch      INSTALLED INTEL32::LINUX  null
sunhpc.lncc.br-localhost  wc    /usr/bin/wc INSTALLED INTEL32::LINUX  null
sunhpc.lncc.br-localhost  hostname    /bin/hostname INSTALLED INTEL32::LINUX  null');
INSERT INTO tc_file VALUES ('faff16f6ed98adcc22cc127c7ad790ddfe53e260', '#This is the transformation catalog.
#
#It comes pre-configured with a number of simple transformations with
#paths that are likely to work on a linux box. However, on some systems,
#the paths to these executables will be different (for example, sometimes
#some of these programs are found in /usr/bin rather than in /bin)
#
#NOTE WELL: fields in this file must be separated by tabs, not spaces; and
#there must be no trailing whitespace at the end of each line.
#
# sitename  transformation  path   INSTALLED  platform  profiles
localhost   echo    /bin/echo INSTALLED INTEL32::LINUX  null
localhost   cat     /bin/cat  INSTALLED INTEL32::LINUX  null
localhost   ls    /bin/ls   INSTALLED INTEL32::LINUX  null
localhost   grep    /bin/grep INSTALLED INTEL32::LINUX  null
localhost   sort    /bin/sort INSTALLED INTEL32::LINUX  null
localhost   paste     /bin/paste  INSTALLED INTEL32::LINUX  null
localhost   cp    /bin/cp         INSTALLED INTEL32::LINUX  null
localhost   touch     /bin/touch      INSTALLED INTEL32::LINUX  null
localhost wc    /usr/bin/wc INSTALLED INTEL32::LINUX  null
localhost sleep   /bin/sleep  null  null  null
sunhpc.lncc.br-sge-local-coasters blastall  /hpc/blast/2.2.22/bin/blastall    null    null    null
localhost fastasplitn /prj/prjssi/public/parallelblast/fastasplitn  null    null  null
localhost blastmerge  /prj/prjssi/public/parallelblast/blastmerge null    null  null
sunhpc.lncc.br-sge-local-coasters formatdb  /hpc/blast/2.2.22/bin/formatdb              null    null  null');
INSERT INTO tc_file VALUES ('f9edf99d216da927e9ca5a1fc3f72ba79285cf6f', '#This is the transformation catalog.
#
#It comes pre-configured with a number of simple transformations with
#paths that are likely to work on a linux box. However, on some systems,
#the paths to these executables will be different (for example, sometimes
#some of these programs are found in /usr/bin rather than in /bin)
#
#NOTE WELL: fields in this file must be separated by tabs, not spaces; and
#there must be no trailing whitespace at the end of each line.
#
# site    transformation  path    obsolete fields for compatibility

localhost   echo    /bin/echo null  null  null
localhost   cat     /bin/cat  null  null  null
localhost   ls    /bin/ls   null  null  null
localhost   grep    /bin/grep null  null  null
localhost   sort    /bin/sort null  null  null
localhost   paste     /bin/paste  null  null  null
localhost   pwd     /bin/pwd  null  null  null

# For cluster usage

#sge-local    convert   /usr/bin/convert  null  null  null
#sge-local    getlanduse  /prj/prjssi/public/cenapadrj/swift/bigdata/bin/getlanduse.sh  null  null  null
#sge-local    analyzelanduse  /prj/prjssi/public/cenapadrj/swift/bigdata/bin/analyzelanduse.sh  null  null  null
#sge-local    colormodis  /prj/prjssi/public/cenapadrj/swift/bigdata/bin/colormodis.sh  null  null  null
#

#coaster-pbs-local  convert /usr/bin/convert        null    null    null
#coaster-pbs-local  getlanduse  /home/public/cenapadrj/swift/bigdata/bin/getlanduse.sh  null    null    null
#coaster-pbs-local  analyzelanduse  /home/public/cenapadrj/swift/bigdata/bin/analyzelanduse.sh      null    null    null
#coaster-pbs-local  colormodis  /home/public/cenapadrj/swift/bigdata/bin/colormodis.sh  null    null    null
#
#ssh-lab5-01       convert /usr/bin/convert        null    null    null
#ssh-lab5-01       getlanduse      /home/public/cenapadrj/swift/bigdata/bin/getlanduse.sh  null    null    null
#ssh-lab5-01       analyzelanduse  /home/public/cenapadrj/swift/bigdata/bin/analyzelanduse.sh      null    null    null
#ssh-lab5-01       colormodis      /home/public/cenapadrj/swift/bigdata/bin/colormodis.sh  null    null    null

# For localhost testing

localhost convert   /usr/bin/convert  null  null  null
localhost getlanduse  /home/public/cenapadrj/swift/bigdata/bin/getlanduse.sh  null  null  null
localhost analyzelanduse  /home/public/cenapadrj/swift/bigdata/bin/analyzelanduse.sh  null  null  null
localhost colormodis  /home/public/cenapadrj/swift/bigdata/bin/colormodis.sh  null  null  null');
INSERT INTO tc_file VALUES ('595cae7061d5ebf9480403d414d7c940cafde937', '#This is the transformation crayalog.
#
#It comes pre-configured with a number of simple transformations with
#paths that are likely to work on a linux box. However, on some systems,
#the paths to these executables will be different (for example, sometimes
#some of these programs are found in /usr/bin rather than in /bin)
#
#NOTE WELL: fields in this file must be separated by tabs, not spaces; and
#there must be no trailing whitespace at the end of each line.
#
# sitename  transformation  path   INSTALLED  platform  profiles
localhost   echo    /bin/echo INSTALLED INTEL32::LINUX  null
cipher.lncc.br-localhost  cray    /home/public/c-ray-1.1/c-ray-mt INSTALLED INTEL32::LINUX  null
localhost   ls    /bin/ls   INSTALLED INTEL32::LINUX  null
localhost   grep    /bin/grep INSTALLED INTEL32::LINUX  null
localhost   sort    /bin/sort INSTALLED INTEL32::LINUX  null
localhost   paste     /bin/paste  INSTALLED INTEL32::LINUX  null
localhost   cp    /bin/cp         INSTALLED INTEL32::LINUX  null
localhost   touch     /bin/touch      INSTALLED INTEL32::LINUX  null
localhost wc    /usr/bin/wc INSTALLED INTEL32::LINUX  null
localhost sleep   /bin/sleep  null  null  null
#lab5-01.lncc.br  cray    /prj/prjssi/public/c-ray-1.1/c-ray-mt INSTALLED INTEL32::LINUX  null
#lab5-02.lncc.br  cray    /prj/prjssi/public/c-ray-1.1/c-ray-mt INSTALLED INTEL32::LINUX  null
#lab5-03.lncc.br  cray    /prj/prjssi/public/c-ray-1.1/c-ray-mt INSTALLED INTEL32::LINUX  null
#lab5-04.lncc.br  cray    /prj/prjssi/public/c-ray-1.1/c-ray-mt INSTALLED INTEL32::LINUX  null
#lab5-05.lncc.br  cray    /prj/prjssi/public/c-ray-1.1/c-ray-mt INSTALLED INTEL32::LINUX  null
#lab5-06.lncc.br  cray    /prj/prjssi/public/c-ray-1.1/c-ray-mt INSTALLED INTEL32::LINUX  null
#lab5-07.lncc.br  cray    /prj/prjssi/public/c-ray-1.1/c-ray-mt INSTALLED INTEL32::LINUX  null
#lab5-08.lncc.br  cray    /prj/prjssi/public/c-ray-1.1/c-ray-mt INSTALLED INTEL32::LINUX  null
#lab5-09.lncc.br  cray    /prj/prjssi/public/c-ray-1.1/c-ray-mt INSTALLED INTEL32::LINUX  null
#lab5-10.lncc.br  cray    /prj/prjssi/public/c-ray-1.1/c-ray-mt INSTALLED INTEL32::LINUX  null
#lab5-12.lncc.br  cray    /prj/prjssi/public/c-ray-1.1/c-ray-mt INSTALLED INTEL32::LINUX  null
#lab5-13.lncc.br  cray    /prj/prjssi/public/c-ray-1.1/c-ray-mt INSTALLED INTEL32::LINUX  null
#lab5-14.lncc.br  cray    /prj/prjssi/public/c-ray-1.1/c-ray-mt INSTALLED INTEL32::LINUX  null
#lab5-15.lncc.br  cray    /prj/prjssi/public/c-ray-1.1/c-ray-mt INSTALLED INTEL32::LINUX  null
#lab5-16.lncc.br  cray    /prj/prjssi/public/c-ray-1.1/c-ray-mt INSTALLED INTEL32::LINUX  null
#lab5-17.lncc.br  cray    /prj/prjssi/public/c-ray-1.1/c-ray-mt INSTALLED INTEL32::LINUX  null
#lab5-18.lncc.br  cray    /prj/prjssi/public/c-ray-1.1/c-ray-mt INSTALLED INTEL32::LINUX  null
#lab5-19.lncc.br  cray    /prj/prjssi/public/c-ray-1.1/c-ray-mt INSTALLED INTEL32::LINUX  null
#lab5-20.lncc.br  cray    /prj/prjssi/public/c-ray-1.1/c-ray-mt INSTALLED INTEL32::LINUX  null
cipher.lncc.br-localhost  genscenes /home/public/cenapadrj/swift/c-ray/genscenes.sh null  null  null
#pbs-local  cray  /home/public/c-ray-1.1/c-ray-mt null  null  null');


--
-- Name: annot_app_exec_num_pkey; Type: CONSTRAINT; Schema: public; Owner: public; Tablespace: 
--

ALTER TABLE ONLY annot_app_exec_num
    ADD CONSTRAINT annot_app_exec_num_pkey PRIMARY KEY (app_exec_id, name);


--
-- Name: annot_app_exec_text_pkey; Type: CONSTRAINT; Schema: public; Owner: public; Tablespace: 
--

ALTER TABLE ONLY annot_app_exec_text
    ADD CONSTRAINT annot_app_exec_text_pkey PRIMARY KEY (app_exec_id, name);


--
-- Name: annot_dataset_num_pkey; Type: CONSTRAINT; Schema: public; Owner: public; Tablespace: 
--

ALTER TABLE ONLY annot_dataset_num
    ADD CONSTRAINT annot_dataset_num_pkey PRIMARY KEY (dataset_id, name);


--
-- Name: annot_dataset_text_pkey; Type: CONSTRAINT; Schema: public; Owner: public; Tablespace: 
--

ALTER TABLE ONLY annot_dataset_text
    ADD CONSTRAINT annot_dataset_text_pkey PRIMARY KEY (dataset_id, name);


--
-- Name: annot_function_call_num_pkey; Type: CONSTRAINT; Schema: public; Owner: public; Tablespace: 
--

ALTER TABLE ONLY annot_function_call_num
    ADD CONSTRAINT annot_function_call_num_pkey PRIMARY KEY (function_call_id, name);


--
-- Name: annot_function_call_text_pkey; Type: CONSTRAINT; Schema: public; Owner: public; Tablespace: 
--

ALTER TABLE ONLY annot_function_call_text
    ADD CONSTRAINT annot_function_call_text_pkey PRIMARY KEY (function_call_id, name);


--
-- Name: annot_script_run_num_pkey; Type: CONSTRAINT; Schema: public; Owner: public; Tablespace: 
--

ALTER TABLE ONLY annot_script_run_num
    ADD CONSTRAINT annot_script_run_num_pkey PRIMARY KEY (script_run_id, name);


--
-- Name: annot_script_run_text_pkey; Type: CONSTRAINT; Schema: public; Owner: public; Tablespace: 
--

ALTER TABLE ONLY annot_script_run_text
    ADD CONSTRAINT annot_script_run_text_pkey PRIMARY KEY (script_run_id, name);


--
-- Name: app_exec_pkey; Type: CONSTRAINT; Schema: public; Owner: public; Tablespace: 
--

ALTER TABLE ONLY app_exec
    ADD CONSTRAINT app_exec_pkey PRIMARY KEY (id);


--
-- Name: app_fun_call_pkey; Type: CONSTRAINT; Schema: public; Owner: public; Tablespace: 
--

ALTER TABLE ONLY app_fun_call
    ADD CONSTRAINT app_fun_call_pkey PRIMARY KEY (id);


--
-- Name: dataset_containment_pkey; Type: CONSTRAINT; Schema: public; Owner: public; Tablespace: 
--

ALTER TABLE ONLY dataset_containment
    ADD CONSTRAINT dataset_containment_pkey PRIMARY KEY (out_id, in_id);


--
-- Name: dataset_in_pkey; Type: CONSTRAINT; Schema: public; Owner: public; Tablespace: 
--

ALTER TABLE ONLY dataset_in
    ADD CONSTRAINT dataset_in_pkey PRIMARY KEY (function_call_id, dataset_id, parameter);


--
-- Name: dataset_out_pkey; Type: CONSTRAINT; Schema: public; Owner: public; Tablespace: 
--

ALTER TABLE ONLY dataset_out
    ADD CONSTRAINT dataset_out_pkey PRIMARY KEY (function_call_id, dataset_id, parameter);


--
-- Name: ds_pkey; Type: CONSTRAINT; Schema: public; Owner: public; Tablespace: 
--

ALTER TABLE ONLY ds
    ADD CONSTRAINT ds_pkey PRIMARY KEY (id);


--
-- Name: fun_call_pkey; Type: CONSTRAINT; Schema: public; Owner: public; Tablespace: 
--

ALTER TABLE ONLY fun_call
    ADD CONSTRAINT fun_call_pkey PRIMARY KEY (id);


--
-- Name: mapped_pkey; Type: CONSTRAINT; Schema: public; Owner: public; Tablespace: 
--

ALTER TABLE ONLY mapped
    ADD CONSTRAINT mapped_pkey PRIMARY KEY (id);


--
-- Name: primitive_pkey; Type: CONSTRAINT; Schema: public; Owner: public; Tablespace: 
--

ALTER TABLE ONLY primitive
    ADD CONSTRAINT primitive_pkey PRIMARY KEY (id);


--
-- Name: rt_info_pkey; Type: CONSTRAINT; Schema: public; Owner: public; Tablespace: 
--

ALTER TABLE ONLY rt_info
    ADD CONSTRAINT rt_info_pkey PRIMARY KEY (app_exec_id, "timestamp");


--
-- Name: run_pkey; Type: CONSTRAINT; Schema: public; Owner: public; Tablespace: 
--

ALTER TABLE ONLY run
    ADD CONSTRAINT run_pkey PRIMARY KEY (id);


--
-- Name: script_pkey; Type: CONSTRAINT; Schema: public; Owner: public; Tablespace: 
--

ALTER TABLE ONLY script
    ADD CONSTRAINT script_pkey PRIMARY KEY (hash_value);


--
-- Name: sites_file_pkey; Type: CONSTRAINT; Schema: public; Owner: public; Tablespace: 
--

ALTER TABLE ONLY sites_file
    ADD CONSTRAINT sites_file_pkey PRIMARY KEY (hash_value);


--
-- Name: tc_file_pkey; Type: CONSTRAINT; Schema: public; Owner: public; Tablespace: 
--

ALTER TABLE ONLY tc_file
    ADD CONSTRAINT tc_file_pkey PRIMARY KEY (hash_value);


--
-- Name: annot_app_exec_num_app_exec_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: public
--

ALTER TABLE ONLY annot_app_exec_num
    ADD CONSTRAINT annot_app_exec_num_app_exec_id_fkey FOREIGN KEY (app_exec_id) REFERENCES app_exec(id) ON DELETE CASCADE;


--
-- Name: annot_app_exec_text_app_exec_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: public
--

ALTER TABLE ONLY annot_app_exec_text
    ADD CONSTRAINT annot_app_exec_text_app_exec_id_fkey FOREIGN KEY (app_exec_id) REFERENCES app_exec(id) ON DELETE CASCADE;


--
-- Name: annot_dataset_num_dataset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: public
--

ALTER TABLE ONLY annot_dataset_num
    ADD CONSTRAINT annot_dataset_num_dataset_id_fkey FOREIGN KEY (dataset_id) REFERENCES ds(id) ON DELETE CASCADE;


--
-- Name: annot_dataset_text_dataset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: public
--

ALTER TABLE ONLY annot_dataset_text
    ADD CONSTRAINT annot_dataset_text_dataset_id_fkey FOREIGN KEY (dataset_id) REFERENCES ds(id) ON DELETE CASCADE;


--
-- Name: annot_function_call_num_function_call_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: public
--

ALTER TABLE ONLY annot_function_call_num
    ADD CONSTRAINT annot_function_call_num_function_call_id_fkey FOREIGN KEY (function_call_id) REFERENCES fun_call(id) ON DELETE CASCADE;


--
-- Name: annot_function_call_text_function_call_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: public
--

ALTER TABLE ONLY annot_function_call_text
    ADD CONSTRAINT annot_function_call_text_function_call_id_fkey FOREIGN KEY (function_call_id) REFERENCES fun_call(id) ON DELETE CASCADE;


--
-- Name: annot_script_run_num_script_run_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: public
--

ALTER TABLE ONLY annot_script_run_num
    ADD CONSTRAINT annot_script_run_num_script_run_id_fkey FOREIGN KEY (script_run_id) REFERENCES run(id) ON DELETE CASCADE;


--
-- Name: annot_script_run_text_script_run_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: public
--

ALTER TABLE ONLY annot_script_run_text
    ADD CONSTRAINT annot_script_run_text_script_run_id_fkey FOREIGN KEY (script_run_id) REFERENCES run(id) ON DELETE CASCADE;


--
-- Name: app_exec_app_fun_call_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: public
--

ALTER TABLE ONLY app_exec
    ADD CONSTRAINT app_exec_app_fun_call_id_fkey FOREIGN KEY (app_fun_call_id) REFERENCES app_fun_call(id);


--
-- Name: app_fun_call_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: public
--

ALTER TABLE ONLY app_fun_call
    ADD CONSTRAINT app_fun_call_id_fkey FOREIGN KEY (id) REFERENCES fun_call(id);


--
-- Name: dataset_containment_in_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: public
--

ALTER TABLE ONLY dataset_containment
    ADD CONSTRAINT dataset_containment_in_id_fkey FOREIGN KEY (in_id) REFERENCES ds(id) ON DELETE CASCADE;


--
-- Name: dataset_containment_out_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: public
--

ALTER TABLE ONLY dataset_containment
    ADD CONSTRAINT dataset_containment_out_id_fkey FOREIGN KEY (out_id) REFERENCES ds(id) ON DELETE CASCADE;


--
-- Name: dataset_in_dataset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: public
--

ALTER TABLE ONLY dataset_in
    ADD CONSTRAINT dataset_in_dataset_id_fkey FOREIGN KEY (dataset_id) REFERENCES ds(id) ON DELETE CASCADE;


--
-- Name: dataset_in_function_call_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: public
--

ALTER TABLE ONLY dataset_in
    ADD CONSTRAINT dataset_in_function_call_id_fkey FOREIGN KEY (function_call_id) REFERENCES fun_call(id);


--
-- Name: dataset_out_dataset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: public
--

ALTER TABLE ONLY dataset_out
    ADD CONSTRAINT dataset_out_dataset_id_fkey FOREIGN KEY (dataset_id) REFERENCES ds(id) ON DELETE CASCADE;


--
-- Name: dataset_out_function_call_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: public
--

ALTER TABLE ONLY dataset_out
    ADD CONSTRAINT dataset_out_function_call_id_fkey FOREIGN KEY (function_call_id) REFERENCES fun_call(id);


--
-- Name: fun_call_run_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: public
--

ALTER TABLE ONLY fun_call
    ADD CONSTRAINT fun_call_run_id_fkey FOREIGN KEY (run_id) REFERENCES run(id) ON DELETE CASCADE;


--
-- Name: mapped_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: public
--

ALTER TABLE ONLY mapped
    ADD CONSTRAINT mapped_id_fkey FOREIGN KEY (id) REFERENCES ds(id) ON DELETE CASCADE;


--
-- Name: primitive_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: public
--

ALTER TABLE ONLY primitive
    ADD CONSTRAINT primitive_id_fkey FOREIGN KEY (id) REFERENCES ds(id) ON DELETE CASCADE;


--
-- Name: rt_info_app_exec_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: public
--

ALTER TABLE ONLY rt_info
    ADD CONSTRAINT rt_info_app_exec_id_fkey FOREIGN KEY (app_exec_id) REFERENCES app_exec(id);


--
-- Name: run_script_hash_fkey; Type: FK CONSTRAINT; Schema: public; Owner: public
--

ALTER TABLE ONLY run
    ADD CONSTRAINT run_script_hash_fkey FOREIGN KEY (script_hash) REFERENCES script(hash_value);


--
-- Name: run_sites_file_hash_fkey; Type: FK CONSTRAINT; Schema: public; Owner: public
--

ALTER TABLE ONLY run
    ADD CONSTRAINT run_sites_file_hash_fkey FOREIGN KEY (sites_file_hash) REFERENCES sites_file(hash_value);


--
-- Name: run_tc_file_hash_fkey; Type: FK CONSTRAINT; Schema: public; Owner: public
--

ALTER TABLE ONLY run
    ADD CONSTRAINT run_tc_file_hash_fkey FOREIGN KEY (tc_file_hash) REFERENCES tc_file(hash_value);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--