create or replace package &INSTALL_USER..code_generator 
as

  
  /* Getter/Setter to adjust, whether a missing anchor raises an error or not
   * @param  p_flag  Boolean value to control, whether a missing anchor is ignored (TRUE) or not (FALSE)
   *                 Default: TRUE
   */
  function get_ignore_missing_anchors return boolean;
  procedure set_ignore_missing_anchors(p_flag in boolean);
  
  
  /* Getter/Setter to adjust the default date mask used for conversion of date columns
   * @param  p_mask  Format mask. 
   *                 Default: YYYY-MM-DD HH24:MI:SS
   */
  function get_default_date_format return varchar2;
  procedure set_default_date_format(p_mask in varchar2);
                               
  
  /* BULK_REPLACE-Method to directly replace anchors with replacement values.
   * @param  p_template  Template containing replacement anchors. 
   *                     Syntax of a replacement string:
   *                     #<Name of the anchor>
   *                     |<Prefix if replacement value is not null>
   *                     |<Postfix if replacement value is not null>
   *                     |<replacement value, if replacement value is null># 
   *                     All PIPE-signs are optional.
   *                     Example: 
   *                     <code>#DATA_PRECISION|(|)|#</code>
   *                     If DATA_PRECISION is 3, this will return (3), if it is NULL, this will return NULL.
   *                     If the eplacement shall contain a second replacement anchor, this 
   *                     anchor needs to be escaped with the secondary replacement sign.
   *                     Example: 
   *                     <code>#LAST_NAME||, |~CHR_NAME||, ~#</code>
   *                     is basically the same as to write
   *                     <code>case when last_name is not null then last_name || ', '
   *                     when first_name is not null then first_name || ', '
   *                     else null end; </code>
   * @param  p_chunks    List of anchor names and replacement text in alternating order
   * @param [p_indent]   Number of charcters to indent the result with
   *                     Default: 0
   * @return CLOB with all replacements
   * @usage  This overload is useful if the replacement anchors and strings are
   *         easily collected into a name-value ordered string
   */
  function bulk_replace(
    p_template in clob,
    p_chunks in clob_table,
    p_indent in number default 0)
    return clob;
                               

  /* BULK_REPLACE-Method to directly replace anchors with replacement values
   * Overlaod with P_CHUNKS as a KEY_VALUE_TAB
   * @param  p_template  Template containing replacement anchors. For details on 
   *                     the syntax of replacement anchors see documentation of
   *                     base BULK_REPLACE method
   * @param  p_chunks    List of anchor names and replacement as a list of key_value_type instances
   * @param [p_indent]   Number of charcters to indent the result with
   *                     Default: 0
   * @return CLOB with all replacements
   * @usage  This overload is useful if the replacement anchors and strings are
   *         accessible as rows in a select statement. They then can be collected
   *         as a KEY_VALUE_TAB using a
   *         <code>cast(multiset(key_value_type) as key_value_tab)</code> statement.
   */
  function bulk_replace(
    p_template in clob,
    p_chunks in key_value_tab,
    p_indent in number default 0)
    return clob;
                          

  /* Method to replace anchors in dynamically selected templates with column values of a select query
   * @param  p_cursor     Open cursor with one or many result rows
   *                      Convention:
   *                      <ul><li>Column name TEMPLATE: contains the template including the replacement anchors.<br/>
   *                        If no column TEMPLATE is existing, the first column of the query is deemed to contain the template</li>
   *                      <li>Column name LOG_TEMPLATE: contains a template that is used to log the replacement using PIT<br/>
   *                        If no column LOG_TEMPLATE is existing, the replacement will not be logged</li>
   *                      <li>All other column names are taken as replacement anchor names, their corresponding value
   *                        will be replaced within the template, based on the rules of BULK_REPLACE</li></ul>
   * @param  p_result     CLOB with all replacements
   * @param [p_delimiter] One or more characters that are used as delimiters between multiple replacements 
   *                      (i.e. when the cursor returns more than one row)
   * @param [p_indent]    Number of charcters to indent the result with
   *                      Default: 0
   * @usage  Is used to create a string based on one or more templates and replacements strings, passed in 
   *         as the result of a SQL query.
   *         Should the query return more than one row, all resulting string a concatenated, 
   *         delimited by P_DELIMITER.
   *         As you can't pass in a constant template, care must be taken that the template is
   *         contained as the first column (or as a column named TEMPLATE) of the query.
   *         If you need a constant template, you may pass it in as a constant, more frequently
   *         you will want to join it from a dedicated template table.
   *         If the cursor contains a column named LOG_TEMPLATE, this template will be replaced
   *         with all replacement values and the result will be logged using PIT. This is
   *         helpful if you want to log what has been replaced, as you normally don't know
   *         upfront, what a template will actually return. So you can use the same methodology
   *         to generate a speaking log message. 
   *         Example:
   *         Imagine a template that creates DDL for a table. As the replacement values dictate 
   *         the name of the resulting table, only then you are able to log which specific 
   *         table DDL has been created. Passing in a LOG_TEMPLATE takes care of this:
   *         Log-Template: <code>DDL for #OWNER#.#TABLE_NAME# created</code>
   *         As a best practice, you should provide the LOG_TEMPLATE in a table with a severity column.
   *         This way you can select or omit the log_template within the query based on the
   *         log settings. If the LOG_TEMPLATE is missing for a given row, no logs are created.
   */
  procedure generate_text(
    p_cursor in sys_refcursor,
    p_result out nocopy clob,
    p_delimiter in varchar2 default null,
    p_indent in number default 0);
                          
  /* Overload as a function. */
  function generate_text(
    p_cursor in sys_refcursor,
    p_delimiter in varchar2 default null,
    p_indent in number default 0) 
    return clob;
    
                         
  /* Extended overlaod of GENERATE TEXT with the following differences:
   * If the query contains more than one row, the resulting text will not be concatenated
   * but collected as rows of a CLOB_TABLE. It therefore does not include a delimiter
   * Indenting is applied nevertheless. This overload is helpful in certain circumstances
   * where you want to avoid complex nested cursor expressions but rather build a complex
   * string one step after another.
   * Normally, GENERATE_TEXT should be preferred.
   */
  procedure generate_text_table(
    p_cursor in sys_refcursor,
    p_result out nocopy clob_table,
    p_indent in number default 0);

  /* Overload as a function. */
  function generate_text_table(
    p_cursor in sys_refcursor,
    p_indent in number default 0) 
    return clob_table;

end code_generator;
/