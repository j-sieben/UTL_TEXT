<<<<<<< HEAD
create or replace package body &INSTALL_USER..code_generator
as

  /* CONSTANTS */
  c_row_template constant varchar2(30) := 'TEMPLATE';
  c_log_template constant varchar2(30) := 'LOG_TEMPLATE';
  c_date_type constant binary_integer := 12;
  c_default_date_format constant varchar2(30 byte) := 'yyyy-mm-dd hh24:mi:ss';
  c_param_group constant varchar2(30 byte) := 'CODE_GEN';

  /* PACKAGE VARS */
=======
create or replace package body code_generator as

  c_row_template           constant varchar2(30) := '$$ROW_TEMPLATE';
  c_date_type              constant binary_integer := 12;
  c_anchor_delimiter       constant char(1 byte) := '|';
>>>>>>> 3366522f4f398efd6ca6128b70a2eb24eb219aca
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
<<<<<<< HEAD
    p_cur := dbms_sql.to_cursor_number(l_cursor);

=======
>>>>>>> 3366522f4f398efd6ca6128b70a2eb24eb219aca
    dbms_sql.describe_columns2(
      c => p_cur,
      col_cnt => l_column_count,
      desc_t => p_cur_desc);
<<<<<<< HEAD

=======
                              
>>>>>>> 3366522f4f398efd6ca6128b70a2eb24eb219aca
    for i in 1 .. l_column_count loop
      -- check whether cursor has a column named C_ROW_TEMPLATE, use this as
      -- the template column
      if p_cur_desc(i).col_name = c_row_template then
        l_has_template_column := true;
      end if;
<<<<<<< HEAD

      -- register out variable
      if p_cur_desc(i).col_type = c_date_type then
        dbms_sql.define_column(p_cur, i, l_result_rec.date_value);
      else
        dbms_sql.define_column(p_cur, i, l_result_rec.clob_value);
=======
      
      l_column_type := p_cur_desc(i).col_type;
      
      -- Spalte als leeren Wert in der PL/SQL-Tabelle anlegen, um ihn als Variable
      -- referenzieren zu koennen
      l_cnt := l_cnt + 1;
      p_key_value_tab(l_column_name) := null;
      
      -- Registriere Variable als Ausgabevariable dieser Spalte
      if l_column_type = c_date_type then
        dbms_sql.define_column(
          c => p_cur,
          position => l_cnt,
          column => l_ref_rec.r_date);
      else
        dbms_sql.define_column(
          c => p_cur,
          position => l_cnt,
          column => l_ref_rec.r_clob);
>>>>>>> 3366522f4f398efd6ca6128b70a2eb24eb219aca
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
<<<<<<< HEAD
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
=======
      copy_values(
        p_cur => p_cur,
        p_cur_desc => p_cur_desc,
        p_key_value_tab => p_key_value_tab,
        p_first_column_is_template => p_first_column_is_template);
    
      p_row_tab(dbms_sql.last_row_count) := p_key_value_tab;
>>>>>>> 3366522f4f398efd6ca6128b70a2eb24eb219aca
    end loop;
  end copy_values;


<<<<<<< HEAD
  /* Method to copy a query into a list of type P_ROW_TAB that contains an instance
   * of CLOB_TAB per resulting row. Each CLOB_TAB instance contains a list of
   * column values casted to varchar2 indexed by column name.
   * %param  p_cursor   Opened cursor passed in when calling GENERATE_TEXT
   * %param  p_row_tab  List of CLOB_TAB instances indexed by binary integer.
   *                    Each entry contains a list of column values indexed by
   *                    column name for each row of the result set
   * %usage  Is used to copy all values of a query into a set of CLOB_TAB instances
   *         that is used to replace the respective entries
=======
  function clob_replace(
    p_in_source  in clob,
    p_in_search  in varchar2,
    p_in_replace in clob) 
    return clob 
  as
    l_pos pls_integer;
  begin
    l_pos := instr(p_in_source, p_in_search);
  
    if l_pos > 0 then
      return substr(p_in_source, 1, l_pos - 1) || p_in_replace || substr(p_in_source, l_pos + length(p_in_search));
    end if;
  
    return p_in_source;
  end clob_replace;
  
  
  /* Prozedur zum Kopieren einer einzelnen Zeile der SQL-Anweisung in eine PL/SQL-Tabelle
   * %param  p_stmt           SQL-Anweisung, die fuer jeden Ersetzungsanker eine Spalte generiert.
   *                          Limitiert auf eine Zeile
   * %param  p_key_value_tab  PL/SQL-Tabelle, die als KEY-VALUE-Tabelle die Ergebnisse
   *                          von P_STMT als <Spaltenname> : <Spaltenwert> liefert.
   * %usage Wird verwendet, um eine SQL-Anweisung in eine PL/SQL-Tabelle mit benannten
   *        Schluesselwerten zu migrieren
   */
  procedure copy_row_to_key_value_tab(
    p_stmt          in clob,
    p_key_value_tab in out nocopy key_value_tab) 
  as
    l_cur integer;
    l_cur_desc dbms_sql.desc_tab2;
  begin
    describe_cursor(
      p_stmt => p_stmt,
      p_cur => l_cur,
      p_cur_desc => l_cur_desc,
      p_key_value_tab => p_key_value_tab);
  
    if dbms_sql.fetch_rows(l_cur) > 0 then
      copy_values(
        p_cur => l_cur,
        p_cur_desc => l_cur_desc
        p_key_value_tab => p_key_value_tab);
    end if;
  
    dbms_sql.close_cursor(l_cur);
  end copy_row_to_key_value_tab;


  /* Ueberladung fuer Cursor mit einer Ergebniszeile 
  * %param p_cursor Geoffneter Cursor
  * %param p_key_value_tab PL/SQL-Tabelle, die als KEY-VALUE-Tabelle die Ergebnisse
  *                        von P_STMT als <Spaltenname> : <Spaltenwert> liefert.
  * %usage Wird verwendet, um einen Cursor in eine PL/SQL-Tabelle mit benannten
  *        Schluesselwerten zu migrieren
  */
  procedure copy_row_to_key_value_tab(
    p_cursor        in out nocopy sys_refcursor,
    p_key_value_tab in out nocopy key_value_tab)
  as
    l_cur      integer;
    l_cur_desc dbms_sql.desc_tab2;
  begin
    describe_cursor(
      p_cursor => p_cursor,
      p_cur => l_cur,
      p_cur_desc => l_cur_desc,
      p_key_value_tab => p_key_value_tab);
  
    if dbms_sql.fetch_rows(l_cur) > 0 then
      copy_values(
        p_cur => l_cur,
        p_cur_desc => l_cur_desc,
        p_key_value_tab => p_key_value_tab);
    end if;
  
    dbms_sql.close_cursor(l_cur);
  end copy_row_to_key_value_tab;


  /* Prozedur zum Kopieren einer Ergebnismenge einer SQL-Anweisung in eine Liste
   * von KEY-VALUE-Tabellen. Jeder Eintrag der Tabelle enthaelt eine KEY-VALUE-Tabelle
   * gem. COPY_ROW_TO_KEY_VALUE_TAB. Die ERgebnisliste ist INDEX BY BINARY_INTEGER.
   * %param  p_stmt     SQL-Anweisung mit einer Spalte pro Ersetzungsanker. Nicht auf eine
   *                    Zeile limitiert
   * %param  p_row_tab  PL/SQL-Tabelle, die in jedem Eintrag eine PL/SQL-Tabelle mit#
   *                    KEY-VALUE-Paaren gem. COPY_ROW_TO_KEY_VALUE_TAB enthaelt
   * %usage Wird verwendet, um eine Liste von merhreren Ersetzungsankern in einem
   *        Durchgang in eine doppelte KEY-VALUE-Tabelle zu konvertieren.
>>>>>>> 3366522f4f398efd6ca6128b70a2eb24eb219aca
   */
  procedure copy_table_to_row_tab(
    p_cursor in sys_refcursor,
    p_row_tab in out nocopy row_tab)
  as
    l_cur integer;
    l_cur_desc dbms_sql.desc_tab2;
  begin
    describe_cursor(
<<<<<<< HEAD
      p_cursor => p_cursor,
      p_cur => l_cur,
      p_cur_desc => l_cur_desc);
=======
      p_stmt => p_stmt,
      p_cur  => l_cur,
      p_cur_desc => l_cur_desc,
      p_key_value_tab => l_key_value_tab,
      p_first_column_is_template => p_first_column_is_template);
  
    copy_values(
      p_cur => l_cur,
      p_cur_desc => l_cur_desc,
      p_key_value_tab => l_key_value_tab,
      p_row_tab => p_row_tab,
      p_first_column_is_template => p_first_column_is_template);
  
    dbms_sql.close_cursor(l_cur);
  end copy_table_to_row_tab;
>>>>>>> 3366522f4f398efd6ca6128b70a2eb24eb219aca

    copy_values(
      p_cur => l_cur,
      p_cur_desc => l_cur_desc,
      p_row_tab => p_row_tab);

<<<<<<< HEAD
=======
  /* Prozedur zum Kopieren einer Ergebnismenge einer SQL-Anweisung in eine Liste
   * von KEY-VALUE-Tabellen. Jeder Eintrag der Tabelle enthaelt eine KEY-VALUE-Tabelle
   * gem. COPY_ROW_TO_KEY_VALUE_TAB. Die ERgebnisliste ist INDEX BY BINARY_INTEGER.
   * %param  p_cursor                    Geoeffneter Cursor, der mehr als eine Zeile liefern kann
   * %param  p_row_tab                   PL/SQL-Tabelle, die in jedem Eintrag eine PL/SQL-Tabelle mit#
   *                                     KEY-VALUE-Paaren gem. COPY_ROW_TO_KEY_VALUE_TAB enthaelt
   * %param [p_first_column_is_template] Flag, das anzeigt, ob in der ersten Spalte
   *                                     das Template fuer diese Zeile uebergeben wird.
   * %usage Wird verwendet, um eine Liste von merhreren Ersetzungsankern in einem
   *        Durchgang in eine doppelte KEY-VALUE-Tabelle zu konvertieren.
   */
  procedure copy_table_to_row_tab(
    p_cursor                   in out nocopy sys_refcursor,
    p_row_tab                  in out nocopy row_tab,
    p_first_column_is_template boolean default false) 
  as
    l_cur           integer;
    l_cur_desc      dbms_sql.desc_tab2;
    l_key_value_tab key_value_tab;
  begin
    describe_cursor(
      p_cursor => p_cursor,
      p_cur => l_cur,
      p_cur_desc => l_cur_desc,
      p_key_value_tab => l_key_value_tab,
      p_first_column_is_template => p_first_column_is_template);
  
    copy_values(
      p_cur => l_cur,
      p_cur_desc => l_cur_desc,
      p_key_value_tab => l_key_value_tab,
      p_row_tab => p_row_tab,
      p_first_column_is_template => p_first_column_is_template);
  
>>>>>>> 3366522f4f398efd6ca6128b70a2eb24eb219aca
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
<<<<<<< HEAD
    c_anchor_regex constant varchar2(20) := g_main_anchor_char || '[A-Z].*?' || g_main_anchor_char;
    c_name_regex constant varchar2(20) := '[^' || g_main_anchor_char || g_main_separator_char || ']+';
    c_parts_regex constant varchar2(20) := '(.*?)(\' || g_main_separator_char || '|$)';

    -- cursor to extract all replacement anchors from a template and separate
    -- Pre/Postfixes and NULL replacement values
=======
    c_regex constant varchar2(20) := g_main_anchor_char || '.+?' || g_main_anchor_char;
    c_regex_anchor constant varchar2(20) := '[^|]+';
    c_regex_replacement constant varchar2(20) := '(.*?)(\||$)';
      
    /* SQL-Anweisung, um generisch aus einem Template alle Ersetzungsanker auszulesen und 
     * optionale Pre- und Postfixe sowie Ersatzwerte fuer NULL zu ermitteln
     */
>>>>>>> 3366522f4f398efd6ca6128b70a2eb24eb219aca
    cursor replacement_cur(p_template in varchar2) is
        with anchors as (
                select trim(g_main_anchor_char from regexp_substr(p_template, c_anchor_regex, 1, level)) replacement_string
                  from dual
               connect by level <= regexp_count(p_template, g_main_anchor_char) / 2)
      select g_main_anchor_char || replacement_string || g_main_anchor_char as replacement_string,
<<<<<<< HEAD
             upper(regexp_substr(replacement_string, c_name_regex, 1, 1)) anchor,
             regexp_substr(replacement_string, c_parts_regex, 1, 2, null, 1) prefix,
             regexp_substr(replacement_string, c_parts_regex, 1, 3, null, 1) postfix,
             regexp_substr(replacement_string, c_parts_regex, 1, 4, null, 1) null_value
=======
             upper(regexp_substr(replacement_string, c_regex_anchor, 1, 1)) anchor,
             regexp_substr(replacement_string, c_regex_replacement, 1, 2, null, 1) prefix,
             regexp_substr(replacement_string, c_regex_replacement, 1, 3, null, 1) postfix,
             regexp_substr(replacement_string, c_regex_replacement, 1, 4, null, 1) null_value
>>>>>>> 3366522f4f398efd6ca6128b70a2eb24eb219aca
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
        l_missing_anchors := l_missing_anchors || c_anchor_delimiter || rep.anchor;
      end if;
    end loop;

    if l_missing_anchors is not null and not g_ignore_missing_anchors then
<<<<<<< HEAD
      l_missing_anchors := ltrim(l_missing_anchors, '|');
      pit.error(msg.CODE_GEN_MISSING_ANCHORS, msg_args(l_missing_anchors));
=======
      l_missing_anchors := ltrim(l_missing_anchors, c_anchor_delimiter);
      msg_log.error(
        msg_pkg.code_gen_missing_anchors,
        msg_args(l_missing_anchors));
>>>>>>> 3366522f4f398efd6ca6128b70a2eb24eb219aca
    end if;

    -- recursive call if the method has replaced anything. As the replacements may
    -- contain anchors, this is necessary. If so, replace secondary anchor chars
    -- with primary anchor chars to make them visible to BULK_REPLACE
    if p_template != p_result then
      bulk_replace(
<<<<<<< HEAD
        p_template => replace(
                        replace(p_result, 
                          g_secondary_anchor_char, g_main_anchor_char), 
                          g_secondary_separator_char, g_main_separator_char),
        p_clob_tab => p_clob_tab,
=======
        p_template => replace(p_result, g_secondary_anchor_char, g_main_anchor_char),
        p_key_value_tab => p_key_value_tab,
>>>>>>> 3366522f4f398efd6ca6128b70a2eb24eb219aca
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
<<<<<<< HEAD
    -- Initialize
    p_result := clob_table();

=======
    bulk_replace(
      p_template => p_template,
      p_key_value_tab => p_key_value_tab,
      p_result => l_result,
      p_indnet => p_indent);
    return l_result;
  end bulk_replace;


  -- %param p_row_tab Liste mit Tabelle von KEY-VALUE-Paaren, erzeugt ueber COPY_TABLE_TO_ROW_TAB
  procedure bulk_replace(
    p_template                 in clob,
    p_row_tab                  in row_tab,
    p_delimiter                in varchar2,
    p_result                   out clob,
    p_first_column_is_template boolean default false,
    p_indent                   number) 
  as
    l_result clob;
    l_template clob;
    l_key_value_tab key_value_tab;
  begin
>>>>>>> 3366522f4f398efd6ca6128b70a2eb24eb219aca
    if p_row_tab.count > 0 then
      for i in p_row_tab.first .. p_row_tab.last loop
<<<<<<< HEAD
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
=======
        l_key_value_tab := p_row_tab(i);
        if p_first_column_is_template then
          l_template := l_key_value_tab(c_row_template);
        end if;
        
        bulk_replace(
          p_template => l_template,
          p_key_value_tab => l_key_value_tab,
          p_result => l_result,
          p_indent => p_indent);
      
        if i < p_row_tab.last then
          l_result := l_result || p_delimiter;
>>>>>>> 3366522f4f398efd6ca6128b70a2eb24eb219aca
        end if;

<<<<<<< HEAD
        p_result.extend;
        p_result(p_result.count) := l_result;
=======

  -- %param  p_result  Ausgabeparameter vom Typ DBMS_SQL.CLOB_TABLE (deprecated)
  procedure bulk_replace(
    p_template                 in clob,
    p_row_tab                  in row_tab,
    p_delimiter                in varchar2,
    p_result                   out dbms_sql.clob_table,
    p_first_column_is_template boolean default false,
    p_indent                   number) 
  as
    l_result clob;
    l_template  clob;
    l_key_value_tab key_value_tab;
  begin
    msg_log.assert(
      p_condition => p_row_tab.count > 0,
      p_message_id => msg.PASS_INFORMATION,
      p_arg_list => msg_args('Keine Zeilen gefunden'));
      
    -- Initialisierung
    l_template := p_template;
    dbms_lob.createtemporary(l_result, false, dbms_lob.call);
    
    if p_row_tab.count > 0 then
      for i in p_row_tab.first .. p_row_tab.last loop
        l_key_value_tab := p_row_tab(i);
      
        if p_first_column_is_template then
          l_template := l_key_value_tab(c_row_template);
        end if;
      
        bulk_replace(
          p_template => l_template,
          p_key_value_tab => l_key_value_tab,
          p_result => l_result,
          p_indent => p_indent);
      
        if i < p_row_tab.last then
          l_result := l_result || p_delimiter;
        end if;
      
        p_result(i) := l_result;
>>>>>>> 3366522f4f398efd6ca6128b70a2eb24eb219aca
      end loop;
    end if;
  end bulk_replace;


<<<<<<< HEAD
=======
  -- %param  p_result  Ausgabeparameter vom Typ CLOB_TABLE
  procedure bulk_replace(
    p_template                 in clob,
    p_row_tab                  in row_tab,
    p_delimiter                in varchar2,
    p_result                   out clob_table,
    p_first_column_is_template boolean default false,
    p_indent                   number) 
  as
    l_result clob;
    l_template clob;
    l_key_value_tab key_value_tab;
  begin
    -- Initialisierung
    l_template := p_template;
    p_result := clob_table();
    
    msg_log.assert(
      p_condition => p_row_tab.count > 0,
      p_message_id => msg_pkg.ASSERTION_ERROR);
      
    for i in p_row_tab.first .. p_row_tab.last loop
      l_key_value_tab := p_row_tab(i);
    
      if p_first_column_is_template then
        l_template := l_key_value_tab(c_row_template);
      end if;
    
      bulk_replace(
        p_template => l_template,
        p_key_value_tab => l_key_value_tab,
        p_result => l_result,
        p_indent => p_indent);
    
      if i < p_row_tab.last then
        l_result := l_result || p_delimiter;
      end if;
    
      p_result.extend;
      p_result(p_result.count) := l_result;
    end loop;
  exception
    when msg_pkg.ASSERTION_ERROR_EXC then
      null;
  end bulk_replace;
  

>>>>>>> 3366522f4f398efd6ca6128b70a2eb24eb219aca
  /* Initialisierungsprozedur des Packages */
  procedure initialize as
  begin
    g_ignore_missing_anchors := true;
<<<<<<< HEAD
    g_default_date_format := c_default_date_format;
    g_main_anchor_char := param.get_string('MAIN_ANCHOR_CHAR', c_param_group);
    g_main_separator_char := param.get_string('MAIN_SEPARATOR_CHAR', c_param_group);
    g_secondary_anchor_char := param.get_string('SECONDARY_ANCHOR_CHAR', c_param_group);
    g_secondary_separator_char := param.get_string('SECONDARY_SEPARATOR_CHAR', c_param_group);
=======
    g_default_date_format := 'dd.mm.yyyy hh24:mi:ss';
    g_main_anchor_char := '#';
    g_secondary_anchor_char := '^';
>>>>>>> 3366522f4f398efd6ca6128b70a2eb24eb219aca
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
<<<<<<< HEAD
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
=======
    copy_table_to_row_tab(
      p_stmt => p_stmt,
      p_row_tab => l_row_tab,
      p_first_column_is_template => true);
  
    bulk_replace(
      p_template => null,
      p_row_tab => l_row_tab,
      p_delimiter => p_delimiter,
      p_result => p_result,
      p_first_column_is_template => true,
      p_indent => p_indent);
  end generate_text;


  procedure generate_text(
    p_stmt      in clob,
    p_result    out dbms_sql.clob_table,
    p_delimiter in varchar2 default null,
    p_indent    in number default 0) 
  as
    l_row_tab row_tab;
  begin
    copy_table_to_row_tab(
      p_stmt                     => p_stmt,
      p_row_tab                  => l_row_tab,
      p_first_column_is_template => true);
  
    bulk_replace(
      p_template => null,
      p_row_tab => l_row_tab,
      p_delimiter => p_delimiter,
      p_result => p_result,
      p_first_column_is_template => true,
      p_indent => p_indent);
  end generate_text;
>>>>>>> 3366522f4f398efd6ca6128b70a2eb24eb219aca


  function bulk_replace(
    p_template in clob,
    p_chunks in key_value_tab,
    p_indent in number default 0)
    return clob
  as
    l_clob_tab clob_tab;
    l_result clob;
  begin
<<<<<<< HEAD
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
=======
    copy_table_to_row_tab(
      p_stmt => p_stmt,
      p_row_tab => l_row_tab,
      p_first_column_is_template => false);
  
    bulk_replace(
      p_template => p_template,
      p_row_tab => l_row_tab,
      p_delimiter => p_delimiter,
      p_result => p_result,
      p_indent => p_indent);
  end generate_text;
  

  -- Ueberladung als Funktion
  function generate_text(
    p_stmt      in clob,
    p_delimiter in varchar2 default null,
    p_indent    in number default 0) 
    return clob 
  as
    l_clob clob;
  begin
    generate_text(
      p_stmt => p_stmt,
      p_result => l_clob,
      p_delimiter => p_delimiter,
      p_indent => p_indent);
    return l_clob;
  end generate_text;
>>>>>>> 3366522f4f398efd6ca6128b70a2eb24eb219aca


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
<<<<<<< HEAD
    dbms_lob.createtemporary(p_result, false, dbms_lob.call);

    copy_table_to_row_tab(
      p_cursor => p_cursor,
      p_row_tab => l_row_tab);
=======
    copy_table_to_row_tab(
      p_cursor => p_cursor,
      p_row_tab => l_row_tab,
      p_first_column_is_template => true);
  
    bulk_replace(
      p_template => null,
      p_row_tab => l_row_tab,
      p_delimiter => p_delimiter,
      p_result => p_result,
      p_first_column_is_template => true,
      p_indent => p_indent);
  end generate_text;


  procedure generate_text(
    p_template  in varchar2,
    p_cursor    in out nocopy sys_refcursor,
    p_result    out varchar2,
    p_delimiter in varchar2 default null,
    p_indent    in number default 0) 
  as
    l_row_tab row_tab;
  begin
    msg_log.assert_not_null(
      p_condition => p_template,
      p_message_id => msg_pkg.no_such_template,
      p_arg_list => msg_args(p_template));
  
    copy_table_to_row_tab(
      p_cursor => p_cursor,
      p_row_tab => l_row_tab,
      p_first_column_is_template => false);
  
    bulk_replace(
      p_template => p_template,
      p_row_tab => l_row_tab,
      p_delimiter => p_delimiter,
      p_result => p_result,
      p_indent => p_indent);
  end generate_text;
>>>>>>> 3366522f4f398efd6ca6128b70a2eb24eb219aca

    bulk_replace(
      p_row_tab => l_row_tab,
      p_indent => p_indent,
      p_result => l_result);

<<<<<<< HEAD
    -- Concatenate CLOB_TAB to CLOB
    for i in l_result.first .. l_result.last loop
      dbms_lob.append(p_result, l_result(i) || case when i < l_result.last then p_delimiter end);
    end loop;
=======
  procedure generate_text(
    p_cursor    in out nocopy sys_refcursor,
    p_result    out dbms_sql.clob_table,
    p_delimiter in varchar2 default null,
    p_template  in varchar2 default null,
    p_indent    in number default 0) 
  as
    l_row_tab row_tab;
  begin
    copy_table_to_row_tab(
      p_cursor => p_cursor,
      p_row_tab => l_row_tab,
      p_first_column_is_template => p_template is null);
  
    bulk_replace(
      p_template => p_template,
      p_row_tab => l_row_tab,
      p_delimiter => p_delimiter,
      p_result => p_result,
      p_first_column_is_template => p_template is null,
      p_indent => p_indent);
>>>>>>> 3366522f4f398efd6ca6128b70a2eb24eb219aca
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
<<<<<<< HEAD
    generate_text(
      p_cursor => p_cursor,
      p_result => l_clob,
      p_delimiter => p_delimiter,
      p_indent => p_indent);
=======
    if p_template is not null then
      generate_text(
        p_cursor => l_cur,
        p_result  => l_clob,
        p_delimiter => p_delimiter,
        p_template => p_template,
        p_indent => p_indent);
    else
      generate_text(
        p_cursor => l_cur,
        p_result => l_clob,
        p_delimiter => p_delimiter,
        p_indent => p_indent);
    end if;
>>>>>>> 3366522f4f398efd6ca6128b70a2eb24eb219aca
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
<<<<<<< HEAD
      p_row_tab => l_row_tab);

    bulk_replace(
      p_row_tab => l_row_tab,
      p_indent => p_indent,
      p_result => p_result);
=======
      p_row_tab  => l_row_tab,
      p_first_column_is_template => p_template is null);
  
    bulk_replace(
      p_template => p_template,
      p_row_tab  => l_row_tab,
      p_delimiter => p_delimiter,
      p_result => p_result,
      p_first_column_is_template => p_template is null,
      p_indent => p_indent);
>>>>>>> 3366522f4f398efd6ca6128b70a2eb24eb219aca
  end generate_text_table;


  -- Ueberladung als Funktion
  function generate_text_table(
    p_cursor in sys_refcursor,
    p_indent in number default 0)
    return clob_table
  as
    l_clob_table clob_table;
<<<<<<< HEAD
  begin
    generate_text_table(
        p_cursor => p_cursor,
        p_result => l_clob_table,
        p_indent => p_indent);
=======
    l_cur sys_refcursor := p_cursor;
  begin
    if p_template is not null then
      generate_text_table(
        p_cursor => l_cur,
        p_result => l_clob_table,
        p_delimiter => p_delimiter,
        p_template => p_template,
        p_indent => p_indent);
    else
      generate_text_table(
        p_cursor => l_cur,
        p_result => l_clob_table,
        p_delimiter => p_delimiter,
        p_indent => p_indent);
    end if;
>>>>>>> 3366522f4f398efd6ca6128b70a2eb24eb219aca
    return l_clob_table;
  end generate_text_table;

begin
  initialize;
end code_generator;
/
