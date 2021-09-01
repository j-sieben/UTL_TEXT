# UTL_TEXT, including CodeGenerator

Helper Package to collect String related utilities and support generating template based texts.

## What it is

`UTL_TEXT` contains two earlier projects, `UTL_TEXT` and `CODE_GENERATOR`. `UTL_TEXT` contained some simple text related utilities, whereas `CODE_GERNERATOR` does some advanced things that need further explanation. As it turned out to be a nightmare to maintain two packages with partly overlapping functionality, I decided to combine both packages into one.

The basic `UTL_TEXT` functionality is self explanatory and consists mainly of simple helper method to make working with strings easier. The rest of this intro deals with the functionality of method `BULK_REPLACE` and the code generator.

### BULK_REPLACE

In all my projects, I create a method like this (or use `UTL_TEXT` if possible). The basic intention for this method is to allow to replace any number of replacement anchors with replacement strings in one go. In comparison to this very simple approach (the function simply iterates over an instance of a `CHAR_TABLE` which simply is a `table of varchar2(4000 byte)`), the `BULK_REPLACE` method including in `UTL_TEXT` is much more powerful, as it allows for the some flexibility in replacing anchors with values. As this flexibility is required by the code generator as well, it is a good start to explain the different possibilities.

CAVEAT: This method is not optimized for performance, as it is capable of generating codes which exceed the 32KByte barrier. This in turn makes it necessary to base some of its function on the powerful, but slow `DBMS_LOB` package. Main focus of this method is to create code in the vicinity of development or master data maintenance.

#### Basic Usage

As a first example, consider this code snippet:

```
SQL> select utl_text.bulk_replace('My first #1#', char_table('1', 'replacement')) result
  2    from dual;

RESULT
---------------------
My first replacement
```

In this example, `#1#` is replaced with `replacement`, which could have been achieved with a simple replace method as well. But you're free to put whatever amount of replacement anchors into the text, as `char_table` is a nested table of type `varchar2(4000 byte)`. You may reference the anchors by any valid Oracle name or by number, as in the example above.


#### Recursion

The real power comes from `UTL_TEXT` recursive abilities. As a simple example, the replacement contains a second anchor:

```
SQL> select utl_text.bulk_replace('A simple #1#', char_table(
  2           '1', 'replacement with #2#',
  3           '2', 'recursive replacements')) result
  4    from dual;

RESULT
-------------------------------------------------
A simple replacement with recursive replacements
```

This example also shows how to include more than one replacement key-value-pair.

#### `NULL` value treatment

To make things a bit more funny, you may extend the anchors syntax to support `NULL` value treatment. In the following example, we want to inlude a `PRE` and `POST` before and after a non `NULL`-value and a `NULL` for any `NULL` value:

```
SQL> select utl_text.bulk_replace(
  2            'Null treatment for #1|PRE|POST|NULL# and #2|PRE|POST|NULL#',
  3            char_table(
  4             '1', ' value 1 ',
  5             '2', null)) result
  6    from dual;

RESULT
---------------------------------------------
Null treatment for PRE value 1 POST and NULL
```

#### Recursion with `NULL` value treatment

This is the foundation for powerful string replacements as in the next example where we want to include a second value with `NULL` treatment, but only, if the first value is `NULL`. If we do this, we need a different syntax for the embedded anchor to distinguish it from the surrounding anchor. We will be using different characters which are referenced as `secondary anchor` and `secondoray replacement` chars. They allow to nest an anchor into a surrounding anchors conditional replacements:

```
SQL> select utl_text.bulk_replace(
  2            'Null treatment for #1|PRE|POST|^2~PRE~POST~NULL^#',
  3            char_table(
  4             '1', null,
  5             '2', ' value 2 ')) result
  6    from dual;

RESULT
--------------------------------------------------------------------------------
Null treatment for PRE value 2 POST
```

Of course this does not have to be as complex as shown above. It's perfectly ok to just pass in a second replacement anchor such as in `#OUTER|PRE|POST|^INNER^#`. Here anchor `INNER` is replaced only if anchor `OUTER` is `NULL`.

All these options are available not only with `BULK_REPLACE`, but with `GENERATE_TEXT` and `GENEREATE_TEXT_TABLE` as well, as all of them reuse the same `BULK_REPLACE` engine underneath.

`BULK_REPLACE` is available as a procedure and a function overload, plus an overload that accepts a template as a parameter and a list of replacement chunks as a PL/SQL table of type `CLOB indexed by varchar2`. This comes in handy if you have your replacement chunks in that format.

`UTL_TEXT` is a helper package to support creating text based on templates with replacement anchors. This kind of replacement is often required when generating dynamic SQL or PL/SQL-code or when putting together mail messages and the like. To reduce the amount of constants used in the code and to remove the burdon of writing the same kind of code over and over again, `UTL_TEXT` helps in putting together the results easily.

Main idea is that a SQL query is provided that offers the replacement values under the column name of the replacement anchor. Therefore, it there is a replacement anchor `#MY_REPLACEMENT#` this requires the SQL query to offer the replacement value in a row under column name `MY_REPLACEMENT`. Plus, the replacement anchor allows for an internal syntax that enables the user to handle the most common replacement scenarios without any conditional logic.

As a standard, a replacement anchor in a template must be surrounded by `#`-signs. It may consist of up to four internal blocks, separated by a pipe `|`. The meaning of the internal blocks is as follows:

1. Name of the replacement anchor
2. Optional prefix put in front of the replacement value if the value exists
3. Optional postfix put after the replacement value if the value exists
4. Optional `NULL` replacement value if the replacement value is `NULL`

As an example, this is a simple replacement anchor: `#SAMPLE_REPLACEMENT#`. If you intend to surround the value with brackets and pass the information `NULL` if the value is `NULL`, you may write `#SAMPLE_REPLACEMENT|(|), |NULL#` to achieve this.

Should it be necessary, the replacement characters can be changed either on a case by case basis by calling setter methods or generally by adjusting initialization parameters, if `PIT` is installed. `UTL_TEXT` works best in conjunction with `PIT` but may be installed without it as well. In this case, the replacement characters are set within the initialization of the package as package constants.

## Code Generator

`UTL_TEXT` has two methods that form the code generator, each designed as a procedure and a function:

- `GENERATE_TEXT`, a method to incorporate column values of a select query into a template passed in as the first column
- `GENERATE_TEXT_TABLE`, as `GENERATE_TEXT` but it delivers a table of `CLOB` instead of a single `CLOB`

### GENERATE_TEXT

`GENERATE_TEXT` extends the possibilites of `BULK_REPLACE` by calling the method within the context of a cursor. This is only a small change, but it leads to surprising advantages.

#### Convention

To work properly, the cursor passed in to `UTL_TEXT.GENERATE_TEXT` assumes several conventions:

- It must contain a column named `TEMPLATE` that contains the replacement template.
- the names of the replacement anchors must match the column names of the other columns of the cursor. We strongly advise not to include umlauts or other specific character in the names but rather KISS. All column names will be converted to uppercase.
- If you want to log conversions, you need to provide a log template as a column named `LOG_TEMPLATE`. If this column is present, `UTL_TEXT` will emit a message using `PIT`, if available, containing the converted log template, or use `DBMS_OUTPUT.PUT_LINE`, if `PIT` is not present.

If a column of type `DATE` is detected, this value will be converted to `VARCHAR2` using a format mask derived from a parameter called `DEFAULT_DATE_FORMAT`. You may also choose to convert any `date` or `number` column upfront and deliver those values as `varchar2` to keep full control over the process.

#### Basic Usage

The following example shows how to call `GENERATE_TEXT` from within SQL. It's also possible to call it from within PL/SQL, either as a function or as a procedure. The return value is a `CLOB` instance:

```
SQL>   with templ as (
  2         select q'^#COLUMN_NAME# #COLUMN_TYPE##COLUMN_SIZE|(| char)|##COLUMN_PRECISION|(|)#^' template,
  3                ', ' || chr(10) delimiter
  4           from dual),
  5         vals as (
  6         select 'FIRST_COLUMN' column_name,
  7                'VARCHAR2' column_type,
  8                '25' column_size,
  9                null column_precision
 10           from dual
 11          union all
 12         select 'SECOND_COLUMN', 'NUMBER', null, '38,0' from dual union all
 13         select 'THIRD_COLUMN', 'INTEGER', null, null from dual)
 14  select utl_text.generate_text(cursor(
 15           select template, column_name, column_type, column_size, column_precision
 16             from templ
 17            cross join vals), delimiter) result
 18    from templ;

RESULT
--------------------------------------------------------------------------------
FIRST_COLUMN VARCHAR2(25 char),
SECOND_COLUMN NUMBER(38,0),
THIRD_COLUMN INTEGER

```

If you inspect the code a bit closer, you will immediately find how intuitive and easy it is to put together templates and the queries to pouplate them. In this example, the result does not require any conditional logic to distinguish between the different column types. It is also possible to provide different templates per column type to make it even more flexible. Lines 1 to 13 are used to provide the method with the templates and the data to insert, so this effort has to be taken anyway. If you remove these lines, only the call in lines 14 to 17 remains. It is possible to abbreviate the call to the method even further:

```
 14  select utl_text.generate_text(cursor(
 15           select *
 16             from templ
 17            cross join vals), delimiter) result
```

If you do not insist on the ANSI join, you can eliminate the `CROSS JOIN`, replacing it by a comma.

Column `DELIMITER` of subquery `TEMPL` contains a delimiter sign that is passed to the `GENERATE_METHOD` as a second parameter, leading to a separated output. As a third parameter, it's also possible to pass in an integer value that indents every row of the output by `N` blank signs.

#### Complex Usage

As a more complex example, you may want to nest calls of `GENERATE_TEXT`. This way, you can create a list of columns like in the above example and nest the result into a surrounding template. In the following example, we do just that:

```
SQL>   with templ as (
  2         select q'^CREATE TABLE #TABLE_NAME#(#CR##COLUMN_LIST#);^' table_template,
  3                q'^#COLUMN_NAME# #COLUMN_TYPE##COLUMN_SIZE|(| char)##COLUMN_PRECISION|(|)#^' col_template,
  5                chr(10) || '  ' cr
  6           from dual),
  7         vals as (
  8         select 'FIRST_COLUMN' column_name,
  9                'VARCHAR2' column_type,
 10                '25' column_size,
 11                null column_precision
 12           from dual
 13          union all
 14         select 'SECOND_COLUMN', 'NUMBER', null, '38,0' from dual union all
 15         select 'THIRD_COLUMN', 'INTEGER', null, null from dual)
 16  select utl_text.generate_text(cursor(
 17           select table_template template, cr,
 18                  'MY_TABLE' table_name,
 19                  utl_text.generate_text(cursor(
 20                    select col_template template, column_name, column_type, column_size, column_precision
 21                      from templ
 22                     cross join vals), cr, 2) column_list
 23             from templ)) result
 24    from dual;

RESULT
--------------------------------------------------------------------------------
CREATE TABLE MY_TABLE(
  FIRST_COLUMN VARCHAR2(25 char),
  SECOND_COLUMN NUMBER(38, 0),
  THIRD_COLUMN INTEGER);
```

If you work with more than one template, make sure to alias those templates with the column name `TEMPLATE` when calling the code generator. As an alternative to the approach shown above, where the templates are provided in separated columns, you may also want to provide them as rows, filtering them out in the respective cursor passed to `CODE_GENERATOR`.

Here you see the usage of parameter `p_indent` which is set to `2` in the example. This then means that any row, delimited by `p_delimiter` which in our case is `chr(10)`, is indented by 2 blanks at the beginning of each line. This is useful when putting together complex DML or DDL statements.

To make it easy to maintain different templates, `UTL_TEXT` ships with a table called `UTL_TEXT_TEMPLATES` you may use as a repository for your templates. Alternatively you can utilize any existing or newly created table for this purpose or provide the templates by any others means. 

It's not difficult to see what could happen if the replacement values and the templates are derived from tables. The logic to select the proper table per row is delegated to the join condition, the data controls how much and what information is generated. In the supplied table, three columns are provided to store templates. The first column, `UTTM_TYPE`, is used to group templates together. `UTTM_NAME` stores the name of the template. Additionally, it has proven to be very useful to store templates for a similar purpose but slightly differnt semantics under the same namen and separate them by `UTTM_MODE`. This column defaults to `DEFAULT` but you could use it to distinguish a template for `DATE` columns from a template for `NUMBER` columns Both generate output for a column, but with different syntax. Doing so, you can easily join the respective template to different column types based on meta data, falling back to a `DEFAULT` template if no specific template was present.

#### Log Conversion

Another nice feature of the code generator is its ability to log conversion processes. Problem here is that only the template may know what exactly was created. Imagine a set of meta data to create tables, indexes, views etc. They all share the same meta data such as core table_name, table_suffix, column list etc. but based on the template the create different data objects with a naming convention that is built into the template. So calling a template and passing the meta data will not tell you which object exactly was created, because only the template really knows.

Therefore, a second template, called `LOG_TEMPLATE` may be passed into `GENERATE_TEXT`. So if you provide the cursor with a column named `LOG_TEMPLATE`, it will try and find content within that column. The log template is expected to be a template with replacement anchors (if any) that creates the message that should be logged. If `UTL_TEXT` finds a template, it replaces the anchors with just the same information available for the main template and logs the message using `PIT.LOG` or `DBMS_OUTPUT`, if `PIT` is not present.

If no template is found, no logging takes place. This way you can easily control which templates log without any changes to the logic that creates the text blocks. You simply pass in the template (ideally located in a column of table `UTL_TEXT_TEMPLATES`) and off you go. As an example on how to use this, review this code:

```
declare
  l_result clob;
begin
  pit.set_context(70, 10, false,'PIT_CONSOLE');
  
  with templ as (
       select q'^CREATE TABLE #TABLE_NAME#(#CR##COLUMN_LIST#);^' table_template,
              q'^#COLUMN_NAME# #COLUMN_TYPE##COLUMN_SIZE|(| char)##COLUMN_PRECISION|(|)#^' col_template,
              q'^Table #TABLE_NAME# created^' log_template,
              ',' || chr(10) || '  ' delimiter,
              chr(10) || '  ' cr
         from dual),
       vals as (
       select 'FIRST_COLUMN' column_name,
              'VARCHAR2' column_type,
              '25' column_size,
              null column_precision
         from dual
        union all
       select 'SECOND_COLUMN', 'NUMBER', null, '38,0' from dual union all
       select 'THIRD_COLUMN', 'INTEGER', null, null from dual)
select utl_text.generate_text(cursor(
       select table_template, log_template, cr,
              'MY_TABLE' table_name,
              utl_text.generate_text(cursor(
                select col_template, column_name, column_type, column_size, column_precision
                  from templ
                 cross join vals), delimiter, 2) column_list
         from templ)) result
  into l_result
  from dual;
  
  pit.reset_context;
end;
/
```

This code will not only create the DDL statement seen earlier, but also log the the console `--> Table MY_TABLE created`. Off course, any output module of PIT set active will receive this log information.

### GENERATE_TEXT_TABLE

Most options are the same in comparison to `GENERATE_TABLE`, but no delimiter and indentation is required, as this function returns the result row by row instead of plumbing it together into one big CLOB.

Again, Im showing the function interface which in this case is a pipelined function. If you need a `CLOB_TABLE` directly, rather use the procedure overload:

```
SQL> select rownum, column_value result
  2    from table(
  3            with templ as (
  4                 select q'^#COLUMN_NAME# #COLUMN_TYPE##COLUMN_SIZE|(| char)##COLUMN_PRECISION|(|)#^' template
  5                   from dual),
  6                 vals as (
  7                 select 'FIRST_COLUMN' column_name,
  8                        'VARCHAR2' column_type,
  9                        '25' column_size,
 10                        null column_precision
 11                   from dual
 12                  union all
 13                 select 'SECOND_COLUMN', 'NUMBER', null, '38,0' from dual union all
 14                 select 'THIRD_COLUMN', 'INTEGER', null, null from dual)
 15          select utl_text.generate_text_table(cursor(
 16                   select template, column_name, column_type, column_size, column_precision
 17                     from templ
 18                    cross join vals)) result
 19            from templ);

ROWNUM RESULT
------ ----------------------------------
     1 FIRST_COLUMN VARCHAR2(25 char)
     2 SECOND_COLUMN NUMBER(38,0)
     3 THIRD_COLUMN INTEGER
```

## Parameterization

As stated already, `UTL_TEXT` assumes that `PIT` is installed. `UTL_TEXT` uses `PIT` for the following tasks:

- Parameters are maintained using `PIT`s built in parameter package
- Code errors are raised using `PIT.ERROR` methods
- Logging of `UTL_TEXT` conversions are done with `PIT`, so any output module may benefit from the logging

It is recommended to install `UTL_TEXT` into the same user that owns `PIT`, though this is not mandatory. If you decide to install `UTL_TEXT` into a new user or install it without `PIT`, you may want to control where the table `UTL_TEXT` creates is installed. Normal behaviour is to use the default tablespace of the (existing) user you install `UTL_TEXT` into. If the user exists but has not tablespace quota on any tablespace, the script will grant quota unlimited on the database default tablespace. If you want to control the tablespace yourself, change the name of the tablespace in file `UTL_TEXT/UTL_TEXT/init.sql`.

`UTL_TEXT` is parameterizable by setting initializiation parameters which are called upon initialization of the package. To reset the package to its initial status, simply call method `UTL_TEXT.INITIALIZE`.

Any parameter that is preset is changeable during operation using getter and setter methods. Calling them before a conversion takes place will set the conversion accordingly, initializing the package afterwards will reset it to its initial state. Here's a list of the parameters provided with `UTL_TEXT`:

- `IGNORE_MISSING_ANCHORS`, flag to indicate whether a anchor that has no matching replacement information throws an error instead of silently ignoring it. Initial value: `TRUE`, meaning that no errors are thrown (missing anchors are ignored)
- `DEFAULT_DATE_FORMAT`, sets the default conversion format for `DATE`-Columns. Initial value: `YYYY-MM-DD HH24:MI:SS`
- `MAIN_ANCHOR_CHAR`, character that is used to mark an anchor. Initial value: `#`
- `MAIN_SEPARATOR_CHAR`, character that is used to separate the four optional building blocks within an anchor. Initial value: `|`
- `SECONDARY_ANCHOR_CHAR`, character that is used to mark a nested anchor within another anchor. Initial value: `^`
- `SECONDARY_SEPARATOR_CHAR`, character that is used to separate the four optional building blocks within a nested anchor. Initial value: `~`

If `PIT` is not present, all parameters are replaced by package constants. Using the Getter/Setter is possible no matter whether `PIT` is present or not.

## Internationalization

As `UTL_TEXT` is based on `PIT`, all messages can be easily translated using `PIT`s built in translation mechanism. Simply export the default language and translate the XLIFF-file to the target language. Then re-import this file into `PIT` using `PIT_ADMIN.TRANSLATE_MESSAGES` and you're done.

## Installing without `PIT` being present
If you decide not to install `PIT` and still want to use `UTL_TEXT`, this is possible as well, but with somewhat limited functionality:

- All parameters are constants in the `UTL_TEXT` package specification
- Any logging will happen to the console using `dbms_output` only.
- Exceptions are thrown using `raise_application_error`
