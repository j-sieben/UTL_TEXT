set verify off
set serveroutput on
set echo off
set feedback off
set lines 120
set pages 9999
whenever sqlerror exit

set termout off

variable with_pit_var varchar2(10 byte);
variable flag_type_var varchar2(100);
variable true_var varchar2(10 byte);
variable false_var varchar2(10 byte);
variable default_lang_var varchar2(128 byte);

define section="********************************************************************************"
define h1="*** "
define h2="**  "
define h3="*   "
define s1=".    - "

col install_user new_val INSTALL_USER format a30
col ora_name_type new_val ORA_NAME_TYPE format a128
col flag_type new_val FLAG_TYPE format a128
col default_language new_val DEFAULT_LANGUAGE format a128
col c_true new_val C_TRUE format a128
col c_false new_val C_FALSE format a128
col pit_installed new_val PIT_INSTALLED format a128


-- Read settings (some values may be overwritten if PIT is present)
@settings.sql

begin
  :with_pit_var := 'true';
  execute immediate 'begin :x := pit_util.C_TRUE; end;' using out :true_var;
  execute immediate 'begin :x := pit_util.C_FALSE; end;' using out :false_var;
  execute immediate 'begin :x := pit.get_default_language; end;' using out :default_lang_var;
  select lower(data_type) || '(' ||     
           case when data_type in ('CHAR', 'VARCHAR2') then data_length || case char_used when 'B' then ' byte)' else ' char)' end
           else data_precision || ', ' || data_scale || ')'
         end,
         case when data_type in ('CHAR', 'VARCHAR2') then dbms_assert.enquote_literal(:true_var) else to_char(:true_var) end, 
         case when data_type in ('CHAR', 'VARCHAR2') then dbms_assert.enquote_literal(:false_var) else to_char(:false_var) end
    into :flag_type_var, :true_var, :false_var
    from all_tab_columns
   where table_name = 'PARAMETER_LOCAL'
     and column_name = 'PAL_BOOLEAN_VALUE';
  
exception
  when others then
    :with_pit_var := 'false';
    select '&FLAG_TYPE.' flag_type, &C_TRUE. C_TRUE, &C_FALSE. C_FALSE, 'AMERICAN' default_language
      into :flag_type_var, :true_var, :false_var, :default_lang_var
      from dual;
end;
/

select :flag_type_var FLAG_TYPE, :true_var C_TRUE, :false_var C_FALSE, :default_lang_var DEFAULT_LANGUAGE, :with_pit_var PIT_INSTALLED
  from dual;

set termout off

col ora_name_type new_val ORA_NAME_TYPE format a30

select 'varchar2(' || data_length || ' byte)' ORA_NAME_TYPE, user INSTALL_USER
  from all_tab_columns
 where table_name = 'USER_TABLES'
   and column_name = 'TABLE_NAME';
           

set termout on
