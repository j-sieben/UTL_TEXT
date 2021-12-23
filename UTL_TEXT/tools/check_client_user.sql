
@install_scripts/init_client.sql &1.

prompt &h2.Checking whether client user is not UTL_TEXT owner

set termout off
col utl_text_owner new_val UTL_TEXT_OWNER format a30

select max(user) UTL_TEXT_OWNER
  from user_objects
 where object_name = 'PIT_ADMIN'
   and object_type = 'PACKAGE';
         
begin
  if '&UTL_TEXT_OWNER.' is not null then
    raise_application_error(-20000, '&UTL_TEXT_OWNER. is the owner of UTL_TEXT. No grant necessary.');
  end if;
  dbms_output.put_line('&s1.Test passed.');
end;
/
set termout on