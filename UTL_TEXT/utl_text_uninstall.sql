-- Parameters:
-- 1: Owner of UTL_TEXT
-- 2: Default message language
@init.sql

prompt &h2.grant user rights
@set_grants.sql

alter session set current_schema=&INSTALL_USER.;

prompt &h1.State UTL_TEXT Deinstallation

prompt &h2.Deinstall CORE Functionality
@clean_up_install.sql

prompt
prompt &section.
prompt &h1.Finalize installation
prompt &h2.Revoke user rights
@revoke_grants.sql

prompt &h1.Finished UTL_TEXT Installation

exit
