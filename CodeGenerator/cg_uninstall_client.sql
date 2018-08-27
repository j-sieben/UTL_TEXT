-- Parameters:
-- 1: Owner of CODE_GENERATOR
-- 2: Remote user CODE_GENERATOR is granted to

@init_client.sql &1. &2.

prompt &h1.Revoking access to CODE_GENERATOR from &REMOTE_USER.

alter session set current_schema=&INSTALL_USER.;
prompt &h3.Revoke user rights
prompt &s1.Revoke execute on CODE_GENERATOR
revoke execute on &INSTALL_USER..CODE_GENERATOR from &REMOTE_USER.;


alter session set current_schema=&REMOTE_USER.;
prompt &h3.Drop synonyms
prompt &s1.Drop synonym for CODE_GENERATOR
drop synonym CODE_GENERATOR;

prompt &h1.CODE_GENERATOR revoked from &REMOTE_USER.

exit
