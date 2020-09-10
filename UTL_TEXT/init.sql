set verify off
set serveroutput on
set echo off
set feedback off
set lines 120
set pages 9999
whenever sqlerror exit
clear screen

set termout on
col sys_user new_val SYS_USER format a30
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

select case count(distinct object_name) when 0 then 'false' else 'true' end pit_installed
  from (select object_name
          from all_objects pit_installed
         where owner = '&INSTALL_USER.'
           and object_name = 'PIT_ADMIN'
       union all
       select table_name
          from dba_tab_privs
         where '&INSTALL_USER.' in (grantee)
           and table_name = 'PIT_ADMIN');

col ora_name_type new_val ORA_NAME_TYPE format a30

select 'varchar2(' || data_length || ' byte)' ORA_NAME_TYPE
  from all_tab_columns
 where table_name = 'USER_TABLES'
   and column_name = 'TABLE_NAME';
           

-- ADJUST THIS SETTING IF YOU WANT ANOTHER TYPE 
define FLAG_TYPE="char(1 byte)";
define C_TRUE="'Y'";
define C_FALSE="'N'";

--define FLAG_TYPE="number(1, 0)";
--define C_TRUE=1;
--define C_FALSE=0;

           
define section="********************************************************************************"
define h1="*** "
define h2="**  "
define h3="*   "
define s1=".    - "

set termout on