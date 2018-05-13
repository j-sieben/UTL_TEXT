# CodeGenerator

Helper Package to support generating template based texts.

## What it is

CodeGenerator is a helper package to support creating text based on templates with replacement anchors. This kind of replacement is often required when generating dynamic SQL or PL/SQL-code or when putting together mail messages and the like.

To reduce the amount of constants used in the code and to remove the burdon of writing the same kind of code over and over again, CodeGenerator helps in putting together the results easily.

Main idea is that a SQL query is provided that offers the replacement values under the column name of the replacement anchor. Therefore, it there is a replacement anchor #MY_REPLACEMENT# this requires the SQL query to offer the replacement value in a row under column name MY_REPLACEMENT. Plus, the replacement anchor allows for an internal syntax that enables the user to handle the most common replacement scenarios without any conditional logic.

The replacement anchor in a template must be surrounded by #-signs, although this is parameterizable. It may consist of up to four internal blocks, separated by a pipe »|« as in this example: ```#COLUMN_SIZE|(| char)|#```. The meaning of the internal blocks are as follows:

1. Name of the replacement anchor
2. Optional prefix put in front of the replacement value if the value exists
3. Optional postfix put after the replacement value if the value exists
4. Optional NULL replacement value if the replacement value is NULL

If you intend to surround the value with brackets if the value is not `NULL` and pass the string `NULL` if the value is `NULL`, you may write `#SAMPLE_REPLACEMENT|(|), |NULL#` to achieve this.

## Functionality

CodeGenerator mainly consists of logic to analyze the given cursor and populate a PL/SQL table indexed by varchar2 from the query result. It uses the column name as the key and the converted column value (as char) as the value of the entry. Based on that PL/SQL table, all occurences of the replacement anchors are replaced with the respective replacement values and the result is returned. 

A second group of methods allows to return a table of CLOB with multiple replacements at once. In this case CodeGenerator prepares a list of PL/SQL tables (one for each row of the result) and processes this list against the respective template, which may be one constant template or one individual template per row returned by the query. In this case, by convention the first column is expected to hold the template.

So you may choose to work with a CLOB containing all replacements in one String or with a table of CLOB containing the replacements in seprate instances. This is useful if you like to reference the replacements in SQL using a `table()`-Function.

All methods accept a `SYS_RECRURSOR` as the data source and additional parameters like a constant template, a delimiter sign or an indent amount to indent the result row by row. Both methods are overloaded as procedures and functions, allowing a flexible usage.

As an example, review this code snippet:
```
set serveroutput on
declare
  l_value_cur sys_refcursor;
  l_tmpl varchar2(32767) := q'^#COLUMN_NAME# #COLUMN_TYPE##COLUMN_SIZE|(| char)##COLUMN_PRECISION|(|)#^';
  l_row_tab code_generator.row_tab;
  l_result varchar2(32767);
begin
  open l_value_cur for
    select 'FIRST_COLUMN' column_name, 'VARCHAR2' column_type, '25' column_size, null column_precision from dual union all
    select 'SECOND_COLUMN', 'NUMBER', null, '38,0' from dual union all
    select 'THIRD_COLUMN', 'INTEGER', null, null from dual;
  code_generator.generate_text(
    p_cursor => l_value_cur,
    p_template => l_tmpl,
    p_result => l_result,
    p_delimiter => ',' || chr(10));
  dbms_output.put_line(l_result);
end;
/

FIRST_COLUMN VARCHAR2(25 char),
SECOND_COLUMN NUMBER(38,0),
THIRD_COLUMN INTEGER

```

This approach uses the procedure interface to invoke the CodeGenerator. Alternatively, you may want to call CodeGenerator like this:

```
declare
  l_tmpl varchar2(32767) := q'^#COLUMN_NAME# #COLUMN_TYPE##COLUMN_SIZE|(| char)##COLUMN_PRECISION|(|)#^';
  l_result varchar2(32767);
begin
  select code_generator.generate_text(cursor(
           select l_tmpl tmpl, 
                  'FIRST_COLUMN' column_name, 
                  'VARCHAR2' column_type, 
                  '25' column_size, 
                  null column_precision 
             from dual 
            union all
           select l_tmpl, 'SECOND_COLUMN', 'NUMBER', null, '38,0' from dual union all
           select l_tmpl, 'THIRD_COLUMN', 'INTEGER', null, null from dual),
           ',' || chr(10))
    into l_result
    from dual;
  dbms_output.put_line(l_result);
end;
/
```

In the second example, you utilize the function overload and pass in the template as the first column of the query. Tis allows to call the CodeGenerator directly from SQL with a cursor expression, reducing code even further. A further improvement would be to offer the templates via a table, then you could eliminate a PL/SQL-block all together and call the CodeGenerator as part of your normal SQL.
