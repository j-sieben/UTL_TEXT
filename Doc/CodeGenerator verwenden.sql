create table addressees(
  addr_id number,
  salutation varchar2(10),
  title varchar2(10),
  first_name varchar2(20),
  last_name varchar2(20),
  constraint pk_addressees primary key(addr_id)
) organization index;

merge into addressees a
using (select 1 addr_id,
              'Frau' salutation,
              'Dr.' title,
              'Elfriede' first_name,
              'Müller' last_name
         from dual 
        union all
       select 2, 'Herr', null, 'Peter', 'Schmitz' from dual union all
       select 3, 'Herr', 'Prof.', 'Walter', 'Meyer' from dual) v
   on (a.addr_id = v.addr_id)
 when not matched then insert(addr_id, salutation, title, first_name, last_name)
      values(v.addr_id, v.salutation, v.title, v.first_name, v.last_name);
      
commit;

select *
  from addressees;

-- Format der Ersetzungszeichenfolge ist verbessert: #<Name>|<Präfix wenn NOT NULL>|<Postfix wenn NOT NULL|<Wert wenn NULL#'

declare
  c_template constant varchar2(32767) := q'^Hallo #SALUTATION# #TITLE|| |##LAST_NAME#,^';
  l_row_tab code_generator.row_tab;
  l_result varchar2(32767);
begin

  code_generator.copy_table_to_row_tab(
    p_stmt => 'select * from addressees', 
    p_row_tab => l_row_tab, 
    p_first_column_is_template => false);
    
  code_generator.bulk_replace(
    p_template => c_template,
    p_delimiter => chr(13),
    p_row_tab => l_row_tab,
    p_result => l_result);
    
  dbms_output.put_line(l_result);
end;
/

create table address_types(
  atyp_id varchar2(20),
  template_mode varchar2(20),
  text_template varchar2(200),
  constraint pk_address_types primary key(atyp_id)
);

merge into address_types a
using (select 'FIRMA' atyp_id,
              'SALUTATION' template_mode,
              q'^Sehr geehrte Damen und Herren,^' text_template
         from dual
        union all
       select 'PRIVAT', 'SALUTATION', q'^Hallo #SALUTATION# #TITLE|| |##LAST_NAME#,^' from dual) v
   on (a.atyp_id = v.atyp_id)
 when not matched then insert(atyp_id, template_mode, text_template)
      values(v.atyp_id, v.template_mode, v.text_template);

commit;

alter table addressees add (addr_atyp_id varchar2(20));
alter table addressees add constraint fk_addr_atyp_id foreign key(addr_atyp_id)
  references address_types(atyp_id);


merge into addressees a
using (select 1 addr_id,
              'PRIVAT' addr_atyp_id,
              'Frau' salutation,
              'Dr.' title,
              'Elfriede' first_name,
              'Müller' last_name
         from dual 
        union all
       select 2, 'PRIVAT', 'Herr', null, 'Peter', 'Schmitz' from dual union all
       select 3, 'PRIVAT', 'Herr', 'Prof.', 'Walter', 'Meyer' from dual union all
       select 4, 'FIRMA', null, null, null, 'ACME Corp.' from dual) v
   on (a.addr_id = v.addr_id)
 when matched then update set
      addr_atyp_id = v.addr_atyp_id
 when not matched then insert(addr_id, addr_atyp_id, salutation, title, first_name, last_name)
      values(v.addr_id, v.addr_atyp_id, v.salutation, v.title, v.first_name, v.last_name);
      
commit;

select t.text_template, a.salutation, a.title, a.first_name, a.last_name
  from addressees a
  join address_types t
    on a.addr_atyp_id = t.atyp_id
 where t.template_mode = 'SALUTATION';
 
 
declare
  l_row_tab code_generator.row_tab;
  l_result varchar2(32767);
  c_stmt constant varchar2(1000) := q'^select t.text_template, a.salutation, a.title, a.first_name, a.last_name
  from addressees a
  join address_types t
    on a.addr_atyp_id = t.atyp_id
 where t.template_mode = 'SALUTATION'^';
begin
    
  code_generator.generate_text(
    p_stmt => c_stmt,
    p_delimiter => chr(13),
    p_result => l_result);
    
  dbms_output.put_line(l_result);
end;
/

-- Zweistufige Ersetzung:
declare
  l_key_value_tab code_generator.key_value_tab;
  l_result varchar2(32767);
  c_list_template constant varchar2(100) := q'^Anredeliste vom #DATUM#
#LISTE#
^';
  c_list_stmt constant varchar2(1000) := q'^select :template, sysdate datum, :result liste from dual^';
  c_stmt constant varchar2(1000) := q'^select t.text_template, a.salutation, a.title, a.first_name, a.last_name
  from addressees a
  join address_types t
    on a.addr_atyp_id = t.atyp_id
 where t.template_mode = 'SALUTATION'^';
 
  l_cursor sys_refcursor;
begin
 
  -- Step 1: Detaildatensaetze bearbeiten
  code_generator.generate_text(
    p_stmt => c_stmt,
    p_delimiter => chr(13),
    p_result => l_result);

  -- Step 2: Uebergeordnetes Template bearbeiten und Detail als Variable uebergeben
  open l_cursor for c_list_stmt using c_list_template, l_result;
  
  code_generator.generate_text(
    p_cursor => l_cursor,
    p_result => l_result);
  
  -- Cursor wird in GENERATE_TEXT geschlossen
  
  dbms_output.put_line(l_result);
end;
/
