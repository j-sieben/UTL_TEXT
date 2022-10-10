prompt &s1.PIT is present, copy boolean value type from PIT
   
-- Copy boolean value type from PIT
col FLAG_TYPE  new_val FLAG_TYPE format a128
col C_FALSE  new_val C_FALSE format a128
col C_TRUE  new_val C_TRUE format a128

select lower(data_type) || '(' ||     
         case when data_type in ('CHAR', 'VARCHAR2') then data_length || case char_used when 'B' then ' byte)' else ' char)' end
         else data_precision || ', ' || data_scale || ')'
       end FLAG_TYPE,
       case when data_type in ('CHAR', 'VARCHAR2') then dbms_assert.enquote_literal(pit_util.c_true) else pit_util.c_true end C_TRUE, 
       case when data_type in ('CHAR', 'VARCHAR2') then dbms_assert.enquote_literal(pit_util.c_false) else pit_util.c_false end C_FALSE
  from all_tab_columns
 where table_name = 'PARAMETER_LOCAL'
   and column_name = 'PAL_BOOLEAN_VALUE';
   