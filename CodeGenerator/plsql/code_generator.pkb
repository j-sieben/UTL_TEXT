create or replace package body code_generator 
as

  c_row_template constant varchar2(30) := '$$ROW_TEMPLATE';
  c_date_type constant binary_integer := 12;
  c_date_format constant varchar2(30) := 'dd.mm.yyyy hh24:mi:ss';
  g_ignore_missing_anchors boolean;

  type ref_rec_type is record(
    r_string varchar2(32767),
    r_date date,
    r_clob clob);
  l_ref_rec ref_rec_type;


  /* Hilfsfunktionen */

  /* Prozedur zum Oeffnen eines Cursors
   * %param p_cur ID des Cursors
   * %usage Oeffnet einen neuen Cursor fuer eine uebergebene SQL-Anweisung
   */
  procedure open_cursor(
    p_cur out integer) 
  as
  begin
    if not dbms_sql.is_open(c => p_cur) then
      p_cur := dbms_sql.open_cursor;
    end if;
  end open_cursor;


  /* Prozedur zum Oeffnen eines Cursors
   * %param p_cur ID des Cursors
   * %param p_cursor SYS_REFCURSOR, Ueberladung fuer einen bereits geoffneten Cursor
   * %usage Wird verwendet, wenn im aufrufenden Code bereits ein Cursor existiert
   *        und nicht nur eine SQL-Anweisung. Konvertiert diesen Cursor in einen
   *        DBMS_SQL-Cursor, der anschliessend analysiert werden kann.
   */
  procedure open_cursor(
    p_cur out integer,
    p_cursor in out nocopy sys_refcursor) 
  as
  begin
    p_cur := dbms_sql.to_cursor_number(p_cursor);
  end open_cursor;


  /* Prozedur zum Analysieren eines Cursor
   * %param p_cur ID des Cursors
   * %param p_cur_desc DBMS_SQL.DESC_TAB2 mit den Details zu einem Cursor
   * %param p_key_value_tab PL/SQL-Tabelle mit dem Spaltennamen (KEY) und 
   *        einem initialen NULL-Wert fuer jede Spalte des Cursors
   * %param p_first_column_is_template Flag, das anzeigt, ob in der ersten Spalte
   *        das Template fuer diese Zeile uebergeben wird.
   * %usage Wird verwendet, um die Spalten eines uebergebenen DBMS_SQL-Cursors
   *        zu beschreiben. Der Code erfuellt folgende Aufgaben:
   *        - Cursor analysieren
   *        - PL/SQL-Tabelle mit Schluessel fuer jede Spalte erstellen, NULL-Wert belegen
   *        - PL/SQL-Tabelleneintraege als Ausgabevariablen fuer Spaltenwert registrieren
   */
  procedure describe_columns(
    p_cur in integer,
    p_cur_desc in out nocopy dbms_sql.desc_tab2,
    p_key_value_tab in out nocopy key_value_tab,
    p_first_column_is_template boolean default false)
  as
    l_column_name varchar2(30);
    l_column_count integer := 1;
    l_column_type integer;
    l_cnt binary_integer := 0;
  begin
    -- DESCRIBE_COLUMNS ist deprecated wegen limitierter Spaltenlaenge
    dbms_sql.describe_columns2(
      c => p_cur,
      col_cnt => l_column_count,
      desc_t => p_cur_desc);

    for i in 1 .. l_column_count loop
      -- Dalls erste Spalte Tempalte ist, fuer spaeteren Zugriff besonders benennen
      if i = 1 and p_first_column_is_template then
        l_column_name := c_row_template;
      else
        l_column_name := p_cur_desc(i).col_name;
      end if;
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
      end if;
    end loop;
  end describe_columns;


  /* Prozedur zum Beschreiben eines Cursors
   * %param p_stmt SQL-Anweisung, die analysiert werden soll
   * %param p_cur ID des Cursors
   * %param p_cur_desc DBMS_SQL.DESC_TAB2 mit den Details zu einem Cursor
   * %param p_key_value_tab PL/SQL-Tabelle mit dem Spaltennamen (KEY) und 
   *        einem initialen NULL-Wert fuer jede Spalte des Cursors
   * %usage Wird verwendet, um eine SQL-Anweisung zu analysieren und eine PL/SQL-Tabelle
   *        zur Aufnahme der jeweiligen Spaltenwerte unter dem Spaltennamen zu erzeugen.
   */
  procedure describe_cursor(
    p_stmt in clob,
    p_cur in out nocopy integer,
    p_cur_desc in out nocopy dbms_sql.desc_tab2,
    p_key_value_tab in out nocopy key_value_tab,
    p_first_column_is_template boolean default false) 
  as
    l_ignore integer;
  begin
    open_cursor(p_cur);
    dbms_sql.parse(p_cur, p_stmt, dbms_sql.native);
    l_ignore := dbms_sql.execute(p_cur);
    describe_columns(p_cur, p_cur_desc, p_key_value_tab, p_first_column_is_template);
  end describe_cursor;


  /* Prozedur zum Beschreiben eines Cursors
   * %param p_cursor Bereits geoeffneter Cursor, der analysiert werden soll
   * %param p_cur ID des Cursors
   * %param p_cur_desc DBMS_SQL.DESC_TAB2 mit den Details zu einem Cursor
   * %param p_key_value_tab PL/SQL-Tabelle mit dem Spaltennamen (KEY) und 
   *        einem initialen NULL-Wert fuer jede Spalte des Cursors
   * %param p_first_column_is_template Flag, das anzeigt, ob in der ersten Spalte
   *        das Template fuer diese Zeile uebergeben wird.
   * %usage Ueberladung, wird verwendet, um einen Cursor zu analysieren und eine PL/SQL-Tabelle
   *        zur Aufnahme der jeweiligen Spaltenwerte unter dem Spaltennamen zu erzeugen.
   */
  procedure describe_cursor(
    p_cursor in out nocopy sys_refcursor,
    p_cur in out nocopy integer,
    p_cur_desc in out nocopy dbms_sql.desc_tab2,
    p_key_value_tab in out nocopy key_value_tab,
    p_first_column_is_template boolean default false) 
  as
  begin
    open_cursor(p_cur, p_cursor);

    describe_columns(
      p_cur => p_cur,
      p_cur_desc => p_cur_desc,
      p_key_value_tab => p_key_value_tab,
      p_first_column_is_template => p_first_column_is_template);
  end describe_cursor;


  /* Pozedur zum Kopieren einer Zeile in die vorbereitete PL/SQL-Tabelle
   * %param p_cur ID des Cursor
   * %param p_cur_desc DBMS_SQL.DESC_TAB2 mit den Details zu einem Cursor
   * %param p_key_value_tab PL/SQL-Tabelle mit dem Spaltennamen (KEY) und 
   *        einem initialen NULL-Wert fuer jede Spalte des Cursors
   * %param p_first_column_is_template Flag, das anzeigt, ob in der ersten Spalte
   *        das Template fuer diese Zeile uebergeben wird.
   * %usage Wird verwendet, um eine Zeile eines Cursor in die vorbereitete PL/SQL-
   *        Tabelle zu uebernehmen
   */
  procedure copy_values(
    p_cur in integer,
    p_cur_desc in dbms_sql.desc_tab2,
    p_key_value_tab in out nocopy key_value_tab,
    p_first_column_is_template boolean default false) 
  as
    l_column_name varchar2(30);
  begin
    for i in p_cur_desc.first .. p_cur_desc.last loop
      if i = 1 and p_first_column_is_template then
        l_column_name := c_row_template;
      else
        l_column_name := p_cur_desc(i).col_name;
      end if;

      -- Aktuellen Spaltenwerte auslesen
      if p_cur_desc(i).col_type = c_date_type then
        dbms_sql.column_value(p_cur, i, l_ref_rec.r_date);
        p_key_value_tab(l_column_name) := to_char(l_ref_rec.r_date, c_date_format);
      else
        dbms_sql.column_value(p_cur, i, p_key_value_tab(l_column_name));
      end if;
    end loop;
  end copy_values;


  /* Pozedur zum Kopieren einer Zeile in die vorbereitete PL/SQL-Tabelle
   * %param p_cur ID des Cursor
   * %param p_cur_desc DBMS_SQL.DESC_TAB2 mit den Details zu einem Cursor
   * %param p_key_value_tab PL/SQL-Tabelle mit dem Spaltennamen (KEY) und 
   *        einem initialen NULL-Wert fuer jede Spalte des Cursors
   * %param p_row_tab Liste von Instanzen KEY_VALUE_TAB, fuer jede Zeile der
   *        Ergebnismenge des Cursors
   * %param p_first_column_is_template Flag, das anzeigt, ob in der ersten Spalte
   *        das Template fuer diese Zeile uebergeben wird.
   * %usage Wird verwendet, alle Zeilen eines Cursor in eine Liste aus 
   *        vorbereiteten PL/SQL-Tabellen zu uebernehmen
   */
  procedure copy_values(
    p_cur in integer,
    p_cur_desc in dbms_sql.desc_tab2,
    p_key_value_tab in out nocopy key_value_tab,
    p_row_tab in out nocopy row_tab,
    p_first_column_is_template boolean default false) 
  as
  begin
    while dbms_sql.fetch_rows(p_cur) > 0 loop
      copy_values(
        p_cur => p_cur,
        p_cur_desc => p_cur_desc,
        p_key_value_tab => p_key_value_tab,
        p_first_column_is_template => p_first_column_is_template);

      p_row_tab(dbms_sql.last_row_count) := p_key_value_tab;
    end loop;
  end copy_values;


  /* Initialisierungsprozedur des Packages */
  procedure initialize 
  as
  begin
    g_ignore_missing_anchors := true;
  end initialize;


  /* INTERFACE */
  procedure set_ignore_missing_anchors(
    p_flag in boolean) 
  as
  begin
    g_ignore_missing_anchors := p_flag;
  end set_ignore_missing_anchors;


  function get_ignore_missing_anchors return boolean 
  as
  begin
    return g_ignore_missing_anchors;
  end get_ignore_missing_anchors;


  procedure copy_row_to_key_value_tab(
    p_stmt in clob,
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
      copy_values(l_cur, l_cur_desc, p_key_value_tab);
    end if;

    dbms_sql.close_cursor(l_cur);
  end copy_row_to_key_value_tab;


  procedure copy_row_to_key_value_tab(
    p_cursor in out nocopy sys_refcursor,
    p_key_value_tab in out nocopy key_value_tab) 
  as
    l_cur integer;
    l_cur_desc dbms_sql.desc_tab2;
  begin
    describe_cursor(
      p_cursor => p_cursor,
      p_cur => l_cur,
      p_cur_desc => l_cur_desc,
      p_key_value_tab => p_key_value_tab);

    if dbms_sql.fetch_rows(l_cur) > 0 then
      copy_values(l_cur, l_cur_desc, p_key_value_tab);
    end if;

    dbms_sql.close_cursor(l_cur);
  end copy_row_to_key_value_tab;


  procedure copy_table_to_row_tab(
    p_stmt in clob,
    p_row_tab in out nocopy row_tab,
    p_first_column_is_template boolean default false) 
  as
    l_cur integer;
    l_cur_desc dbms_sql.desc_tab2;
    l_key_value_tab key_value_tab;
  begin
    describe_cursor(
      p_stmt => p_stmt,
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
  end copy_table_to_row_tab;


  procedure copy_table_to_row_tab(
    p_cursor in out nocopy sys_refcursor,
    p_row_tab in out nocopy row_tab,
    p_first_column_is_template boolean default false) 
  as
    l_cur integer;
    l_cur_desc dbms_sql.desc_tab2;
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
  end copy_table_to_row_tab;


  function bulk_replace(
    p_template in varchar2,
    p_chunks in char_table)
    return varchar2
  as
    l_result varchar2(32767);
    l_key_value_tab key_value_tab;
  begin
    if p_chunks is not null then 
      for i in p_chunks.first .. p_chunks.last loop
        if mod(i, 2) = 1 then
          l_key_value_tab(p_chunks(i)) := p_chunks(i + 1);
        end if;
      end loop;
    end if;
    bulk_replace(p_template, l_key_value_tab, l_result);
    return l_result;
  end bulk_replace;
    
    
  procedure bulk_replace(
    p_template in varchar2,
    p_chunks in char_table,
    p_result out varchar2)
  as
  begin
    p_result := bulk_replace(p_template, p_chunks);
  end bulk_replace;
    
    
  procedure bulk_replace(
    p_text in out nocopy varchar2,
    p_chunks in char_table)
  as
  begin
    p_text := bulk_replace(p_text, p_chunks);
  end bulk_replace;
    
    
  procedure bulk_replace(
    p_template in varchar2,
    p_key_value_tab in key_value_tab,
    p_result out varchar2) 
  as
    /* Format des Ersetzungsankers:
     * #<Name des Ersetzungsankers, muss Tabellenspalte entsprechen>
     *        |<Pr�fix, falls Wert not null>
     *        |<Postfix, falls Wert not null>
     *        |<Wert, falls NULL>#
     */
    cursor replacement_cur(p_template in varchar2) is
      with data as
       (select p_template template
        from   dual),
      anchors as
       (select trim('#' from regexp_substr(template, '#.+?#', 1, level)) replacement_string
        from   data
        connect by level <= regexp_count(template,'#') / 2)
      select '#'||replacement_string||'#' as replacement_string
            ,upper(regexp_substr(replacement_string, '[^|]+', 1, 1)) anchor
            ,regexp_substr(replacement_string, '(.*?)(\||$)', 1, 2, null, 1) prefix
            ,regexp_substr(replacement_string, '(.*?)(\||$)', 1, 3, null, 1) postfix                         
            ,regexp_substr(replacement_string, '(.*?)(\||$)', 1, 4, null, 1) not_null
      from   anchors;

    l_value varchar2(32767);
    l_missing_anchors varchar2(32767);
  begin
    p_result := p_template;

    for rep in replacement_cur(p_template) loop
      if p_key_value_tab.exists(rep.anchor) then
        l_value := p_key_value_tab(rep.anchor);
        if l_value is not null then
          p_result := replace(
                        p_result, 
                        rep.replacement_string, 
                        rep.prefix || l_value || rep.postfix);
        else
          p_result := replace(p_result, rep.replacement_string, rep.not_null);
        end if;
      else
        if g_ignore_missing_anchors then
          null;
        else
          l_missing_anchors := l_missing_anchors || '|' || rep.anchor;
        end if;
      end if;
    end loop;

    if l_missing_anchors is not null then
      l_missing_anchors := trim('|' from l_missing_anchors);
      -- msg_log.error(msg_pkg.code_gen_missing_anchors, msg_args(l_missing_anchors));
    end if;

  end bulk_replace;


  procedure bulk_replace(
    p_template in varchar2,
    p_row_tab in row_tab,
    p_delimiter in varchar2,
    p_result out varchar2,
    p_first_column_is_template boolean default false) 
  as
    l_result varchar2(32767);
    l_template varchar2(4000);
    l_key_value_tab key_value_tab;
  begin
    l_template := p_template;
    if p_row_tab.count > 0 then
      for i in p_row_tab.first .. p_row_tab.last loop
        l_key_value_tab := p_row_tab(i);

        if p_first_column_is_template then
          l_template := l_key_value_tab(c_row_template);
        end if;

        bulk_replace(
          p_template => l_template,
          p_key_value_tab => l_key_value_tab,
          p_result => l_result);

        if i < p_row_tab.last then
          l_result := l_result || p_delimiter;
        end if;

        p_result := p_result || l_result;
      end loop;
    else
      raise no_data_found;
    end if;
  end bulk_replace;


  procedure bulk_replace(
    p_template in varchar2,
    p_row_tab in row_tab,
    p_delimiter in varchar2,
    p_result out dbms_sql.varchar2a,
    p_first_column_is_template boolean default false)
  as
    l_result varchar2(32767);
    l_template varchar2(4000);
    l_key_value_tab key_value_tab;
  begin
    l_template := p_template;
    if p_row_tab.count > 0 then
      for i in p_row_tab.first .. p_row_tab.last loop
        l_key_value_tab := p_row_tab(i);

        if p_first_column_is_template then
          l_template := l_key_value_tab(c_row_template);
        end if;

        bulk_replace(
          p_template => l_template,
          p_key_value_tab => l_key_value_tab,
          p_result => l_result);

        if i < p_row_tab.last then
          l_result := l_result || p_delimiter;
        end if;

        p_result(i) := l_result;
      end loop;
    else
      raise no_data_found;
    end if;
  end bulk_replace;


  procedure generate_text(
    p_template in varchar2,
    p_stmt in clob,
    p_result out varchar2,
    p_delimiter in varchar2 default null)
  as
    l_row_tab row_tab;
  begin
    copy_table_to_row_tab(
      p_stmt => p_stmt,
      p_row_tab => l_row_tab,
      p_first_column_is_template => false);

    bulk_replace(
      p_template => p_template,
      p_row_tab => l_row_tab,
      p_delimiter => p_delimiter,
      p_result => p_result);
  end generate_text;


  procedure generate_text(
    p_template in varchar2,
    p_cursor in out nocopy sys_refcursor,
    p_result out varchar2,
    p_delimiter in varchar2 default null) 
  as
    l_row_tab row_tab;
  begin
    copy_table_to_row_tab(
      p_cursor => p_cursor,
      p_row_tab => l_row_tab);

    bulk_replace(
      p_template => p_template,
      p_row_tab => l_row_tab,
      p_delimiter => p_delimiter,
      p_result => p_result);
  end generate_text;


  procedure generate_text(
    p_cursor in out nocopy sys_refcursor,
    p_result out varchar2,
     p_delimiter in varchar2 default null) 
  as
    l_row_tab row_tab;
  begin
    copy_table_to_row_tab(
      p_cursor => p_cursor,
      p_row_tab => l_row_tab,
      p_first_column_is_template => true);

    bulk_replace(
      p_template => null,
      p_row_tab => l_row_tab,
      p_delimiter => p_delimiter,
      p_result => p_result,
      p_first_column_is_template => true);
  end generate_text;


  procedure generate_text(
    p_stmt in clob,
    p_result out varchar2,
    p_delimiter in varchar2 default null) 
  as
    l_row_tab row_tab;
  begin
    copy_table_to_row_tab(
      p_stmt => p_stmt,
      p_row_tab => l_row_tab,
      p_first_column_is_template => true);

    bulk_replace(
      p_template => null,
      p_row_tab => l_row_tab,
      p_delimiter => p_delimiter,
      p_result => p_result,
      p_first_column_is_template => true);
  end generate_text;


  procedure generate_text(
    p_stmt in clob,
    p_result out dbms_sql.varchar2a,
    p_delimiter in varchar2 default null) 
  as
    l_row_tab row_tab;
  begin
    copy_table_to_row_tab(
      p_stmt => p_stmt,
      p_row_tab => l_row_tab,
      p_first_column_is_template => true);

    bulk_replace(
      p_template => null,
      p_row_tab => l_row_tab,
      p_delimiter => p_delimiter,
      p_result => p_result,
      p_first_column_is_template => true);
  end generate_text;


  function generate_text(
    p_stmt in clob,
    p_delimiter in varchar2 default null) 
    return varchar2 
  as
    l_string varchar2(32767);
  begin
    generate_text(
      p_stmt => p_stmt,
      p_result => l_string,
      p_delimiter => p_delimiter);
    return l_string;
  end generate_text;


  function generate_text(
    p_cursor in sys_refcursor,
    p_delimiter in varchar2 default null) 
    return varchar2 
  as
    l_string varchar2(32767);
    l_cur sys_refcursor := p_cursor;
  begin
    generate_text(
      p_cursor => l_cur,
      p_result => l_string,
      p_delimiter => p_delimiter);
    return l_string;
  end generate_text;


begin
  initialize;
end code_generator;
/

