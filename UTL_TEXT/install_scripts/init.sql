set verify off
set serveroutput on
set echo off
set feedback off
set lines 120
set pages 9999
whenever sqlerror exit

set termout off
col install_user new_val INSTALL_USER format a30
--col default_language new_val DEFAULT_LANGUAGE format a30
define DEFAULT_LANGUAGE=GERMAN

  
-- Check whether PIT is installed at the installation user
col pit_installed new_val PIT_INSTALLED format a30

select case count(distinct object_name) when 0 then 'false' else 'true' end PIT_INSTALLED
  from (select object_name
          from all_objects
         where object_name = 'PIT_ADMIN'
       union all
       select table_name
          from all_tab_privs
         where table_name = 'PIT_ADMIN');

col ora_name_type new_val ORA_NAME_TYPE format a30

select 'varchar2(' || data_length || ' byte)' ORA_NAME_TYPE, user INSTALL_USER
  from all_tab_columns
 where table_name = 'USER_TABLES'
   and column_name = 'TABLE_NAME';
           

-- Read settings
@settings.sql

define section="********************************************************************************"
define h1="*** "
define h2="**  "
define h3="*   "
define s1=".    - "

set termout on
