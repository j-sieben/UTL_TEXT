-- Parameters:
-- 1: Owner of UTL_TEXT
-- 2: Remote user UTL_TEXT is granted to

@init_client.sql &1. &2.

prompt &h1.Granting access to UTL_TEXT to &REMOTE_USER.

alter session set current_schema=&INSTALL_USER.;
prompt &h3.Grant user rights
prompt &s1.Grant execute on UTL_TEXT
grant execute on &INSTALL_USER..UTL_TEXT to &REMOTE_USER.;

prompt &s1.Grant select on UTL_TEXT_TEMPLATES
grant select on &INSTALL_USER..UTL_TEXT_TEMPLATES to &REMOTE_USER.;


alter session set current_schema=&REMOTE_USER.;
prompt &h3.Create synonyms
prompt &s1.Create synonym for UTL_TEXT
create or replace synonym UTL_TEXT for &INSTALL_USER..UTL_TEXT;

prompt &s1.Create synonym for UTL_TEXT_TEMPLATES
create or replace synonym UTL_TEXT_TEMPLATES for &INSTALL_USER..UTL_TEXT_TEMPLATES;

prompt &h1.UTL_TEXT granted to &REMOTE_USER.

exit
