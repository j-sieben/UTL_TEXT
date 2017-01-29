create or replace package body code_generator
as
  
  C_ROW_TEMPLATE constant varchar2(30) := '$$ROW_TEMPLATE';
  g_ignore_missing_anchors boolean;
  
  /* Hilfsfunktionen */
  
  /* Prozedur zum Oeffnen eines Cursors
   * %param p_cur ID des Cursors
   * %usage Oeffnet einen neuen Cursor fuer eine uebergebene SQL-Anweisung
   */
  procedure open_cursor(
    p_cur out integer)
  as
  begin
    p_cur := dbms_sql.open_cursor;
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
   */
  procedure describe_columns(
    p_cur in integer,
    p_cur_desc in out nocopy dbms_sql.desc_tab2,
    p_key_value_tab in out nocopy key_value_tab,
    p_first_column_is_template boolean default false)
  as
    l_column_name varchar2(30);
    l_column_count integer := 1;
  begin
    -- DESCRIBE_COLUMNS ist deprecated wegen limitierter Spaltenlaenge
    dbms_sql.describe_columns2(
      c => p_cur, 
      col_cnt => l_column_count,
      desc_t => p_cur_desc);
      
    for i in 1 .. l_column_count loop
      if i = 1 and p_first_column_is_template then
        l_column_name := C_ROW_TEMPLATE;
      else
        l_column_name := p_cur_desc(i).col_name;
      end if;
        
      -- Spalte als leeren Wert in der PL/SQL-Tabelle anlegen, um ihn als Variable
      -- referenzieren zu koennen
      p_key_value_tab(l_column_name) := null;
        
      -- Registriere Variable als Ausgabevariable dieser Spalte
      dbms_sql.define_column_char(
        c => p_cur, 
        position => i,
        column => p_key_value_tab(l_column_name), 
        column_size => 4000);
      -- COLUMN_SIZE = 4000 fuehrt dazu, dass CHAR(4000)-Werte erzeugt werden.
      -- Daher muss beim Fuellen auf ein TRIM() geachtet werden.
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
    p_stmt in varchar2,
    p_cur in out nocopy integer,
    p_cur_desc in out nocopy dbms_sql.desc_tab2,
    p_key_value_tab in out nocopy key_value_tab)
  as
    l_success integer;
  begin
    open_cursor(p_cur);
    dbms_sql.parse(p_cur, p_stmt, dbms_sql.native);
    l_success := dbms_sql.execute(p_cur);
    describe_columns(p_cur, p_cur_desc, p_key_value_tab);
  end describe_cursor;
  
  
  /* Prozedur zum Beschreiben eines Cursors
   * %param p_cursor Bereits geoeffneter Cursor, der analysiert werden soll
   * %param p_cur ID des Cursors
   * %param p_cur_desc DBMS_SQL.DESC_TAB2 mit den Details zu einem Cursor
   * %param p_key_value_tab PL/SQL-Tabelle mit dem Spaltennamen (KEY) und 
   *        einem initialen NULL-Wert fuer jede Spalte des Cursors
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
    open_cursor(
      p_cur => p_cur, 
      p_cursor => p_cursor);
      
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
        l_column_name := C_ROW_TEMPLATE;
      else
        l_column_name := p_cur_desc(i).col_name;
      end if;
      
      -- Aktuellen Spaltenwerte auslesen
      dbms_sql.column_value_char(p_cur, i, p_key_value_tab(l_column_name));
      -- Elementwert trimmen, um unnoetigen Weissraum zu entfernen 
      p_key_value_tab(l_column_name) := trim(p_key_value_tab(l_column_name));
    end loop;
  end copy_values;
  
  
  /* Pozedur zum Kopieren einer Zeile in die vorbereitete PL/SQL-Tabelle
   * %param p_cur ID des Cursor
   * %param p_cur_desc DBMS_SQL.DESC_TAB2 mit den Details zu einem Cursor
   * %param p_key_value_tab PL/SQL-Tabelle mit dem Spaltennamen (KEY) und 
   *        einem initialen NULL-Wert fuer jede Spalte des Cursors
   * %param p_row_tab Liste von Instanzen KEY_VALUE_TAB, fuer jede Zeile der
   *        Ergebnismenge des Cursors
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
  
  
  function get_ignore_missing_anchors
    return boolean
  as
  begin
    return g_ignore_missing_anchors;
  end get_ignore_missing_anchors;
  
  
  procedure copy_row_to_key_value_tab(
    p_stmt in varchar2,
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
    p_stmt in varchar2,
    p_row_tab in out nocopy row_tab)
  as
    l_cur integer;
    l_cur_desc dbms_sql.desc_tab2;
    l_key_value_tab key_value_tab;
  begin
    describe_cursor(
      p_stmt => p_stmt, 
      p_cur => l_cur, 
      p_cur_desc => l_cur_desc, 
      p_key_value_tab => l_key_value_tab);
      
    copy_values(
      p_cur => l_cur, 
      p_cur_desc => l_cur_desc, 
      p_key_value_tab => l_key_value_tab, 
      p_row_tab => p_row_tab);
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
  

  procedure bulk_replace(
    p_template in varchar2,
    p_key_value_tab in key_value_tab,
    p_result out varchar2)
  as
    /* SQL-Anweisung, um generisch aus einem Template alle Ersetzungsanker
       auszulesen und optionale Pre- und Postfixe sowie Ersatzwerte fuer NULL
       zu ermitteln
       Syntax des Ersetzungsankers:
       #<Name>[|<Prefix>[|<Postfix>[|<NULL-Ersatzwert>]]]#
       Beispiele:
        #COLUMN_VALUE#
        #COLUMN_VALUE||, #
        #EMP_ID|(|), |ohne ID#
     */
    cursor replacement_cur(p_template in varchar2) is
        with data as(
             select p_template template
               from dual),
             anchors as(
              select regexp_substr(template, '#.+?#', 1, level) a
                from data
             connect by level <= regexp_count(template, '#')/2)
      select a replacement_string, 
             upper(regexp_substr(a, '[^#|]+')) anchor, 
             regexp_substr(a, '[^#|]+', 1, 2) prefix, 
             regexp_substr(a, '[^#|]+', 1, 3) postfix, 
             regexp_substr(a, '[^#|]+', 1, 4) not_null
        from anchors;  
    l_key_value_tab code_generator.key_value_tab;
    l_value varchar2(4000);
    l_result varchar2(32767);
    l_missing_anchors varchar2(4000);
  begin
    p_result := p_template;
    for rep in replacement_cur(p_template) loop
    
      if p_key_value_tab.exists(rep.anchor) then
        l_value := p_key_value_tab(rep.anchor);
        if l_value is not null then
          p_result := replace(p_result, rep.replacement_string, rep.prefix || l_value || rep.postfix);
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
      pit.error(msg.CODE_GEN_MISSING_ANCHORS, msg_args(l_missing_anchors));
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
    
    for i in p_row_tab.first .. p_row_tab.last loop
      l_key_value_tab := p_row_tab(i);
      
      if p_first_column_is_template then
        l_template := l_key_value_tab(C_ROW_TEMPLATE);
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
  end bulk_replace;
  
  
  procedure generate_text(
    p_template in varchar2,
    p_stmt in varchar2,
    p_result out varchar2,
    p_delimiter in varchar2 default null)
  as
    l_row_tab row_tab;
  begin
    code_generator.copy_table_to_row_tab(
      p_stmt => p_stmt,
      p_row_tab => l_row_tab);
    code_generator.bulk_replace(
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
    l_key_value_tab key_value_tab;
    l_result varchar2(32767);
  begin
    code_generator.copy_table_to_row_tab(
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

begin
  initialize;
end code_generator;
/
