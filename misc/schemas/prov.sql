
-- executes_in_workflow is unused at the moment, but is intended to associate
-- each execute with its containing workflow 

CREATE TABLE executes_in_workflows
	(workflow_id 		char(128), 
	 execute_id 		char(128) 
	 );

 
 -- processes gives information about each process (in the OPM sense)
 -- it is augmented by information in other tables 

CREATE TABLE processes 
	(id 				char(128) PRIMARY KEY, -- a uri 
	 type 				char(16)	-- specifies the type of process. for any type, it
				  					-- must be the case that the specific type table
									-- has an entry for this process.
									-- Having this type here seems poor normalisation, though? 
	);

-- this gives information about each execute.
-- each execute is identified by a unique URI. other information from
-- swift logs is also stored here. an execute is an OPM process. 

CREATE TABLE executes
	(id 				char(128) PRIMARY KEY, -- actually foreign key to processes 
	 starttime 			numeric,
	 duration 			numeric,
	 finalstate 		char(128), 
	 app 				char(128), 
	 scratch 			char(128) 
	);

	-- this gives information about each execute2, which is an attempt to
	-- perform an execution. the execute2 id is tied to per-execution-attempt
	-- information such as wrapper logs 

CREATE TABLE execute2s
	(id 				char(128) PRIMARY KEY,
	 execute_id			char(128),			 -- secondary key to executes and processes tables
	 starttime 			numeric, 
	 duration 			numeric, 
	 finalstate 		char(128), 
	 site 				char(128) 
	);

-- dataset_usage records usage relationships between processes and datasets;
-- in SwiftScript terms, the input and output parameters for each
-- application procedure invocation; in OPM terms, the artificts which are
-- input to and output from each process that is a Swift execution 


CREATE TABLE dataset_usage
	(process_id 		char(128),	-- foreign key but not enforced because maybe process doesn ' t exist at time. same type as processes.id 
	 direction 			char(1),   	-- I or O for input or output 
	 dataset_id 		char(128)	-- this will perhaps key against dataset table param_name char(128)
							-- the name of the parameter in this execute that
							-- this dataset was bound to. sometimes this must
							-- be contrived (for example, in positional varargs) 
	 );

-- invocation_procedure_name maps each execute ID to the name of its
-- SwiftScript procedure 

CREATE TABLE invocation_procedure_names 
	(execute_id 		char(128),
	 procedure_name 	char(128) 
	);

-- dataset_containment stores the containment hierarchy between
-- container datasets (arrays and structs) and their contents.
-- outer_dataset_id contains inner_dataset_id 

CREATE TABLE dataset_containment 
	( outer_dataset_id 	char(128),
	 inner_dataset_id 	char(128) 
	);

-- dataset_filenames stores the filename mapped to each dataset. As some
-- datasets do not have filenames, it should not be expected that
-- every dataset will have a row in this table 

CREATE TABLE dataset_filenames 
	( dataset_id 		char(128),
	  filename 			char(128) 
	);

-- dataset_values stores the value for each dataset which is known to have
-- a value (which is all assigned primitive types). No attempt is made here
-- to expose that value as an SQL type other than a string, and so (for
-- example) SQL numerical operations should not be expected to work, even
-- though the user knows that a particular dataset stores a numeric value. 

CREATE TABLE dataset_values 
	( dataset_id 		char(128), -- should be primary key 
	  value 			char(128) 
	);

-- known_workflows stores some information about each workflow log that has
-- been seen by the importer: the log filename, swift version and import
-- status. 
CREATE TABLE known_workflows 
	( 
	workflow_id 			char(128), 
	workflow_log_filename 	char(128), 
	version 				char(128), 
	importstatus 			char(128) 
	);

-- workflow_events stores the start time and duration for each workflow
-- that has been successfully imported. 
CREATE TABLE workflow_events 
	( workflow_id 		char(128), 
	  starttime 		numeric, 
	  duration 			numeric 
	);

-- extrainfo stores lines generated by the SWIFT_EXTRA_INFO feature 
CREATE TABLE extrainfo
	( execute2id 		char(128), 
	  extrainfo 		char(1024) 
	);
