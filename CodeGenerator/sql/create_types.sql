create or replace type clob_table as table of clob;
/

create or replace type key_value_type is object(
  key &ORA_NAME_TYPE.,
  value clob
);
/

create or replace type key_value_tab as table of key_value_type;
/
