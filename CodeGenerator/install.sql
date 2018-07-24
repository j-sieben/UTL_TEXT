define sql_dir=sql/
define plsql_dir=plsql/

prompt &h3.Remove existing installation
@clean_up_install.sql

prompt &h3.Create CodeGenerator types
@&sql_dir.create_types.sql

prompt &h3.Create CodeGenerator parameters
@&sql_dir.create_parameters.sql

prompt &h3.Create CodeGenerator messages
@&sql_dir.create_messages.sql

prompt &h3.Create table CODE_GENERATOR_TEMPLATES
@&sql_dir.code_generator_templates.tbl

prompt &h3.Create packages
prompt &s1.Create package CODE_GENERATOR
@&plsql_dir.code_generator.pks
show errors

prompt &s1.Create package Body CODE_GENERATOR
@&plsql_dir.code_generator.pkb
show errors
