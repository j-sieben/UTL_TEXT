define sql_dir=sql/
define plsql_dir=plsql/

prompt &h3.Remove existing installation
@clean_up_install.sql

prompt &h3.Create UTL_TEXT types
prompt &s1.Type CLOB_TABLE
@types/clob_table.tps

prompt &h3.Create UTL_TEXT parameters
@tools/check_pit_exists.sql "scripts/ParameterGroup_UTL_TEXT.sql"

prompt &h3.Create UTL_TEXT messages
@tools/check_pit_exists.sql "messages/&DEFAULT_LANGUAGE./create_messages.sql"

prompt &h3.Create table UTL_TEXT_TEMPLATES
@tables/utl_text_templates.tbl

prompt &h3.Create packages
prompt &s1.Create package UTL_TEXT
@packages/utl_text.pks
show errors

prompt &s1.Create package Body UTL_TEXT
@packages/utl_text.pkb
show errors
