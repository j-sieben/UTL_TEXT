-- Parameters:
-- 1: Owner of UTL_TEXT
-- 2: Remote user UTL_TEXT is granted to

@install_scripts/init_client.sql &1. &2.

prompt &section.
prompt &h1.Granting access to UTL_TEXT to &REMOTE_USER.
prompt &section.

prompt &h2.Grant user rights

@tools/grant_access execute UTL_TEXT
@tools/grant_access execute UTL_TEXT_ADMIN
@tools/grant_access execute CLOB_TABLE
@tools/grant_access execute CHAR_TABLE
@tools/grant_access read UTL_TEXT_TEMPLATES_V

prompt &h1.UTL_TEXT granted to &REMOTE_USER.
prompt &section.

exit
