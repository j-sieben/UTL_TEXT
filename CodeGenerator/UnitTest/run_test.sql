declare
  l_version pls_integer;
  l_cmd varchar2(200);
  l_owner varchar2(30);
begin

  select owner
    into l_owner
    from all_objects
   where object_type = 'PACKAGE'
     and object_name = 'UT';
    
  execute immediate 'alter session set current_schema=&INSTALL_USER.';
  execute immediate 'grant inherit privileges on user ' || user || ' to ' || l_owner;
  ut.run;
  execute immediate 'revoke inherit privileges on user ' || user || ' from ' || l_owner;
  
end;
/

alter session set current_schema=&INSTALL_USER.;