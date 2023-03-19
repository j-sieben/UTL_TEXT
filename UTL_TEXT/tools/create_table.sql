set termout off
column SCRIPT new_value SCRIPT format a100
column MSG new_value MSG format a30

select case when count(*) = 0
         then '&table_dir.&1..tbl'
         else '&tool_dir.null.sql'
       end script,
       case when count(*) = 0
         then '&s1.Create Table &1.'
         else '&s1.Table &1. already exists'
       end msg
  from user_objects
 where object_type = 'TABLE'
   and object_name = upper('&1.');
set termout on

prompt &MSG.
@&SCRIPT.


