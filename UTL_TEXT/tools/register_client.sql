
begin
  dbms_output.put_line('&s1.Create synonym &1. for &INSTALL_USER..&1. at &REMOTE_USER.');
  execute immediate 'create or replace synonym &1. for &INSTALL_USER..&1.';
end;
/

