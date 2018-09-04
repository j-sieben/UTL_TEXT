declare
  l_result boolean;
begin
  l_result := dbms_db_version.ver_le_12_1;
  if l_result then
    raise_application_error(-20000, 'Database version must be 12.2 at least');
  end if;
exception
  when others then
    raise_application_error(-20000, 'Database version must be 12.2 at least');
end;
/
