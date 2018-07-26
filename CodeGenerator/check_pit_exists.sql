set termout off

column script new_value SCRIPT
select case when &PIT_INSTALLED. = 1
            then '&1.' 
            else 'null.sql' end script
  from dual;

set termout on
@&script.