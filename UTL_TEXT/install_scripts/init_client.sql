set verify off
set serveroutput on
set echo off
set feedback off
set lines 120
set pages 9999
whenever sqlerror exit
set termout off

-- make parameter 1 optional
col 1 new_val 1
col install_user new_val INSTALL_USER format a128
col remote_user new_val REMOTE_USER format a128

select '' "1"
  from dual
 where null is not null;

select owner install_user, 
       case when instr('&1.', '[') > 0 
       then substr(upper('&1.'), instr('&1.', '[') + 1, length('&1.') - instr('&1.', '[') - 1)
       else coalesce(upper('&1.'), user) end remote_user
  from all_objects
 where object_type = 'PACKAGE'
   and object_name = 'UTL_TEXT';

define section="********************************************************************************"
define h1="*** "
define h2="**  "
define h3="*   "
define s1=".    - "

set termout on