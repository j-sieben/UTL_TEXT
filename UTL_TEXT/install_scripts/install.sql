-- Parameters:
-- None. UTL_TEXT will be installed into the user logged on and, if present,
-- grab the default language name from the existing PIT installation

define install_scripts=install_scripts/
define table_dir=tables/
define package_dir=packages/
define tool_dir=tools/
define type_dir=types/
define script_dir=scripts/

@&install_scripts.init.sql

@&tool_dir.set_compiler_flags.sql

prompt
prompt &section.
prompt &h1.State UTL_TEXT Installation at user &INSTALL_USER.

prompt &h3.Create UTL_TEXT types
prompt &s1.Type CLOB_TABLE
@&type_dir.clob_table.tps
prompt &s1.Type CHAR_TABLE
@&type_dir.char_table.tps

prompt &h3.Create UTL_TEXT parameters
@&tool_dir.check_pit_exists.sql "&script_dir.ParameterGroup_UTL_TEXT.sql"

prompt &h3.Create UTL_TEXT messages for &DEFAULT_LANGUAGE.
@&tool_dir.check_pit_exists.sql "messages/&DEFAULT_LANGUAGE./MessageGroup_UTL_TEXT.sql"

prompt &h3.Create tables
@&tool_dir.create_table utl_text_templates

prompt &h3.Create packages
prompt &s1.Create package UTL_TEXT_ADMIN
@&package_dir.utl_text_admin.pks
show errors

prompt &s1.Create package UTL_TEXT
@&package_dir.utl_text.pks
show errors

prompt &s1.Create package Body UTL_TEXT_ADMIN
@&package_dir.utl_text_admin.pkb
show errors

prompt &s1.Create package Body UTL_TEXT
@&package_dir.utl_text.pkb
show errors

prompt &s1.Create internal templates
@&script_dir.TemplateGroup_INTERNAL.sql

prompt &h1.Recompiling invalid objects
declare
  l_invalid_objects binary_integer;
begin
  dbms_utility.compile_schema(
    schema => user,
    compile_all => false);
    
  select count(*)
    into l_invalid_objects
    from user_objects
   where status = 'INVALID';
   
  dbms_output.put_line(l_invalid_objects || ' invalid objects found');
end;
/
prompt &h1.Finished UTL_TEXT Installation

exit
