
prompt &s1.Set Compiler-Flags
alter session set plsql_optimize_level = 3;
alter session set plsql_code_type='NATIVE';
alter session set plscope_settings='IDENTIFIERS:ALL';

declare
  l_pit_installed pls_integer;
begin
  select count(*)
    into l_pit_installed
    from all_objects
   where owner = '&INSTALL_USER.'
     and object_type = 'PACKAGE'
     and object_name = 'PIT';
     
  if l_pit_installed = 1 then
    execute immediate q'^alter session set PLSQL_CCFLAGS = 'pit_installed:true'^';
  end if;
end;
/
