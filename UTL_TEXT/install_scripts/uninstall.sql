-- Parameters:
-- 1: Owner of UTL_TEXT
-- 2: Default message language
@init.sql

prompt &section.
prompt &h1.Start UTL_TEXT Deinstallation
prompt &section.

prompt &h2.Deinstall CORE Functionality
@install_scripts/clean_up_install.sql

prompt &section.
prompt &h1.Finished UTL_TEXT Deinstallation
prompt &section.

exit
