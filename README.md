# CodeGenerator

Helper Package to support generating template based texts.

## What it is

CodeGenerator is a helper package to support creating text based on templates with replacement anchors. This kind of replacement is often required when generating dynamic SQL or PL/SQL-code or when putting together mail messages and the like.

To reduce the amount of constants used in the code and to remove the burdon of writing the same kind of code over and over again, CodeGenerator helps in putting together the results easily.

Main idea is that a SQL query is provided that offers the replacement values under the column name of the replacement anchor. Therefore, it there is a replacement anchor `#MY_REPLACEMENT#` this requires the SQL query to offer the replacement value in a row under column name `MY_REPLACEMENT`. Plus, the replacement anchor allows for an internal syntax that enables the user to handle the most common replacement scenarios without any conditional logic.

As a standard, a replacement anchor in a template must be surrounded by `#`-signs. It may consist of up to four internal blocks, separated by a pipe `|`. The meaning of the internal blocks is as follows:

1. Name of the replacement anchor
2. Optional prefix put in front of the replacement value if the value exists
3. Optional postfix put after the replacement value if the value exists
4. Optional `NULL` replacement value if the replacement value is `NULL`

As an example, this is a simple replacement anchor: `#SAMPLE_REPLACEMENT#`. If you intend to surround the value with brackets and pass the information `NULL` if the value is `NULL`, you may write `#SAMPLE_REPLACEMENT|(|), |NULL#` to achieve this.

Should it be necessary, the replacement characters can be changed either on a case by case basis by calling setter methods or generally by adjusting initialization parameters. 
CodeGenerator will utilize PIT for messaging, if it is installed. If this is the case ...
- CodeGenerator raises meaningful and translatable messages on errors
- Loggig is possible to any PIT output module, including tables, trace files, console and so on
- Initial value of setter methods are controlled by parameters

If PIT is not present...
- if falls back to a more basic version raising simple errors 
- logging is made to the console only and
- Initial status of setter methods are not maintained by parameters but hard coded into the package

## Functionality

CodeGenerator has three methods, each designed as a procedure and a function:

- `BULK_REPLACE`, a convenient method to replace many occurences of a text in one go
- `GENERATE_TEXT`, a method to incorporate column values of a select query into a template passed in as the first column
- `GENERATE_TEXT_TABLE`, as `GENERATE_TEXT` but it delivers a table of `CLOB` instead of a single `CLOB`

### BULK_REPLACE

This method is the most basic one but it allows for the same flexibility in replacing anchors with values, so this is a good start to explain the different possibilities.

#### Basic Usage

As a first example, consider this code snippet:

```
SQL> select code_generator.bulk_replace('My first #1#', char_table('1', 'replacement')) result
  2    from dual;

RESULT
---------------------
My first replacement
```

In this example, `#1#` is replaced with `replacement`, which could have been achieved with a simple replace method as well. But you're free to put whatever amount of replacement anchors into the text, as `char_table` is a nested table of type `varchar2(4000)`. You may reference the anchors by any valid Oracle name or by number, as in the example above.


#### Recursion

The real power comes from CodeGenerators recursive abilities. As a simple example, the replacement contains a second anchor:

```
SQL> select code_generator.bulk_replace('A simple #1#', char_table(
  2           '1', 'replacement with #2#',
  3           '2', 'recursive replacements')) result
  4    from dual;

RESULT
-------------------------------------------------
A simple replacement with recursive replacements
```

This example also shows how to include more than one replacement key-value-pair.

#### `NULL` value treatment

To make things a bit more funny, you may extend the anchors syntax to support `NULL`-value treatment. In the following example, we want to inlude a `PRE` and `POST` before and after a non `NULL`-value and a `NULL` for any `NULL` value:

```
SQL> select code_generator.bulk_replace(
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
SQL> select code_generator.bulk_replace(
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

All these options are available not only with `BULK_REPLACE`, but with `GENERATE_TEXT` and `GENEREATE_TEXT_TABLE` as well, as all of them reuse the same `BULK_REPLACE`engine underneath.

### GENERATE_TEXT

`GENERATE_TEXT` extends the possibilites of `BULK_REPLACE` by calling the method within the context of a cursor. 

#### Convention

To work properly, CodeGenerator assumes several conventions:

- the first column of the cursor passed into the method has to contain the template with the replacement anchors. Ideally, it's named `TEMPLATE` but that's not necessary.
- the names of the replacement anchors must match the column names of the second to last column. We strongly advise not to include umlauts or other specific character in the names but rather keep it simple stupid. All column names will be converted to uppercase.
- If you want to log conversions, you need to provide a log template as a column named `LOG_TEMPLATE`

If a column of type `DATE` is detected, this value will be converted to `VARCHAR2` by a calling a format mask stored at a parameter called `DEFAULT_DATE_FORMAT`. You may also choose to convert any date or number column upfront and deliver those values as varchar2 to keep full control over the process.

#### Basic Usage

The following example shows how to call `GENERATE_TEXT` from within SQL. It's also possible to call it from within PL/SQL, either as a function or as a procedure. The return value is a `CLOB`:

```
SQL>   with templ as (
  2         select q'^#COLUMN_NAME# #COLUMN_TYPE##COLUMN_SIZE|(| char)|##COLUMN_PRECISION|(|){#^' template,
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
 14  select code_generator.generate_text(cursor(
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

If you inspect the code a bit closer, you will immediately find how intuitive and easy it is to put together templates and the queries to pouplate them. In this example, the result does not require any conditional logic to distinguish between the different column types. It is also possible to provide different templates per column type to make it even more flexible.

Column `DELIMITER` of subquery `TEMPL` contains a delimiter sign that is passed to the `GENERATE_METHOD` as a second parameter, leading to a separated output. As a third parameter, it's also possible to pass in an integer value that indents every row of the output by `N` blank signs.

#### Complex Usage

As a more complex example, you may want to nest calls of `GENERATE_TEXT`. This way, you can create a list of columns like in the above example and nest the result into a surrounding template. In the following example, we do just that:

```
SQL>   with templ as (
  2         select q'^CREATE TABLE #TABLE_NAME#(#CR##COLUMN_LIST#);^' table_template,
  3                q'^#COLUMN_NAME# #COLUMN_TYPE##COLUMN_SIZE|(| char)##COLUMN_PRECISION|(|)#^' col_template,
  4                ',' || chr(10) || '  ' delimiter,
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
 16  select code_generator.generate_text(cursor(
 17         select table_template, cr,
 18                'MY_TABLE' table_name,
 19                code_generator.generate_text(cursor(
 20                  select col_template, column_name, column_type, column_size, column_precision
 21                    from templ
 22                   cross join vals), delimiter, 2) column_list
 23           from templ)) result
 24    from dual;

RESULT
--------------------------------------------------------------------------------
CREATE TABLE MY_TABLE(
  FIRST_COLUMN VARCHAR2(25 char),
  SECOND_COLUMN NUMBER(38, 0),
  THIRD_COLUMN INTEGER);
```

To make it easy to maintain different templates, CodeGenerator ships with a table called `CODE_GENERATOR_TEMPLATES` you may use as a repository for your templates. You may use any existing or newly created table for this purpose as well or provide the template by any others means. 

It's not difficult to see what could happen if the replacement values and the templates are derived from tables. The logic to select the proper table per row is delegated to the join condition, the data controls how much and what information is generated. In the supplied table, three columns are provided to store templates. The first column, `CGTM_NAME` contains the name of the template. You can group together templates using column `CGTM_TYPE`. Additionally, it has proven to be very useful to be able to store different template versions by `CGTM_MODE`. This column defaults to `DEFAULT` but we used it to distinguish different column type templates fi. In this case, we stored the template to cater for `DATE` columns as name `COLUMN_TEMPLATE`, type `DDL` with mode `DATE`. Doing this, we could easily join the respective template to different column types, falling back to a `DEFAULT` template if no specific template was present.

#### Log Conversion

Another nice feature we built into CodeGenerator is its ability to log conversion processes. Problem here is that only the template may know what exactly was created. Imagine a set of meta data to create tables, indexes, views etc. They all share the same meta data such as core table_name, table_suffix, column list etc. but based on the template the create different data objects with a naming convention that is built into the template. So calling a template and passing the meta data will not tell you which object exactly was created, because only the template really knows.

Therefore, a second template, called `LOG_TEMPLATE` may be passed into `GENERATE_TEXT`. The way it is passed into the method is by means of a column name convention. So if you provide the method with a column named `LOG_TEMPLATE`, it will try and find content wihtin that column. The log template is expected to be a template with replacement anchors (if any) that create the message that should be logged. If CodeGenerator finds a template, it replaces the anchors with just the same information available for the main template and logs the message using `PIT.LOG`.

If no template is found, no logging takes place. This way you can easily control which templates log without any intervention into the logic to create the text blocks. You simply pass in the template (ideally located in a column of table CODE_GENERATOR_TEMPLATES) and off you go.

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
 15          select code_generator.generate_text_table(cursor(
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

As stated already, CodeGenerator assumes that PIT is installed. CodeGenerator uses PIT for the following tasks:

- Parameters are maintained using PITs built in parameter package
- Code errors are raised using `PIT.ERROR` methods
- Logging of CodeGenerator conversions are done with PIT, so any output module may benefit from the logging

CodeGenerator is parameterizable by setting initializiation parameters which are called upon initialization of the package. To reset the package to its initial status, simply call method `CODE_GENERATOR.INITIALIZE`.

Any parameter that is preset is changeable during operation using getter and setter methods. Calling them before a conversion takes place will set the conversion accordingly, initializing the package afterwards will reset it to its initial state. Here's a list of the parameters provided with CodeGenerator:

- `IGNORE_MISSING_ANCHORS`, flag to indicate whether a anchor that has no matching replacement information throws an error instead of silently ignoring it. Initial value: `TRUE`, meaning that no errors are thrown (missing anchors are ignored)
- `DEFAULT_DATE_FORMAT`, sets the default conversion format for `DATE`-Columns. Initial value: `YYYY-MM-DD HH24:MI:SS`
- `MAIN_ANCHOR_CHAR`, character that is used to mark an anchor. Initial value: `#`
- `MAIN_SEPARATOR_CHAR`, character that is used to separate the four optional building blocks within an anchor. Initial value: `|`
- `SECONDARY_ANCHOR_CHAR`, character that is used to mark a nested anchor within another anchor. Initial value: `^`
- `SECONDARY_SEPARATOR_CHAR`, character that is used to separate the four optional building blocks within a nested anchor. Initial value: `~`


## Internationalization

As CodeGenerator is based on PIT, all messages can be easily translated using PITs built in translation mechanism. Simply export the default language and translate the XLIFF-file to the target language. Then re-import this file into PIT using `PIT_ADMIN.TRANSLATE_MESSAGES` and you're done.
