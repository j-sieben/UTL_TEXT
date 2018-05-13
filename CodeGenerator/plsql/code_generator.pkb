create or replace package body &INSTALL_USER..code_generator
as

  /* CONSTANTS */
  c_row_template constant varchar2(30) := 'TEMPLATE';
  c_log_template constant varchar2(30) := 'LOG_TEMPLATE';
  c_date_type constant binary_integer := 12;
  c_default_date_format constant varchar2(30 byte) := 'yyyy-mm-dd hh24:mi:ss';
  c_param_group constant varchar2(30 byte) := 'CODE_GEN';

  /* PACKAGE VARS */
  g_ignore_missing_anchors boolean;
  g_default_date_format varchar2(200);
  g_main_anchor_char char(1 char);
  g_secondary_anchor_char char(1 char);
  g_main_separator_char char(1 char);
  g_secondary_separator_char char(1 char);

  /* DATA TYPES */
  -- not to be confused with SQL CLOB_TABLE datatype
  type clob_tab is table of clob index by varchar2(30 byte);
  type row_tab is table of clob_tab index by binary_integer;

  -- record with variables for query values
  type result_rec is record(
    date_value date,
    clob_value clob);


  /* HELPERS METHODS */
  /* Method to describe a cursor
   * %param  p_cursor    Opened cursor passed in when calling GENERATE_TEXT
   * %param  p_cur       DBMS_SQL-ID of the cursor
   * %param  p_cur_desc  DBMS_SQL.DESC_TAB2 containing the cursor description
   * %param  p_clob_tab  PL/SQL table indexed by the column name (KEY) and
   *                     NULL as the payload
   * %usage  Is used to create a table indexed by column name and a variable
   *         to accept the column value upon later replacement.
   */
  procedure describe_cursor(
    p_cursor in sys_refcursor,
    p_cur in out nocopy integer,
    p_cur_desc in out nocopy dbms_sql.desc_tab2)
  as
    l_cursor sys_refcursor := p_cursor;
    l_column_count integer;
    l_result_rec result_rec;
    l_has_template_column boolean := false;
  begin
    p_cur := dbms_sql.to_cursor_number(l_cursor);

    dbms_sql.describe_columns2(
      c => p_cur,
      col_cnt => l_column_count,
      desc_t => p_cur_desc);

    for i in 1 .. l_column_count loop
      -- check whether cursor has a column named C_ROW_TEMPLATE, use this as
      -- the template column
      if p_cur_desc(i).col_name = c_row_template then
        l_has_template_column := true;
      end if;

      -- register out variable
      if p_cur_desc(i).col_type = c_date_type then
        dbms_sql.define_column(p_cur, i, l_result_rec.date_value);
      else
        dbms_sql.define_column(p_cur, i, l_result_rec.clob_value);
      end if;
    end loop;

    if not l_has_template_column then
      -- No dedicated template column in cursor, fallback to first column
      p_cur_desc(1).col_name := c_row_template;
    end if;
  end describe_cursor;


  /* Method to copy actual row values of the cursor into local variables
   * %param  p_cur       DMS_SQL cursor ID
   * %param  p_cur_desc  DBMS_SQL.DESC_TAB2 containing the cursor description
   * %param  p_row_tab   List of CLOB_TAB instances indexed by binary integer.
   *                     Each entry contains a list of column values indexed by
   *                     column name for each row of the result set
   * %usage  Is used to copy all rows of the query into a table of replacement
   *         key value pairs
   */
  procedure copy_values(
    p_cur in integer,
    p_cur_desc in dbms_sql.desc_tab2,
    p_row_tab in out nocopy row_tab)
  as
    l_clob_tab clob_tab;
    l_result_rec result_rec;
  begin
    while dbms_sql.fetch_rows(p_cur) > 0 loop
      for i in p_cur_desc.first .. p_cur_desc.last loop
        -- copy column values
        if p_cur_desc(i).col_type = c_date_type then
          -- get date value
          dbms_sql.column_value(p_cur, i, l_result_rec.date_value);
          -- cast to char and store it in P_CLOB_TAB
          l_clob_tab(p_cur_desc(i).col_name) := to_char(l_result_rec.date_value, g_default_date_format);
        else
          -- store value directly in P_CLOB_TAB
          dbms_sql.column_value(p_cur, i, l_clob_tab(p_cur_desc(i).col_name));
        end if;
      end loop;

      p_row_tab(dbms_sql.last_row_count) := l_clob_tab;
    end loop;
  end copy_values;


  /* Method to copy a query into a list of type P_ROW_TAB that contains an instance
   * of CLOB_TAB per resulting row. Each CLOB_TAB instance contains a list of
   * column values casted to varchar2 indexed by column name.
   * %param  p_cursor   Opened cursor passed in when calling GENERATE_TEXT
   * %param  p_row_tab  List of CLOB_TAB instances indexed by binary integer.
   *                    Each entry contains a list of column values indexed by
   *                    column name for each row of the result set
   * %usage  Is used to copy all values of a query into a set of CLOB_TAB instances
   *         that is used to replace the respective entries
   */
  procedure copy_table_to_row_tab(
    p_cursor in sys_refcursor,
    p_row_tab in out nocopy row_tab)
  as
    l_cur integer;
    l_cur_desc dbms_sql.desc_tab2;
  begin
    describe_cursor(
      p_cursor => p_cursor,
      p_cur => l_cur,
      p_cur_desc => l_cur_desc);

    copy_values(
      p_cur => l_cur,
      p_cur_desc => l_cur_desc,
      p_row_tab => p_row_tab);

    dbms_sql.close_cursor(l_cur);
  end copy_table_to_row_tab;


  /* Central BULK_REPLACE method that is called by all public methods
   * %param  p_template  Template that is used to replace the values at
   * %param  p_clob_tab  List of KEY VALUE pairs holding the anchor name and the replacement string
   * %param  p_result    Result of the replacement operation
   * %param  p_indent    Amount of chars the result is indented with
   * %usage  Is called to recursively replace all anchors with their provided replacement values.
   *         Logic is incorporated to <ul>
   *         <li>Handle NULL values</li>
   *         <li>enclose NOT NULL values with optional PRE and POSTFIX</li>
   *         <li>Unmask anchors which are replaced as replacement values</li>
   *         <li>Recursively replace all anchors</li></ul>
   */
  procedure bulk_replace(
    p_template in clob default null,
    p_clob_tab in clob_tab,
    p_indent in number,
    p_result out nocopy clob)
  as
    c_anchor_regex constant varchar2(20) := g_main_anchor_char || '[A-Z].*?' || g_main_anchor_char;
    c_name_regex constant varchar2(20) := '[^' || g_main_anchor_char || g_main_separator_char || ']+';
    c_parts_regex constant varchar2(20) := '(.*?)(\' || g_main_separator_char || '|$)';

    -- cursor to extract all replacement anchors from a template and separate
    -- Pre/Postfixes and NULL replacement values
    cursor replacement_cur(p_template in varchar2) is
        with anchors as (
                select trim(g_main_anchor_char from regexp_substr(p_template, c_anchor_regex, 1, level)) replacement_string
                  from dual
               connect by level <= regexp_count(p_template, g_main_anchor_char) / 2)
      select g_main_anchor_char || replacement_string || g_main_anchor_char as replacement_string,
             upper(regexp_substr(replacement_string, c_name_regex, 1, 1)) anchor,
             regexp_substr(replacement_string, c_parts_regex, 1, 2, null, 1) prefix,
             regexp_substr(replacement_string, c_parts_regex, 1, 3, null, 1) postfix,
             regexp_substr(replacement_string, c_parts_regex, 1, 4, null, 1) null_value
        from anchors;

    l_anchor_value clob;
    l_missing_anchors clob;
  begin
    pit.assert_not_null(
      p_condition => p_template,
      p_message_name => msg.CODE_GEN_NO_TEMPLATE);

    -- Copy tempalte to result. Used to allow for recursive calls
    p_result := p_template;

    -- replace anchors with replacement string. These may contain anchors again
    for rep in replacement_cur(p_template) loop
      if p_clob_tab.exists(rep.anchor) then
        l_anchor_value := p_clob_tab(rep.anchor);
        if l_anchor_value is not null then
          p_result := replace(p_result, rep.replacement_string, rep.prefix || l_anchor_value || rep.postfix);
        else
          p_result := replace(p_result, rep.replacement_string, rep.null_value);
        end if;
      else
        -- Ersetzungszeichenfolge ist in Ersetzungsliste nicht enthalten
        l_missing_anchors := l_missing_anchors || '|' || rep.anchor;
      end if;
    end loop;

    if l_missing_anchors is not null and not g_ignore_missing_anchors then
      l_missing_anchors := ltrim(l_missing_anchors, '|');
      pit.error(msg.CODE_GEN_MISSING_ANCHORS, msg_args(l_missing_anchors));
    end if;

    -- recursive call if the method has replaced anything. As the replacements may
    -- contain anchors, this is necessary. If so, replace secondary anchor chars
    -- with primary anchor chars to make them visible to BULK_REPLACE
    if p_template != p_result then
      bulk_replace(
        p_template => replace(
                        replace(p_result, 
                          g_secondary_anchor_char, g_main_anchor_char), 
                          g_secondary_separator_char, g_main_separator_char),
        p_clob_tab => p_clob_tab,
        p_result => p_result,
        p_indent => p_indent);
    else
      -- Replacement is complete, now indent any row by P_INDENT if requested
      if p_indent > 0 then
        p_result := replace(p_result, chr(10), chr(10) || rpad(' ', p_indent, ' '));
      end if;
    end if;
  end bulk_replace;


  /* Oveload to allow BULK_REPLACE to work with a list of rows. Each row is
   * computed and stored in a CLOB_TAB entry within P_RESULT.
   */
  -- %param  p_result  Ausgabeparameter vom Typ CLOB_TABLE
  procedure bulk_replace(
    p_row_tab in row_tab,
    p_indent in number,
    p_result out nocopy clob_table)
  as
    l_result clob;
    l_template clob;
    l_log_message clob;
    l_clob_tab clob_tab;
  begin
    -- Initialize
    p_result := clob_table();

    if p_row_tab.count > 0 then
      for i in p_row_tab.first .. p_row_tab.last loop
        l_clob_tab := p_row_tab(i);
        l_template := l_clob_tab(c_row_template);

        bulk_replace(
          p_template => l_template,
          p_clob_tab => l_clob_tab,
          p_result => l_result,
          p_indent => p_indent);

        if l_clob_tab.exists(c_log_template) then
          if l_clob_tab(c_log_template) is not null then
            bulk_replace(p_template => l_clob_tab(c_log_template)
                        ,p_clob_tab => l_clob_tab
                        ,p_result => l_log_message
                        ,p_indent => null);

            pit.info(msg.CODE_GEN_LOG_MESSAGE, msg_args(l_log_message));
          end if;
        end if;

        p_result.extend;
        p_result(p_result.count) := l_result;
      end loop;
    end if;
  end bulk_replace;


  /* Initialisierungsprozedur des Packages */
  procedure initialize as
  begin
    g_ignore_missing_anchors := true;
    g_default_date_format := c_default_date_format;
    g_main_anchor_char := param.get_string('MAIN_ANCHOR_CHAR', c_param_group);
    g_main_separator_char := param.get_string('MAIN_SEPARATOR_CHAR', c_param_group);
    g_secondary_anchor_char := param.get_string('SECONDARY_ANCHOR_CHAR', c_param_group);
    g_secondary_separator_char := param.get_string('SECONDARY_SEPARATOR_CHAR', c_param_group);
  end initialize;


  /* INTERFACE*/
  /* GETTER/SETTER */
  procedure set_ignore_missing_anchors(p_flag in boolean) as
  begin
    g_ignore_missing_anchors := p_flag;
  end set_ignore_missing_anchors;

  function get_ignore_missing_anchors return boolean as
  begin
    return g_ignore_missing_anchors;
  end get_ignore_missing_anchors;

  procedure set_default_date_format(p_mask in varchar2) as
  begin
    g_default_date_format := p_mask;
  end set_default_date_format;

  function get_default_date_format return varchar2 as
  begin
    return g_default_date_format;
  end get_default_date_format;


  /* BULK_REPLACE */
  function bulk_replace(
    p_template in clob,
    p_chunks in clob_table,
    p_indent in number default 0)
    return clob
  as
    l_clob_tab clob_tab;
    l_result clob;
  begin
    if p_chunks is not null then
      -- Copy chunks to CLOB_TABLE
      for i in p_chunks.first .. p_chunks.last loop
        if mod(i, 2) = 1 then
          l_clob_tab(replace(p_chunks(i), g_main_anchor_char)) := p_chunks(i + 1);
        end if;
      end loop;

      bulk_replace(
        p_template => p_template,
        p_clob_tab => l_clob_tab,
        p_result => l_result,
        p_indent => p_indent);
    end if;
    return l_result;
  end bulk_replace;


  function bulk_replace(
    p_template in clob,
    p_chunks in key_value_tab,
    p_indent in number default 0)
    return clob
  as
    l_clob_tab clob_tab;
    l_result clob;
  begin
    if p_chunks is not null then
      -- Copy chunks to CLOB_TAB instance
      for i in p_chunks.first .. p_chunks.last loop
        l_clob_tab(replace(p_chunks(i).key, g_main_anchor_char)) := p_chunks(i).value;
      end loop;

      bulk_replace(
        p_template => p_template,
        p_clob_tab => l_clob_tab,
        p_result => l_result,
        p_indent => p_indent);
    end if;
    return l_result;
  end bulk_replace;


  /* GENERATE_TEXT */
  procedure generate_text(
    p_cursor in sys_refcursor,
    p_result out nocopy clob,
    p_delimiter in varchar2 default null,
    p_indent in number default 0)
  as
    l_row_tab row_tab;
    l_result clob_table;
  begin
    dbms_lob.createtemporary(p_result, false, dbms_lob.call);

    copy_table_to_row_tab(
      p_cursor => p_cursor,
      p_row_tab => l_row_tab);

    bulk_replace(
      p_row_tab => l_row_tab,
      p_indent => p_indent,
      p_result => l_result);

    -- Concatenate CLOB_TAB to CLOB
    for i in l_result.first .. l_result.last loop
      dbms_lob.append(p_result, l_result(i) || case when i < l_result.last then p_delimiter end);
    end loop;
  end generate_text;


  -- Ueberladung als Funktion
  function generate_text(
    p_cursor in sys_refcursor,
    p_delimiter in varchar2 default null,
    p_indent in number default 0)
    return clob
  as
    l_clob clob;
  begin
    generate_text(
      p_cursor => p_cursor,
      p_result => l_clob,
      p_delimiter => p_delimiter,
      p_indent => p_indent);
    return l_clob;
  end generate_text;


  /* GENERATE_TEXT_TABLE */
  procedure generate_text_table(
    p_cursor in sys_refcursor,
    p_result out nocopy clob_table,
    p_indent in number default 0)
  as
    l_row_tab row_tab;
  begin
    copy_table_to_row_tab(
      p_cursor => p_cursor,
      p_row_tab => l_row_tab);

    bulk_replace(
      p_row_tab => l_row_tab,
      p_indent => p_indent,
      p_result => p_result);
  end generate_text_table;


  -- Ueberladung als Funktion
  function generate_text_table(
    p_cursor in sys_refcursor,
    p_indent in number default 0)
    return clob_table
  as
    l_clob_table clob_table;
  begin
    generate_text_table(
        p_cursor => p_cursor,
        p_result => l_clob_table,
        p_indent => p_indent);
    return l_clob_table;
  end generate_text_table;

begin
  initialize;
end code_generator;
/
