-- Parameters:
-- 1: Owner of CODE_GENERATOR
-- 2: Remote user CODE_GENERATOR is granted to

@init_client.sql &1. &2.

prompt &h1.Granting access to CODE_GENERATOR to &REMOTE_USER.

alter session set current_schema=&INSTALL_USER.;
prompt &h3.Grant user rights
prompt &s1.Grant execute on CODE_GENERATOR
grant execute on &INSTALL_USER..CODE_GENERATOR to &REMOTE_USER.;

prompt &s1.Grant select on CODE_GENERATOR_TEMPLATES
grant select on &INSTALL_USER..CODE_GENERATOR_TEMPLATES to &REMOTE_USER.;


alter session set current_schema=&REMOTE_USER.;
prompt &h3.Create synonyms
prompt &s1.Create synonym for CODE_GENERATOR
create or replace synonym CODE_GENERATOR for &INSTALL_USER..CODE_GENERATOR;

prompt &s1.Create synonym for CODE_GENERATOR_TEMPLATES
create or replace synonym CODE_GENERATOR_TEMPLATES for &INSTALL_USER..CODE_GENERATOR_TEMPLATES;

prompt &h1.CODE_GENERATOR granted to &REMOTE_USER.

exit
