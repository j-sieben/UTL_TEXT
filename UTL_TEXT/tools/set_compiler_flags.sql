
prompt &s1.Set Compiler-Flags
alter session set plsql_optimize_level = 2;
begin
  execute immediate q'^alter session set plsql_code_type='NATIVE'^';
exception
  when others then
    null;
end;
/
alter session set plscope_settings='IDENTIFIERS:ALL';

begin
  if '&PIT_INSTALLED.' = 'true' then
    execute immediate q'^alter session set PLSQL_CCFLAGS = 'pit_installed:true'^';
  end if;
end;
/
