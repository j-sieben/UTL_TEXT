# CodeGenerator

Helper Package to support generating template based texts.

## What it is

CodeGenerator is a helper package to support creating text based on templates with replacement anchors. This kind of replacement is often required when generating dynamic SQL or PL/SQL-code or when putting together mail messages and the like.

To reduce the amount of constants used in the code and to remove the burdon of writing the same kind of code over and over again, CodeGenerator helps in putting together the results easily.

Main idea is that a SQL query is provided that offers the replacement values under the column name of the replacement anchor. Therefore, it there is a replacement anchor #MY_REPLACEMENT# this requires the SQL query to offer the replacement value in a row under column name MY_REPLACEMENT. Plus, the replacement anchor allows for an internal syntax that enables the user to handle the most common replacement scenarios without any conditional logic.

As of now, a replacement anchor in a template must be surrounded by #-signs. It may consist of up to four internal blocks, separated by a pipe »|«. The meaning of the internal blocks is as follows:

1. Name of the replacement anchor
2. Optional prefix put in front of the replacement value if the value exists
3. Optional postfix put after the replacement value if the value exists
4. Optional NULL replacement value if the replacement value is NULL

As an example, this is a simple replacement anchor: `#SAMPLE_REPLACEMENT#`. If you intend to surround the value with brackets and pass the information NULL if the value is NULL, you may write `#SAMPLE_REPLACEMENT|(|), |NULL#` to achieve this.

## Functionality

CodeGenerator offers an API to convert a table row into a PL/SQL table indexed by varchar2. It uses the column name as the key and the converted column value (as char) as the value of the entry. It also offers a range of overloaded procedures to work with literal SQL statements or SYS_REFCURSOR. It also allows converting a template one time or multiple times if the statement returns more than one row.

Replacing text anchors within a template is a two step process. You first prepare a statement by converting it to a PL/SQL table that holds the name of the columns and the replacement values. You then apply that PL/SQL table to your template. Should you want to convert many rows of a query at once, you prepare a list of PL/SQL tables (one for each row of the result) and process this list against your template.
