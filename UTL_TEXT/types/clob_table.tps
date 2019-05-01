declare
  x_object_exists exception;
  pragma exception_init(x_object_exists, -955);
begin
  execute immediate 'create or replace type clob_table as table of clob';
exception
  when x_object_exists then
    null;
end;
/
