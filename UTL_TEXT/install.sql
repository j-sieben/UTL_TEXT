define table_dir=tables/
define package_dir=packages/
define tool_dir=tools/
define type_dir=types/
define script_dir=scripts/

prompt &h3.  Remove existing installation
@clean_up_install.sql

prompt &h3.  Create UTL_TEXT types
prompt &s1.   Type CLOB_TABLE
@&type_dir.clob_table.tps

prompt &h3.  Create UTL_TEXT parameters
@&tool_dir.check_pit_exists.sql "&script_dir.ParameterGroup_UTL_TEXT.sql"

prompt &h3.  Create UTL_TEXT messages
@&tool_dir.check_pit_exists.sql "messages/&DEFAULT_LANGUAGE./MessageGroup_UTL_TEXT.sql"

prompt &h3.  Create table UTL_TEXT_TEMPLATES
@&table_dir.utl_text_templates.tbl

prompt &h3.  Create packages
prompt &s1.   Create package UTL_TEXT
@&package_dir.utl_text.pks
show errors

prompt &s1.   Create package Body UTL_TEXT
@&package_dir.utl_text.pkb
show errors

prompt &s1.   Create internal templates
@&script_dir.TemplateGroup_INTERNAL.sql
