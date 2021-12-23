-- Parameters:
-- 1: Owner of UT_UTL_TEXT
-- 2: Language, dummy
@init.sql

prompt &h2.grant user rights
@set_grants.sql

alter session set current_schema=&INSTALL_USER.;

prompt &h1.State UTL_TEXT UnitTest Deinstallation

@UnitTest/clean_up_install.sql

prompt
prompt &section.
prompt &h1.Finalize installation
prompt &h2.Revoke user rights
@revoke_grants.sql

prompt &h1.Finished UTL_TEXT UnitTest De-Installation

exit
