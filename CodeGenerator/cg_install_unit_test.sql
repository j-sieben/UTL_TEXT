-- Parameters:
-- 1: Owner of SCT, package into which SCT will be installed

@init.sql &1.

alter session set current_schema=sys;
prompt
prompt &section.
prompt &h1.Checking whether required users exist
@check_users_exist.sql

alter session set current_schema=&INSTALL_USER.;
@set_compiler_flags.sql

prompt
prompt &section.
prompt &h1.Code Generator UnitTest Installation at user &INSTALL_USER.
@UnitTest/install.sql

prompt
prompt &section.
prompt &h1.Finalize installation
prompt &h2.Revoke user rights
@revoke_grants.sql

prompt &h1.Finished Code Generator UnitTest Installation

exit
