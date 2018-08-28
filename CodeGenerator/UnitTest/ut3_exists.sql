
declare
  l_version pls_integer;
  l_cmd varchar2(200);
  l_owner varchar2(30);
begin

  select 'begin :x := to_number(substr(' || owner || '.' || object_name || '.version, 2, 1)); end;' cmd, owner
    into l_cmd, l_owner
    from all_objects
   where object_type = 'PACKAGE'
     and object_name = 'UT';
    
  execute immediate 'alter session set current_schema=' || user;
  execute immediate 'grant inherit privileges on user ' || user || ' to ' || l_owner;
  execute immediate l_cmd using out l_version;
  execute immediate 'revoke inherit privileges on user ' || user || ' from ' || l_owner;
  
  if l_version < 3 then
    raise_application_error(-20000, 'UT_PLSQL in version 3 or above is required to install the unit test package');
  end if;
  
exception
  when others then
    dbms_output.put_line('Expected to find UT3-Framework. This framework is available under https://github.com/utPLSQL/utPLSQL');
    raise_application_error(-20000, 'UT_PLSQL in version 3 or above is required to install the unit test package');
end;
/

alter session set current_schema=&INSTALL_USER.;