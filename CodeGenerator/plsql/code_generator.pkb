create or replace package body code_generator 
as

  c_pkg constant varchar2(30) := $$PLSQL_UNIT;
  c_row_template constant varchar2(30) := 'TEMPLATE';
  c_log_template constant varchar2(30) := 'LOG_TEMPLATE';
  c_date_type constant binary_integer := 12;
  c_param_group constant varchar2(30) := 'CODE_GEN';
  
  c_regex_anchor_name constant varchar2(50) := q'^(^[0-9]+$|^[A-Z][A-Z0-9_\$#]+$)^';
  
  g_ignore_missing_anchors boolean;
  g_default_date_format varchar2(200);
  g_default_delimiter_char varchar2(100);
  g_main_anchor_char char(1 char);
  g_secondary_anchor_char char(1 char);
  g_main_separator_char char(1 char);
  g_secondary_separator_char char(1 char);

  /* DATENTYPEN */
  type clob_tab is table of clob index by varchar2(30);
  type row_tab is table of clob_tab index by binary_integer;
  
  -- Record mit Variablen fuer Ergebnisspaltenwerte
  type ref_rec_type is record(
    r_string varchar2(32767),
    r_date date,
    r_clob clob);
  l_ref_rec ref_rec_type;


  /* Hilfsfunktionen */
  /* Prozedur zum Oeffnen eines Cursors
   * %param  p_cur     ID des Cursors
   * %param  p_cursor  SYS_REFCURSOR, Ueberladung fuer einen bereits geoffneten Cursor
   * %usage  Wird verwendet, um den uebergebenen Cursor in einen DBMS_SQL-Cursor 
   *         zu konvertieren, der anschliessend analysiert werden kann.
   */
  procedure open_cursor(
    p_cur out nocopy integer,
    p_cursor in out nocopy sys_refcursor) 
  as
  begin
    p_cur := dbms_sql.to_cursor_number(p_cursor);
  end open_cursor;
  

  /* Prozedur zum Analysieren eines Cursor
   * %param  p_cur       ID des Cursors
   * %param  p_cur_desc  DBMS_SQL.DESC_TAB2 mit den Details zu einem Cursor
   * %param  p_clob_tab  PL/SQL-Tabelle mit dem Spaltennamen (KEY) und 
   *                     einem initialen NULL-Wert fuer jede Spalte des Cursors
   * %usage  Wird verwendet, um die Spalten eines uebergebenen DBMS_SQL-Cursors
   *         zu beschreiben. Der Code erfuellt folgende Aufgaben:
   *         - Cursor analysieren
   *         - PL/SQL-Tabelle mit Schluessel fuer jede Spalte erstellen, NULL-Wert belegen
   *         - PL/SQL-Tabelleneintraege als Ausgabevariablen fuer Spaltenwert registrieren
   */
  procedure describe_columns(
    p_cur in integer,
    p_cur_desc in out nocopy dbms_sql.desc_tab2,
    p_clob_tab in out nocopy clob_tab) 
  as
    l_column_name varchar2(30);
    l_column_count integer := 1;
    l_column_type integer;
    l_cnt binary_integer := 0;
  begin
    dbms_sql.describe_columns2(
      c => p_cur,
      col_cnt => l_column_count,
      desc_t => p_cur_desc);
                              
    for i in 1 .. l_column_count loop
      if i = 1 then
        l_column_name := c_row_template;
      else
        l_column_name := p_cur_desc(i).col_name;
      end if;
      
      l_column_type := p_cur_desc(i).col_type;
      
      -- Spalte als leeren Wert in der PL/SQL-Tabelle anlegen, um ihn als Variable
      -- referenzieren zu koennen
      l_cnt := l_cnt + 1;
      p_clob_tab(l_column_name) := null;
      
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
   * %param p_cursor Bereits geoeffneter Cursor, der analysiert werden soll
   * %param p_cur ID des Cursors
   * %param p_cur_desc DBMS_SQL.DESC_TAB2 mit den Details zu einem Cursor
   * %param p_clob_tab PL/SQL-Tabelle mit dem Spaltennamen (KEY) und 
   *        einem initialen NULL-Wert fuer jede Spalte des Cursors
   * %usage Ueberladung, wird verwendet, um einen Cursor zu analysieren und eine PL/SQL-Tabelle
   *        zur Aufnahme der jeweiligen Spaltenwerte unter dem Spaltennamen zu erzeugen.
   */
  procedure describe_cursor(
    p_cursor in out nocopy sys_refcursor,
    p_cur in out nocopy integer,
    p_cur_desc in out nocopy dbms_sql.desc_tab2,
    p_clob_tab in out nocopy clob_tab) 
  as
  begin
    open_cursor(
      p_cur => p_cur,
      p_cursor => p_cursor);
  
    describe_columns(
      p_cur => p_cur,
      p_cur_desc => p_cur_desc,
      p_clob_tab => p_clob_tab);
  end describe_cursor;
  

  /* Pozedur zum Kopieren einer Zeile in die vorbereitete PL/SQL-Tabelle
   * %param  p_cur       ID des Cursor
   * %param  p_cur_desc  DBMS_SQL.DESC_TAB2 mit den Details zu einem Cursor
   * %param  p_clob_tab  PL/SQL-Tabelle mit dem Spaltennamen (KEY) und 
   *                     einem initialen NULL-Wert fuer jede Spalte des Cursors
   * %usage  Wird verwendet, um eine Zeile eines Cursor in die vorbereitete PL/SQL-
   *         Tabelle zu uebernehmen
   */
  procedure copy_values(
    p_cur in integer,
    p_cur_desc in dbms_sql.desc_tab2,
    p_clob_tab in out nocopy clob_tab) 
  as
    l_column_name varchar2(30);
  begin
    for i in 1 .. p_cur_desc.count loop
      if i = 1 then
        l_column_name := c_row_template;
      else
        l_column_name := p_cur_desc(i).col_name;
      end if;
      
      -- Aktuellen Spaltenwerte auslesen
      if p_cur_desc(i).col_type = c_date_type then
        dbms_sql.column_value(p_cur, i, l_ref_rec.r_date);
        p_clob_tab(l_column_name) := to_char(l_ref_rec.r_date, g_default_date_format);
      else
        dbms_sql.column_value(p_cur, i, p_clob_tab(l_column_name));
      end if;
    end loop;
  end copy_values;
  

  /* Prozedur zum Kopieren einer Zeile in die vorbereitete PL/SQL-Tabelle
   * %param  p_cur       ID des Cursor
   * %param  p_cur_desc  DBMS_SQL.DESC_TAB2 mit den Details zu einem Cursor
   * %param [p_clob_tab] PL/SQL-Tabelle mit dem Spaltennamen (KEY) und 
   *                     einem initialen NULL-Wert fuer jede Spalte des Cursors
   * %param [p_row_tab]  Liste von Instanzen clob_tab, fuer jede Zeile der
   *                     Ergebnismenge des Cursors
   * %usage  Wird verwendet, alle Zeilen eines Cursor in eine Liste aus 
   *         vorbereiteten PL/SQL-Tabellen zu uebernehmen
   */
  procedure copy_values(
    p_cur in integer,
    p_cur_desc in dbms_sql.desc_tab2,
    p_clob_tab in out nocopy clob_tab,
    p_row_tab in out nocopy row_tab) 
  as
  begin
    while dbms_sql.fetch_rows(p_cur) > 0 loop
      copy_values(
        p_cur => p_cur,
        p_cur_desc => p_cur_desc,
        p_clob_tab => p_clob_tab);
    
      p_row_tab(dbms_sql.last_row_count) := p_clob_tab;
    end loop;
  end copy_values;


  /* Prozedur zum Kopieren einer Ergebnismenge einer SQL-Anweisung in eine Liste
   * von KEY-VALUE-Tabellen. Jeder Eintrag der Tabelle enthaelt eine KEY-VALUE-Tabelle
   * gem. COPY_ROW_TO_clob_tab. Die Ergebnisliste ist INDEX BY BINARY_INTEGER.
   * %param  p_cursor   Geoeffneter Cursor, der mehr als eine Zeile liefern kann
   * %param  p_row_tab  PL/SQL-Tabelle, die in jedem Eintrag eine PL/SQL-Tabelle mit#
   *                    KEY-VALUE-Paaren gem. COPY_ROW_TO_clob_tab enthaelt
   * %usage Wird verwendet, um eine Liste von merhreren Ersetzungsankern in einem
   *        Durchgang in eine doppelte KEY-VALUE-Tabelle zu konvertieren.
   */
  procedure copy_table_to_row_tab(
    p_cursor in out nocopy sys_refcursor,
    p_row_tab in out nocopy row_tab) 
  as
    l_cur integer;
    l_cur_desc dbms_sql.desc_tab2;
    l_clob_tab clob_tab;
  begin
    describe_cursor(
      p_cursor => p_cursor,
      p_cur => l_cur,
      p_cur_desc => l_cur_desc,
      p_clob_tab => l_clob_tab);
  
    copy_values(
      p_cur => l_cur,
      p_cur_desc => l_cur_desc,
      p_clob_tab => l_clob_tab,
      p_row_tab => p_row_tab);
  
    dbms_sql.close_cursor(l_cur);
  end copy_table_to_row_tab;
  
  
  /* Hilfsfunktion zur Ermittlung des aktuellen Trennzeichens
   * %param  p_delimiter  Uebergebenes Trennzeichen
   * %return Trennzeichen, das aktuell verwendet werden soll
   */
  function get_delimiter(
    p_delimiter in varchar2)
    return varchar2
  as
    l_delimiter varchar2(100);
  begin
    case 
    when p_delimiter = c_no_delimiter then
      l_delimiter := null;
    when p_delimiter is null then
      l_delimiter := g_default_delimiter_char;
    else
      l_delimiter := p_delimiter;
    end case;
    
    return l_delimiter;
  end get_delimiter;


  /* Prozedur zum Ersetzen aller Ersetzungsanker einer PL/SQL-Tabelle in einem Template
   * %param  p_template       Template mit Ersetzungsankern. Syntax der Ersetzungsanker:
   *                          #<Name des Ersetzungsankers, muss Tabellenspalte entsprechen>
   *                          |<Praefix, falls Wert not null>
   *                          |<Postfix, falls Wert not null>
   *                          |<Wert, falls NULL>#
   *                          Alle PIPE-Zeichen und Klauseln sind optional, muessen aber, wenn sie 
   *                          verwendet werden, in dieser Reihenfolge eingesetzt werden.
   *                          NB: Das Trennzeichen # entspricht g_main_anchor_char
   *                          Beispiel: #VORNAME||, |# => Falls vorhanden wird hinter dem Vornamen ein Komma eingefuegt
   * %param  p_clob_tab  Tabelle von KEY-VALUE-Paaren, erzeugt ueber COPY_ROW_TO_clob_tab
   * %param  p_result         Ergebnis der Umwandlung
   * %usage  Der Prozedur werden ein Template und eine aufbereitete Liste von Ersetzungsankern und
   *         Ersetzungswerten uebergeben. Die Methode ersetzt alle Anker im Template durch
   *         die Ersetzungswerte in der PL/SQL-Tabelle und analysiert dabei NULL-Werte,
   *         um diese durch die Ersatzwerte zu ersetzen. Ist der Wert nicht NULL, werden
   *         PRE-und POSTFIX-Werte eingefuegt, falls im Ersetzungsanker definiert.
   */
  procedure bulk_replace(
    p_template in clob default null,
    p_clob_tab in clob_tab,
    p_result out nocopy clob) 
  as
    c_regex varchar2(20) := replace('\#A#[A-Z0-9].*?\#A#', '#A#', g_main_anchor_char);
    c_regex_anchor varchar2(20) := '[^\' || g_main_separator_char || ']+';
    c_regex_separator varchar2(20) := '(.*?)(\' || g_main_separator_char || '|$)';
      
    /* SQL-Anweisung, um generisch aus einem Template alle Ersetzungsanker auszulesen und 
     * optionale Pre- und Postfixe sowie Ersatzwerte fuer NULL zu ermitteln
     */
    cursor replacement_cur(p_template in varchar2) is
        with anchors as (
                select trim(g_main_anchor_char from regexp_substr(p_template, c_regex, 1, level)) replacement_string
                  from dual
               connect by level <= regexp_count(p_template, '\' || g_main_anchor_char) / 2),
             parts as(
             select g_main_anchor_char || replacement_string || g_main_anchor_char as replacement_string,
                    upper(regexp_substr(replacement_string, c_regex_anchor, 1, 1)) anchor,
                    regexp_substr(replacement_string, c_regex_separator, 1, 2, null, 1) prefix,
                    regexp_substr(replacement_string, c_regex_separator, 1, 3, null, 1) postfix,
                    regexp_substr(replacement_string, c_regex_separator, 1, 4, null, 1) null_value
               from anchors)
      select replacement_string, anchor, prefix, postfix, null_value, 
             case when regexp_instr(anchor, c_regex_anchor_name) > 0 then 1 else 0 end valid_anchor_name
        from parts
       where anchor is not null;
  
    l_anchor_value clob;
    l_missing_anchors varchar2(32767);
    l_invalid_anchors varchar2(32767);
  begin
    $IF CODE_GENERATOR.C_WITH_PIT $THEN
    pit.assert_not_null(
      p_condition => p_template,
      p_message_name => msg.NO_TEMPLATE);
    $ELSE
    if p_template is null then
      raise_application_error(-20000, 'Template must not be null');
    end if;
    $END
      
    -- Template auf Ergebnis umkopieren, um Rekursion durchfuehren zu koennen
    p_result := p_template;
  
    -- Zeichenfolgen ersetzen. Ersetzungen koennen wiederum Ersetzungsanker enthalten
    for rep in replacement_cur(p_template) loop
      case
      when rep.valid_anchor_name = 0 then
        l_invalid_anchors := l_invalid_anchors || g_main_separator_char || rep.anchor;
      when p_clob_tab.exists(rep.anchor) then
        l_anchor_value := p_clob_tab(rep.anchor);
        if l_anchor_value is not null then
          p_result := replace(p_result, rep.replacement_string, rep.prefix || l_anchor_value || rep.postfix);
        else
          p_result := replace(p_result, rep.replacement_string, rep.null_value);
        end if;
      else
        -- Ersetzungszeichenfolge ist in Ersetzungsliste nicht enthalten
        l_missing_anchors := l_missing_anchors || g_main_separator_char || rep.anchor;
        null;
      end case;
    end loop;
  
    if l_invalid_anchors is not null then
      $IF CODE_GENERATOR.C_WITH_PIT $THEN
      pit.error(
        msg.INVALID_ANCHOR_NAMES,
        msg_args(l_invalid_anchors));
      $ELSE
      raise_application_error(-20001, 'The following anchors are not conforming to the naming rules: ' || l_invalid_anchors); 
      $END
    end if;
    
    if l_missing_anchors is not null and not g_ignore_missing_anchors then
      l_missing_anchors := ltrim(l_missing_anchors, g_main_separator_char);
      $IF CODE_GENERATOR.C_WITH_PIT $THEN
      pit.error(
        msg.MISSING_ANCHORS,
        msg_args(l_missing_anchors));
      $ELSE
      raise_application_error(-20002, 'The following anchors are missing: ' || l_missing_anchors); 
      $END
    end if;
  
    -- Rekursiver Aufruf, falls Ersetzungen wiederum Anker beinhalten,
    -- bisheriges Ergebnis dient als Template fuer den rekursiven Aufruf
    -- Hierfuer geschachtelte sekundaere Ersetzungstzeichen durch primaeres ersetzen
    if p_template != p_result then
      bulk_replace(
        p_template => replace(replace(p_result, 
                        g_secondary_anchor_char, g_main_anchor_char), 
                        g_secondary_separator_char, g_main_separator_char),
        p_clob_tab => p_clob_tab,
        p_result => p_result);
    end if;
  end bulk_replace;


  -- %param p_row_tab Liste mit Tabelle von KEY-VALUE-Paaren, erzeugt ueber COPY_TABLE_TO_ROW_TAB
  procedure bulk_replace(
    p_row_tab in row_tab,
    p_delimiter in varchar2,
    p_indent in number,
    p_result out nocopy clob) 
  as
    l_result clob;
    l_template clob;
    l_log_message clob;
    l_clob_tab clob_tab;
    l_delimiter g_default_delimiter_char%type;
    l_indent varchar2(1000);
  begin
    l_delimiter := get_delimiter(p_delimiter);
    
    if p_row_tab.count > 0 then
      dbms_lob.createtemporary(p_result, false, dbms_lob.call);
      
      for i in 1 .. p_row_tab.count loop
        l_clob_tab := p_row_tab(i);
        l_template := l_clob_tab(c_row_template);
        
        bulk_replace(
          p_template => l_template,
          p_clob_tab => l_clob_tab,
          p_result => l_result);
      
        -- Falls vorhanden, Logging durchfuehren
        if l_clob_tab.exists(c_log_template) and l_clob_tab(c_log_template) is not null then
          bulk_replace(
            p_template => l_clob_tab(c_log_template),
            p_clob_tab => l_clob_tab,
            p_result => l_log_message);   
          
          $IF CODE_GENERATOR.C_WITH_PIT $THEN
          pit.log(msg.LOG_CONVERSION, msg_args(l_log_message));
          $ELSE
          dbms_output.put_line(l_log_message);
          $END
        end if;
        
        if i < p_row_tab.last then
          l_result := l_result || l_delimiter;
        end if;
      
        dbms_lob.append(p_result, l_result);
      end loop;
    end if;
    
    -- gesamtes Ergebnis um P_INDENT Zeichen einruecken
    if p_indent > 0 then
      l_indent := l_delimiter || rpad(' ', p_indent, ' ');
      p_result := replace(p_result, l_delimiter, l_indent);
    end if;
    
  end bulk_replace;


  -- %param  p_result  Ausgabeparameter vom Typ CLOB_TABLE
  procedure bulk_replace(
    p_row_tab in row_tab,
    p_delimiter in varchar2,
    p_result out nocopy clob_table) 
  as
    l_result clob;
    l_template clob;
    l_log_message clob;
    l_clob_tab clob_tab;
    l_delimiter g_default_delimiter_char%type;
  begin
    -- Initialisierung
    p_result := clob_table();
    l_delimiter := get_delimiter(p_delimiter);
    
    for i in 1 .. p_row_tab.count loop
      l_clob_tab := p_row_tab(i);
    
      l_template := l_clob_tab(c_row_template); 
    
      bulk_replace(
        p_template => l_template,
        p_clob_tab => l_clob_tab,
        p_result => l_result);
    
      if l_clob_tab.exists(c_log_template) and l_clob_tab(c_log_template) is not null then
        bulk_replace(
          p_template => l_clob_tab(c_log_template),
          p_clob_tab => l_clob_tab,
          p_result => l_log_message);
                  
          
        $IF CODE_GENERATOR.C_WITH_PIT $THEN
        pit.log(msg.LOG_CONVERSION, msg_args(l_log_message));
        $ELSE
        dbms_output.put_line(l_log_message);
        $END
      end if;
      
      if i < p_row_tab.last then
        l_result := l_result || l_delimiter;
      end if;
    
      p_result.extend;
      p_result(p_result.count) := l_result;
    end loop;
  end bulk_replace;
  

  /* Initialisierungsprozedur des Packages */
  procedure initialize 
  as
  begin
    $IF CODE_GENERATOR.C_WITH_PIT $THEN
    g_ignore_missing_anchors := param.get_boolean(
                                  p_par_id => 'IGNORE_MISSING_ANCHORS',
                                  p_pgr_id => c_param_group);
    g_default_delimiter_char := param.get_string(
                                  p_par_id => 'DEFAULT_DELIMITER_CHAR',
                                  p_pgr_id => c_param_group);
    g_default_date_format := param.get_string(
                               p_par_id => 'DEFAULT_DATE_FORMAT',
                               p_pgr_id => c_param_group);
    g_main_anchor_char := param.get_string(
                            p_par_id => 'MAIN_ANCHOR_CHAR',
                            p_pgr_id => c_param_group);
    g_secondary_anchor_char := param.get_string(
                                 p_par_id => 'SECONDARY_ANCHOR_CHAR',
                                 p_pgr_id => c_param_group);
    g_main_separator_char := param.get_string(
                               p_par_id => 'MAIN_SEPARATOR_CHAR',
                               p_pgr_id => c_param_group);
    g_secondary_separator_char := param.get_string(
                                    p_par_id => 'SECONDARY_SEPARATOR_CHAR',
                                    p_pgr_id => c_param_group);
    $ELSE
    g_ignore_missing_anchors := true;
    g_default_delimiter_char := chr(10);
    g_default_date_format := 'yyyy-mm-dd hh24:mi:ss';
    g_main_anchor_char := '#';
    g_secondary_anchor_char := '^';
    g_main_separator_char := '|';
    g_secondary_separator_char := '~';
    $END
  end initialize;


  /* INTERFACE*/
  /* GET/SET-Methoden */
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
  
  
  procedure set_default_delimiter_char(
    p_delimiter in varchar2)
  as
  begin
    g_default_delimiter_char := p_delimiter;
  end set_default_delimiter_char;

  function get_default_delimiter_char
    return varchar2
  as
  begin
    return g_default_delimiter_char;
  end get_default_delimiter_char;
  
  
  
  procedure set_main_anchor_char(p_char in varchar2) as
  begin
    g_main_anchor_char := p_char;
  end set_main_anchor_char;

  function get_main_anchor_char return varchar2 as
  begin
    return g_main_anchor_char;
  end get_main_anchor_char;
  

  procedure set_secondary_anchor_char(p_char in varchar2) as
  begin
    g_secondary_anchor_char := p_char;
  end set_secondary_anchor_char;

  function get_secondary_anchor_char return varchar2 as
  begin
    return g_secondary_anchor_char;
  end get_secondary_anchor_char;
  
  
  procedure set_main_separator_char(
    p_char in varchar2)
  as
  begin
    g_main_separator_char := p_char;
  end set_main_separator_char;
  
  function get_main_separator_char 
    return varchar2
  as
  begin
    return g_main_separator_char;
  end get_main_separator_char;
    
    
  procedure set_secondary_separator_char(
    p_char in varchar2)
  as
  begin
    g_secondary_separator_char := p_char;
  end set_secondary_separator_char;
  
  function get_secondary_separator_char 
    return varchar2
  as
  begin
    return g_secondary_separator_char;
  end get_secondary_separator_char;
  

  procedure set_default_date_format(p_format in varchar2) as
  begin
    g_default_date_format := p_format;
  end set_default_date_format;

  function get_default_date_format return varchar2 as
  begin
    return g_default_date_format;
  end get_default_date_format;
  
  
  /* BULK_REPLACE */
  function bulk_replace(
    p_template in clob,
    p_chunks in char_table
  ) return clob
  as
    l_clob_tab clob_tab;
    l_result clob;
  begin
    for i in 1 .. p_chunks.count loop
      if mod(i, 2) = 1 then
        l_clob_tab(replace(p_chunks(i), g_main_anchor_char)) := p_chunks(i + 1);
      end if;
    end loop;
    
    bulk_replace(
      p_template => p_template,
      p_clob_tab => l_clob_tab,
      p_result => l_result);
      
    return l_result;
  end bulk_replace;
  
  
  /* GENERATE_TEXT */
  procedure generate_text(
    p_cursor in out nocopy sys_refcursor,
    p_result out nocopy varchar2,
    p_delimiter in varchar2 default null,
    p_indent in number default 0) 
  as
    l_row_tab row_tab;
  begin
    $IF CODE_GENERATOR.C_WITH_PIT $THEN
    pit.assert(
      p_condition => (p_delimiter = c_no_delimiter and p_indent = 0) or (p_delimiter != c_no_delimiter),
      p_message_name => msg.INVALID_PARAMETER_COMBI);
    $ELSE
    if not((p_delimiter = c_no_delimiter and p_indent = 0) or (p_delimiter != c_no_delimiter)) then
      raise_application_error(-20003, 'Indenting is allowed only if a delimiter is present.');
    end if;
    $END
    
    copy_table_to_row_tab(
      p_cursor => p_cursor,
      p_row_tab => l_row_tab);
  
    bulk_replace(
      p_row_tab => l_row_tab,
      p_delimiter => p_delimiter,
      p_result => p_result,
      p_indent => p_indent);
  end generate_text;


  -- Ueberladung als Funktion
  function generate_text(
    p_cursor in sys_refcursor,
    p_delimiter in varchar2 default null,
    p_indent in number default 0) 
    return clob 
  as
    l_clob clob;
    l_cur sys_refcursor := p_cursor;
  begin
    generate_text(
      p_cursor => l_cur,
      p_result => l_clob,
      p_delimiter => p_delimiter,
      p_indent => p_indent);
    return l_clob;
  end generate_text;


  /* GENERATE_TEXT_TABLE */
  procedure generate_text_table(
    p_cursor in out nocopy sys_refcursor,
    p_result out nocopy clob_table)
  as
    l_row_tab row_tab;
  begin
    copy_table_to_row_tab(
      p_cursor => p_cursor,
      p_row_tab => l_row_tab);
  
    bulk_replace(
      p_row_tab => l_row_tab,
      p_delimiter => null,
      p_result => p_result);
  end generate_text_table;
  
  
  -- Ueberladung als Funktion
  function generate_text_table(
    p_cursor in sys_refcursor) 
    return clob_table
    pipelined
  as
    l_clob_table clob_table;
    l_cur sys_refcursor := p_cursor;
  begin
    generate_text_table(
        p_cursor    => l_cur,
        p_result    => l_clob_table);
        
    for i in 1 .. l_clob_table.count loop
      if dbms_lob.getlength(l_clob_table(i)) > 0 then
        pipe row (l_clob_table(i));
      end if;
    end loop;
    return;
  end generate_text_table;
  
                  
  function get_anchors(
    p_tmplate_name in varchar2,
    p_template_type in varchar2,
    p_template_mode in varchar2,
    p_with_replacements in number default 0
  ) return char_table
    pipelined
  as
    c_regex_anchor_complete constant varchar2(100) := '\#A#[A-Z0-9_\$\#S#].*?\#A#';
    c_regex_anchor_only constant varchar2(100) := '\#A#[A-Z0-9_\$].*?(\#S#|\#A#)';
    
    l_regex varchar2(200);
    l_retval char_table;
    l_template code_generator_templates.cgtm_text%type;
    l_str varchar2(50 char);
    l_cnt pls_integer := 1;
  begin
    select cgtm_text
      into l_template
      from code_generator_templates
     where cgtm_name = upper(p_tmplate_name)
       and cgtm_type = upper(p_template_type)
       and cgtm_mode = upper(p_template_mode);
       
    -- Template gefunden, initialisieren
    case when p_with_replacements = 1 then
      l_regex := c_regex_anchor_complete;
    else
      l_regex := c_regex_anchor_only;
    end case;
    l_regex := replace(replace(l_regex, '#A#', g_main_anchor_char), '#S#', g_main_separator_char);
    
    -- Anker finden und aufbereiten
    loop
      l_str := regexp_substr(l_template, l_regex, 1, l_cnt);
      if l_str is not null then
        if p_with_replacements = 0 then
          l_str := replace(replace(l_str, g_main_anchor_char), g_main_separator_char);
        end if;
        l_cnt := l_cnt + 1;
        
        pipe row (l_str);
      else
        exit;
      end if;
    end loop;
    
    return;
  end get_anchors;

begin
  initialize;
end code_generator;
/
