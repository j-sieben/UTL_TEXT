set termout off

column script new_value SCRIPT
select case when count(*) = 0
            then '&2.' 
            else 'null.sql' end script
  from all_objects
 where object_type = 'PACKAGE'
   and object_name = upper('&1.')
   and owner = '&INSTALL_USER.';

set termout on
@&script.