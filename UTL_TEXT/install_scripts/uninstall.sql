-- Parameters:
-- 1: Owner of UTL_TEXT
-- 2: Default message language
@init.sql

prompt &h1.State UTL_TEXT Deinstallation

prompt &h2.Deinstall CORE Functionality
@install_scripts/clean_up_install.sql

prompt &h1.Finished UTL_TEXT Installation

exit
