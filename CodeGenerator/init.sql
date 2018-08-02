set verify off
set serveroutput on
set echo off
set feedback off
set lines 120
set pages 9999
whenever sqlerror exit
clear screen

set termout off
col install_user new_val INSTALL_USER format a30
col default_language new_val DEFAULT_LANGUAGE format a30


select user sys_user,
       upper('&1.') install_user,
       upper('&2.') default_language
  from V$NLS_VALID_VALUES
 where parameter = 'LANGUAGE'
   and value = upper('&2.');
  
-- Check whether PIT is installed at the installation user
col pit_installed new_val PIT_INSTALLED format a30

select count(distinct object_name) pit_installed
  from (select object_name
          from all_objects pit_installed
         where owner = '&INSTALL_USER.'
           and object_name = 'PIT_ADMIN'
       union all
       select table_name
          from dba_tab_privs
         where '&INSTALL_USER.' in (grantee)
           and table_name = 'PIT_ADMIN');

define section="********************************************************************************"
define h1="*** "
define h2="**  "
define h3="*   "
define s1=".    - "

set termout on