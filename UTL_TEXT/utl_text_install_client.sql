-- Parameters:
-- 1: Owner of UTL_TEXT
-- 2: Remote user UTL_TEXT is granted to

@init_client.sql &1. &2.

prompt &h1.Granting access to UTL_TEXT to &REMOTE_USER.

alter session set current_schema=&INSTALL_USER.;
prompt &h3.Grant user rights

@tools/grant_access execute UTL_TEXT
@tools/grant_access select UTL_TEXT_TEMPLATES

prompt &h1.UTL_TEXT granted to &REMOTE_USER.

exit
