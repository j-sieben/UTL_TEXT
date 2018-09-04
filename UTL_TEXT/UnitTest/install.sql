define ut_dir=UnitTest/

prompt &h3.Remove existing installation
@&ut_dir.clean_up_install.sql

prompt &h2.grant user rights
@set_grants.sql

prompt &h3.Check Installation Preferences
@&ut_dir.version_ge_12_2.sql
@&ut_dir.ut3_exists.sql

prompt &h3.Create packages
prompt &s1.Create package UT_CODE_GENERATOR
@&ut_dir.packages/ut_utl_text.pks
show errors

prompt &s1.Create package Body UT_CODE_GENERATOR
@&ut_dir.packages/ut_utl_text.pkb
show errors

prompt &h3.Execute unit tests
@&ut_dir.run_test.sql