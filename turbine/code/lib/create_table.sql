
--All this is in the db public....probably don't need that
--Why does he have 22 tables and I have sixteen fijngfskngl;dkf

CREATE TABLE annot_app_exec_num (
    app_exec_id character varying(256) NOT NULL,
    name character varying(256) NOT NULL,
    value numeric
);


-- ALTER TABLE public.annot_app_exec_num OWNER TO public;

--
-- Name: annot_app_exec_text; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE annot_app_exec_text (
    app_exec_id character varying(256) NOT NULL,
    name character varying(256) NOT NULL,
    value character varying(2048)
);


-- ALTER TABLE public.annot_app_exec_text OWNER TO public;

--
-- Name: annot_dataset_num; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE annot_dataset_num (
    dataset_id character varying(256) NOT NULL,
    name character varying(256) NOT NULL,
    value numeric
);


-- ALTER TABLE public.annot_dataset_num OWNER TO public;

--
-- Name: annot_dataset_text; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE annot_dataset_text (
    dataset_id character varying(256) NOT NULL,
    name character varying(256) NOT NULL,
    value character varying(2048)
);


-- ALTER TABLE public.annot_dataset_text OWNER TO public;

--
-- Name: annot_function_call_num; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE annot_function_call_num (
    function_call_id character varying(256) NOT NULL,
    name character varying(256) NOT NULL,
    value numeric
);


-- ALTER TABLE public.annot_function_call_num OWNER TO public;

--
-- Name: annot_function_call_text; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE annot_function_call_text (
    function_call_id character varying(256) NOT NULL,
    name character varying(256) NOT NULL,
    value character varying(2048)
);


-- ALTER TABLE public.annot_function_call_text OWNER TO public;

--
-- Name: annot_script_run_num; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE annot_script_run_num (
    script_run_id character varying(256) NOT NULL,
    name character varying(256) NOT NULL,
    value numeric
);


-- ALTER TABLE public.annot_script_run_num OWNER TO public;

--
-- Name: annot_script_run_text; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE annot_script_run_text (
    script_run_id character varying(256) NOT NULL,
    name character varying(256) NOT NULL,
    value character varying(2048)
);


-- ALTER TABLE public.annot_script_run_text OWNER TO public;

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


-- ALTER TABLE public.app_exec OWNER TO public;

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


-- ALTER TABLE public.app_fun_call OWNER TO public;

--
-- Name: application_execution; Type: VIEW; Schema: public; Owner: public
--

CREATE VIEW application_execution AS
    SELECT app_exec.id, app_exec.app_fun_call_id AS function_call_id, to_timestamp((app_exec.start_time)::double precision) AS start_time, app_exec.duration, app_exec.final_state, app_exec.site FROM app_exec;


-- ALTER TABLE public.application_execution OWNER TO public;

--
-- Name: dataset_containment; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE dataset_containment (
    out_id character varying(256) NOT NULL,
    in_id character varying(256) NOT NULL
);


-- ALTER TABLE public.dataset_containment OWNER TO public;

--
-- Name: mapped; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE mapped (
    id character varying(256) NOT NULL,
    filename character varying(2048)
);


-- ALTER TABLE public.mapped OWNER TO public;

--
-- Name: primitive; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE primitive (
    id character varying(256) NOT NULL,
    value character varying(2048)
);


-- ALTER TABLE public.primitive OWNER TO public;

--
-- Name: dataset; Type: VIEW; Schema: public; Owner: public
--

CREATE VIEW dataset AS
    (SELECT mapped.id, 'mapped'::text AS type, mapped.filename, NULL::character varying AS value FROM mapped UNION ALL SELECT primitive.id, 'primitive'::text AS type, NULL::character varying AS filename, primitive.value FROM primitive) UNION ALL SELECT dataset_containment.out_id AS id, 'composite'::text AS type, NULL::character varying AS filename, NULL::character varying AS value FROM dataset_containment;


-- ALTER TABLE public.dataset OWNER TO public;

--
-- Name: dataset_in; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE dataset_in (
    function_call_id character varying(256) NOT NULL,
    dataset_id character varying(256) NOT NULL,
    parameter character varying(256) NOT NULL
);


-- ALTER TABLE public.dataset_in OWNER TO public;

--
-- Name: dataset_out; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE dataset_out (
    function_call_id character varying(256) NOT NULL,
    dataset_id character varying(256) NOT NULL,
    parameter character varying(256) NOT NULL
);


-- ALTER TABLE public.dataset_out OWNER TO public;

--
-- Name: dataset_io; Type: VIEW; Schema: public; Owner: public
--

CREATE VIEW dataset_io AS
    SELECT dataset_in.function_call_id, dataset_in.dataset_id, dataset_in.parameter, 'I'::text AS type FROM dataset_in UNION ALL SELECT dataset_out.function_call_id, dataset_out.dataset_id, dataset_out.parameter, 'O'::text AS type FROM dataset_out;


-- ALTER TABLE public.dataset_io OWNER TO public;

--
-- Name: ds; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE ds (
    id character varying(256) NOT NULL
);


-- ALTER TABLE public.ds OWNER TO public;

--
-- Name: fun_call; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE fun_call (
    id character varying(256) NOT NULL,
    run_id character varying(256),
    type character varying(16),
    name character varying(256)
);


-- ALTER TABLE public.fun_call OWNER TO public;

--
-- Name: function_call; Type: VIEW; Schema: public; Owner: public
--

CREATE VIEW function_call AS
    SELECT fun_call.id, fun_call.name, fun_call.type, app_fun_call.name AS app_catalog_name, fun_call.run_id AS script_run_id, to_timestamp((app_fun_call.start_time)::double precision) AS start_time, app_fun_call.duration, app_fun_call.final_state, app_fun_call.scratch FROM (fun_call LEFT JOIN app_fun_call ON (((fun_call.id)::text = (app_fun_call.id)::text)));


-- ALTER TABLE public.function_call OWNER TO public;

--
-- Name: provenance_graph_edge; Type: VIEW; Schema: public; Owner: public
--

CREATE VIEW provenance_graph_edge AS
    SELECT dataset_out.function_call_id AS parent, dataset_out.dataset_id AS child FROM dataset_out UNION ALL SELECT dataset_in.dataset_id AS parent, dataset_in.function_call_id AS child FROM dataset_in;


-- ALTER TABLE public.provenance_graph_edge OWNER TO public;

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


-- ALTER TABLE public.rt_info OWNER TO public;

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


-- ALTER TABLE public.run OWNER TO public;

--
-- Name: runtime_info; Type: VIEW; Schema: public; Owner: public
--

CREATE VIEW runtime_info AS
    SELECT rt_info.app_exec_id, to_timestamp((rt_info."timestamp")::double precision) AS "timestamp", rt_info.cpu_usage, rt_info.max_phys_mem, rt_info.max_virt_mem, rt_info.io_read, rt_info.io_write FROM rt_info;


-- ALTER TABLE public.runtime_info OWNER TO public;

--
-- Name: script; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE script (
    hash_value character varying(256) NOT NULL,
    content text
);


-- ALTER TABLE public.script OWNER TO public;

--
-- Name: script_run; Type: VIEW; Schema: public; Owner: public
--

CREATE VIEW script_run AS
    SELECT run.id, run.log_filename, run.swift_version, run.cog_version, run.final_state, to_timestamp((run.start_time)::double precision) AS start_time, run.duration, run.script_filename, run.script_hash, run.tc_file_hash, run.sites_file_hash FROM run;


-- ALTER TABLE public.script_run OWNER TO public;

--
-- Name: sites_file; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE sites_file (
    hash_value character varying(256) NOT NULL,
    content text
);


-- ALTER TABLE public.sites_file OWNER TO public;

--
-- Name: tc_file; Type: TABLE; Schema: public; Owner: public; Tablespace: 
--

CREATE TABLE tc_file (
    hash_value character varying(256) NOT NULL,
    content text
);


-- ALTER TABLE public.tc_file OWNER TO public;
