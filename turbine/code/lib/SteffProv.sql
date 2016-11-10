
-- This schema was my interpretation of MTCProv model proposed in 2012. It is a modified version of prov
-- this is supposed to work with sqlite3 so that I can integrate it in a tcl file
--Steff Prov is my updated schema based off of MTCProv

CREATE TABLE ApplicationCatalog
(
	hashValue 		char(128) PRIMARY KEY,
	catalogEntries 	text	
);

CREATE TABLE ApplicationExecution
(
	applicationExecutionId	char(128) PRIMARY KEY,
	try						int,
	startTime 				datetime,
	duration				int,
	finalState 				char(128),
	stdios					char(128),
	arguments				char(128),
	site 					char(128),
	notes					text

);

CREATE TABLE ApplicationFunctionCall
(
	startTime 			datetime,  --what type should this be?
	duration 			int,
	finalState			char(128),
	app_catalog_name	char(128)
);

CREATE TABLE ConsumesProperty
(
	parameter 		char(128)
);

CREATE TABLE FunctionCall
(
	functionCallId 	char(128) PRIMARY KEY,
	type 			char(128),
	name 			char(128),
	notes			text
);


CREATE TABLE Mapped
(
	filename 		char(128)
);

CREATE TABLE Primitive
(
	value 			text
);

CREATE TABLE ProducesProperty
(
	parameter 		char(128)
);


CREATE TABLE RuntimeSnapshot
(
	timestamp		datetime PRIMARY KEY,
	cpuUsage		float,
	maxPhysMem		int,
	maxVirtMem		int,
	ioRead			int,
	ioWrite			int
);

CREATE TABLE  Script
(
	hashValue 		char(128) PRIMARY KEY,
	sourceCode 		text
);

CREATE TABLE ScriptRun
(
	scriptRunId 			char(128) PRIMARY KEY, 
	scriptFileName 			char(128),
	logFileName 			char(128),			--maybe use varchar depending on what we get for each
	swiftVersion 			char(128),
	cogVersion 				char(128),
	finalState 				char(128),
	starttime 				datetime,
	duration 				int,
	scriptHash 				char(128),
	applicationCatalogHash 	char(128),
	siteCatalogHash 		char(128)

);


CREATE TABLE ScriptRunAnnotation
(
	key 			char(128) PRIMARY KEY,
	value 			text
);

CREATE TABLE SiteCatalog
(
	hashValue 		char(128) PRIMARY KEY,
	catalogEntries 	text
);


CREATE TABLE Variable
(
	variableId 		char(128) PRIMARY KEY

);

CREATE TABLE VariableAnnotation
(
	key 			char(128) PRIMARY KEY,
	value			text			
);


-- Here are some types that are now tables because of how sqlite3 works.

CREATE TABLE compare_run_by_annot_num_type
(
	run_id varchar,
	name varchar,
	value numeric
);

CREATE TABLE compare_run_by_annot_txt_type
(
	run_id varchar,
	name varchar,
	value varchar
);

CREATE TABLE compare_run_by_key_numeric_type
(
	run_id varchar,
	name varchar,
	value numeric
);

CREATE TABLE compare_run_by_key_text_type
(
	run_id varchar,
	name varchar,
	value varchar
);

CREATE TABLE compare_run_by_parameter_type
(
	run_id varchar,
	parameter varchar,
	value varchar
);












