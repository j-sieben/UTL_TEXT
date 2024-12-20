-- Parameters:
-- None

@install_scripts/init_client.sql &1. &2.

prompt &section.
prompt &h1.Generating synonyms to UTL_TEXT at &REMOTE_USER.
prompt &section.

prompt &h2.Create local synonyms for UTL_TEXT

@tools/register_client UTL_TEXT
@tools/register_client UTL_TEXT_ADMIN
@tools/register_client CLOB_TABLE
@tools/register_client CHAR_TABLE
@tools/register_client UTL_TEXT_TEMPLATES_V

prompt &section.
prompt &h1.UTL_TEXT granted to &REMOTE_USER.

exit
