-- Parameters:
-- 1: Owner of UTL_TEXT
-- 2: Remote user UTL_TEXT is granted to

@init_client.sql &1. &2.

prompt &section.
prompt &h1.Revoking access to UTL_TEXT from &REMOTE_USER.
prompt &section.

alter session set current_schema=&INSTALL_USER.;
prompt &h2.Revoke user rights

@tools/revoke_access execute UTL_TEXT_ADMIN
@tools/revoke_access execute UTL_TEXT
@tools/revoke_access select UTL_TEXT_TEMPLATES

prompt
prompt &section.
prompt &h1.Finalize installation
prompt &h2.Revoke user rights
@revoke_grants.sql

prompt &section.
prompt &h1.Finished UTL_TEXT Client De-Installation
prompt &section.

exit
