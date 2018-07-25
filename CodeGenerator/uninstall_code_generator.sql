@init.sql

alter session set current_schema=&INSTALL_USER.;

prompt &h1.State Code-Generator Deinstallation

prompt &h2.Deinstall CORE Functionality
@clean_up_install.sql

exit;
