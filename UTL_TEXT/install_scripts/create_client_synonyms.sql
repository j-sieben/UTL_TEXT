-- Parameters:
-- None

@install_scripts/init_client.sql &1. &2.

prompt &h1.Granting access to UTL_TEXT to &REMOTE_USER.

prompt &h3.Grant user rights

@tools/register_client UTL_TEXT
@tools/register_client UTL_TEXT_ADMIN
@tools/register_client CLOB_TABLE
@tools/register_client CHAR_TABLE

prompt &h1.UTL_TEXT granted to &REMOTE_USER.

exit
