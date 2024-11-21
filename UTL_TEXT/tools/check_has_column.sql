set termout off

column script new_value SCRIPT
select case when count(*) = 0
            then '&type_dir.&1..tps' 
            else '&tool_dir.null.sql' end script
  from user_objects
 where object_type = 'TYPE'
   and object_name = upper('&1.');

set termout on
@&script.