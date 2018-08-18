create or replace package body code_generator 
as
  subtype ora_name_type is &ORA_NAME_TYPE.;
  subtype flag_type is char(1 char);
  subtype max_char is varchar2(32767 byte);
  
  C_PKG constant ora_name_type := $$PLSQL_UNIT;
  C_ROW_TEMPLATE constant ora_name_type := 'TEMPLATE';
  C_LOG_TEMPLATE constant ora_name_type := 'LOG_TEMPLATE';
  C_DATE_TYPE constant binary_integer := 12;
  C_PARAM_GROUP constant ora_name_type := 'CODE_GEN';
  -- Ersetzungszeichen beim Ex- und Import zum Maskieren von Zeilenspruengen
  C_CR_CHAR constant varchar2(10) := '\CR\';
  
  C_REGEX_ANCHOR_NAME constant varchar2(50) := q'^(^[0-9]+$|^[A-Z][A-Z0-9_\$#]+$)^';
  C_REGEX_INTERNAL_ANCHORS constant varchar2(100) := '(#CGTM_NAME#|#CGTM_TYPE#|#CGTM_MODE#|#CGTM_TEXT#|#CGTM_LOG_TEXT#|#CGTM_LOG_SEVERITY#)';
  
  g_ignore_missing_anchors boolean;
  g_default_date_format varchar2(200);
  g_default_delimiter_char varchar2(100);
  g_main_anchor_char flag_type;
  g_secondary_anchor_char flag_type;
  g_main_separator_char flag_type;
  g_secondary_separator_char flag_type;
  g_newline_char varchar2(2 byte);

  /* DATENTYPEN */
  type clob_tab is table of clob index by ora_name_type;
  type row_tab is table of clob_tab index by binary_integer;
  
  -- Record mit Variablen fuer Ergebnisspaltenwerte
  type ref_rec_type is record(
    r_string max_char,
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
    p_cur out nocopy binary_integer,
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
    p_cur in binary_integer,
    p_cur_desc in out nocopy dbms_sql.desc_tab2,
    p_clob_tab in out nocopy clob_tab) 
  as
    l_column_name ora_name_type;
    l_column_count binary_integer := 1;
    l_column_type binary_integer;
    l_cnt binary_integer := 0;
  begin
    dbms_sql.describe_columns2(
      c => p_cur,
      col_cnt => l_column_count,
      desc_t => p_cur_desc);
                              
    for i in 1 .. l_column_count loop
      if i = 1 then
        l_column_name := C_ROW_TEMPLATE;
      else
        l_column_name := p_cur_desc(i).col_name;
      end if;
      
      l_column_type := p_cur_desc(i).col_type;
      
      -- Spalte als leeren Wert in der PL/SQL-Tabelle anlegen, um ihn als Variable
      -- referenzieren zu koennen
      l_cnt := l_cnt + 1;
      p_clob_tab(l_column_name) := null;
      
      -- Registriere Variable als Ausgabevariable dieser Spalte
      if l_column_type = C_DATE_TYPE then
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
    p_cur in out nocopy binary_integer,
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
    p_cur in binary_integer,
    p_cur_desc in dbms_sql.desc_tab2,
    p_clob_tab in out nocopy clob_tab) 
  as
    l_column_name ora_name_type;
  begin
    for i in 1 .. p_cur_desc.count loop
      if i = 1 then
        l_column_name := C_ROW_TEMPLATE;
      else
        l_column_name := p_cur_desc(i).col_name;
      end if;
      
      -- Aktuellen Spaltenwerte auslesen
      if p_cur_desc(i).col_type = C_DATE_TYPE then
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
    l_cur binary_integer;
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
    l_delimiter g_default_delimiter_char%type;
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
    C_REGEX varchar2(20) := replace('\#A#[A-Z0-9].*?\#A#', '#A#', g_main_anchor_char);
    C_REGEX_ANCHOR varchar2(20) := '[^\' || g_main_separator_char || ']+';
    C_REGEX_SEPARATOR varchar2(20) := '(.*?)(\' || g_main_separator_char || '|$)';
      
    /* SQL-Anweisung, um generisch aus einem Template alle Ersetzungsanker auszulesen und 
     * optionale Pre- und Postfixe sowie Ersatzwerte fuer NULL zu ermitteln
     */
    cursor replacement_cur(p_template in varchar2) is
        with anchors as (
                select trim(g_main_anchor_char from regexp_substr(p_template, C_REGEX, 1, level)) replacement_string
                  from dual
               connect by level <= regexp_count(p_template, '\' || g_main_anchor_char) / 2),
             parts as(
             select g_main_anchor_char || replacement_string || g_main_anchor_char as replacement_string,
                    upper(regexp_substr(replacement_string, C_REGEX_ANCHOR, 1, 1)) anchor,
                    regexp_substr(replacement_string, C_REGEX_SEPARATOR, 1, 2, null, 1) prefix,
                    regexp_substr(replacement_string, C_REGEX_SEPARATOR, 1, 3, null, 1) postfix,
                    regexp_substr(replacement_string, C_REGEX_SEPARATOR, 1, 4, null, 1) null_value
               from anchors)
      select replacement_string, anchor, prefix, postfix, null_value, 
             case when regexp_instr(anchor, C_REGEX_ANCHOR_NAME) > 0 then 1 else 0 end valid_anchor_name
        from parts
       where anchor is not null;
  
    l_anchor_value clob;
    l_missing_anchors max_char;
    l_invalid_anchors max_char;
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
  
    if l_invalid_anchors is not null and not g_ignore_missing_anchors then
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
      -- Intern verwendete Anker entfernen, um inifinte loops zu vermeiden
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
        l_template := l_clob_tab(C_ROW_TEMPLATE);
        
        bulk_replace(
          p_template => l_template,
          p_clob_tab => l_clob_tab,
          p_result => l_result);
      
        -- Falls vorhanden, Logging durchfuehren
        if l_clob_tab.exists(C_LOG_TEMPLATE) and l_clob_tab(C_LOG_TEMPLATE) is not null then
          bulk_replace(
            p_template => l_clob_tab(C_LOG_TEMPLATE),
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
    
      l_template := l_clob_tab(C_ROW_TEMPLATE); 
    
      bulk_replace(
        p_template => l_template,
        p_clob_tab => l_clob_tab,
        p_result => l_result);
    
      if l_clob_tab.exists(C_LOG_TEMPLATE) and l_clob_tab(C_LOG_TEMPLATE) is not null then
        bulk_replace(
          p_template => l_clob_tab(C_LOG_TEMPLATE),
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
                                  p_pgr_id => C_PARAM_GROUP);
    g_default_delimiter_char := param.get_string(
                                  p_par_id => 'DEFAULT_DELIMITER_CHAR',
                                  p_pgr_id => C_PARAM_GROUP);
    g_default_date_format := param.get_string(
                               p_par_id => 'DEFAULT_DATE_FORMAT',
                               p_pgr_id => C_PARAM_GROUP);
    g_main_anchor_char := param.get_string(
                            p_par_id => 'MAIN_ANCHOR_CHAR',
                            p_pgr_id => C_PARAM_GROUP);
    g_secondary_anchor_char := param.get_string(
                                 p_par_id => 'SECONDARY_ANCHOR_CHAR',
                                 p_pgr_id => C_PARAM_GROUP);
    g_main_separator_char := param.get_string(
                               p_par_id => 'MAIN_SEPARATOR_CHAR',
                               p_pgr_id => C_PARAM_GROUP);
    g_secondary_separator_char := param.get_string(
                                    p_par_id => 'SECONDARY_SEPARATOR_CHAR',
                                    p_pgr_id => C_PARAM_GROUP);
    $ELSE
    g_ignore_missing_anchors := true;
    g_default_delimiter_char := chr(10);
    g_default_date_format := 'yyyy-mm-dd hh24:mi:ss';
    g_main_anchor_char := '#';
    g_secondary_anchor_char := '^';
    g_main_separator_char := '|';
    g_secondary_separator_char := '~';
    $END
    
    -- Absatzzeichen aus OS ableiten
    case when regexp_like(dbms_utility.port_string, '(WIN|Windows)') then
      g_newline_char := chr(13) || chr(10);
    when regexp_like(dbms_utility.port_string, '(AIX)') then
      g_newline_char := chr(21);
    else
      g_newline_char := chr(10);
    end case;
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
  
  
  procedure set_newline_char(
    p_char in varchar2)
  as
  begin
    g_newline_char := p_char;
  end set_newline_char;
  

  function get_newline_char
    return varchar2
  as
  begin
    return g_newline_char;
  end get_newline_char;
    
  
  /* WRAP_STRING */
  function wrap_string(
    p_string in varchar2,
    p_prefix in varchar2 default q'^q'°^',
    p_postfix in varchar2 default q'^°'^')
    return varchar2
  as
    C_REGEX_newline constant varchar2(30) := '(' || chr(13) || chr(10) || '|' || chr(10) || '|' || chr(13) || ' |' || chr(21) || ')';
    c_replacement constant varchar2(100) := C_CR_CHAR || p_postfix || ' || ' || g_newline_char || p_prefix;
  begin
    return p_prefix || regexp_replace(p_string, C_REGEX_newline, c_replacement) || p_postfix;
  end wrap_string;
  
  
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
    p_cgtm_name in varchar2,
    p_cgtm_type in varchar2,
    p_cgtm_mode in varchar2,
    p_with_replacements in number default 0
  ) return char_table
    pipelined
  as
    C_REGEX_ANCHOR_complete constant varchar2(100) := '\#A#[A-Z0-9_\$\#S#].*?\#A#';
    C_REGEX_ANCHOR_only constant varchar2(100) := '\#A#[A-Z0-9_\$].*?(\#S#|\#A#)';
    
    l_regex varchar2(200);
    l_retval char_table;
    l_template code_generator_templates.cgtm_text%type;
    l_str varchar2(50 char);
    l_cnt pls_integer := 1;
  begin
    select cgtm_text
      into l_template
      from code_generator_templates
     where cgtm_name = upper(p_cgtm_name)
       and cgtm_type = upper(p_cgtm_type)
       and cgtm_mode = upper(p_cgtm_mode);
       
    -- Template gefunden, initialisieren
    case when p_with_replacements = 1 then
      l_regex := C_REGEX_ANCHOR_complete;
    else
      l_regex := C_REGEX_ANCHOR_only;
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
    
  procedure merge_template(
    p_cgtm_name in varchar2,
    p_cgtm_type in varchar2,
    p_cgtm_mode in varchar2,
    p_cgtm_text in varchar2,
    p_cgtm_log_text in varchar2,
    p_cgtm_log_severity in number) 
  as
  begin
    merge into code_generator_templates t
    using (select p_cgtm_name cgtm_name,
                  p_cgtm_type cgtm_type,
                  p_cgtm_mode cgtm_mode,
                  replace(p_cgtm_text, C_CR_CHAR, g_newline_char) cgtm_text,
                  p_cgtm_log_text cgtm_log_text,
                  p_cgtm_log_severity cgtm_log_severity
             from dual) s
       on (t.cgtm_name = s.cgtm_name
       and t.cgtm_type = s.cgtm_type
       and t.cgtm_mode = s.cgtm_mode)
     when matched then update set
            t.cgtm_text = s.cgtm_text,
            t.cgtm_log_text = s.cgtm_log_text,
            t.cgtm_log_severity = s.cgtm_log_severity
     when not matched then insert(
            t.cgtm_name, t.cgtm_type, t.cgtm_mode, t.cgtm_text, t.cgtm_log_text, t.cgtm_log_severity)
          values(
            s.cgtm_name, s.cgtm_type, s.cgtm_mode, s.cgtm_text, s.cgtm_log_text, s.cgtm_log_severity);
    
  end merge_template;


  procedure write_template_file(
    p_directory in varchar2 := 'DATA_DIR')
  as
    c_file_name constant varchar2(30) := 'templates.sql';
  begin
    $IF dbms_db_version.ver_le_12_1 $THEN
    dbms_xslprocessor.clob2file(get_templates, p_directory, c_file_name);
    $ELSE
    dbms_lob.clob2file(get_templates, p_directory, c_file_name);
    $END
  end write_template_file;
    
  
  function get_templates
    return clob
  as
    c_cgtm_name constant varchar2(30) := 'EXPORT';
    c_cgtm_type constant varchar2(30) := 'INTERNAL';
    l_script clob;
  begin
    select code_generator.generate_text(cursor(
             select cgtm_text template,
                    g_newline_char cr,
                    code_generator.generate_text(cursor(
                      select t.cgtm_text template,
                             d.cgtm_name, d.cgtm_type, d.cgtm_mode,
                             code_generator.wrap_string(d.cgtm_text) cgtm_text,
                             code_generator.wrap_string(d.cgtm_log_text) cgtm_log_text,
                             d.cgtm_log_severity
                        from code_generator_templates d
                       cross join (
                             select cgtm_text
                               from code_generator_templates
                              where cgtm_name = c_cgtm_name
                                and cgtm_type = c_cgtm_type
                                and cgtm_mode = 'METHODS') t
                       where cgtm_type != c_cgtm_type
                    ), g_newline_char || g_newline_char) methods
               from code_generator_templates d
              where cgtm_name = c_cgtm_name
                and cgtm_type = c_cgtm_type
                and cgtm_mode = 'FRAME'
             )
           ) resultat
      into l_script
      from dual;
      
    return l_script;
  end get_templates;
  
begin
  initialize;
end code_generator;
/
