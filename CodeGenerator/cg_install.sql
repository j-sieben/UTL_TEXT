-- Parameters:
-- 1: Owner of SCT, package into which SCT will be installed
-- 2: Default language all messages are generated at, if PIT is present

@init.sql &1.

alter session set current_schema=&SYS_USER.;
prompt
prompt &section.
prompt &h1.Checking whether required users exist
@check_users_exist.sql

prompt &h2.grant user rights
@set_grants.sql

alter session set current_schema=&INSTALL_USER.;
@set_compiler_flags.sql

prompt
prompt &section.
prompt &h1.State Code Generator Installation at user &INSTALL_USER.
@install.sql

prompt
prompt &section.
prompt &h1.Finalize installation
prompt &h2.Revoke user rights
@revoke_grants.sql

prompt &h1.Finished Code Generator Installation

exit
