create or replace package body code_generator as

  c_row_template           constant varchar2(30) := '$$ROW_TEMPLATE';
  c_date_type              constant binary_integer := 12;
  c_anchor_delimiter       constant char(1 byte) := '|';
  g_ignore_missing_anchors boolean;
  g_default_date_format    varchar2(200);
  g_main_anchor_char       char(1 char);
  g_secondary_anchor_char  char(1 char);

  /* DATENTYPEN */
  type key_value_tab is table of clob index by varchar2(30);
  type row_tab is table of key_value_tab index by binary_integer;
  
  -- Record mit Variablen fuer Ergebnisspaltenwerte
  type ref_rec_type is record(
    r_string varchar2(32767),
    r_date   date,
    r_clob   clob);
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
    p_cur    out integer,
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
    p_cur                      in integer,
    p_cur_desc                 in out nocopy dbms_sql.desc_tab2,
    p_key_value_tab            in out nocopy key_value_tab,
    p_first_column_is_template boolean default false) 
  as
    l_column_name  varchar2(30);
    l_column_count integer := 1;
    l_column_type  integer;
    l_cnt          binary_integer := 0;
  begin
    dbms_sql.describe_columns2(
      c => p_cur,
      col_cnt => l_column_count,
      desc_t => p_cur_desc);
                              
    for i in 1 .. l_column_count loop
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
    p_stmt                     in clob,
    p_cur                      in out nocopy integer,
    p_cur_desc                 in out nocopy dbms_sql.desc_tab2,
    p_key_value_tab            in out nocopy key_value_tab,
    p_first_column_is_template boolean default false) 
  as
    l_ignore integer;
  begin
    open_cursor(p_cur);
    
    dbms_sql.parse(p_cur, 'select * from (' || p_stmt || ')', dbms_sql.native);
    l_ignore := dbms_sql.execute(p_cur);
    
    describe_columns(p_cur
                    ,p_cur_desc
                    ,p_key_value_tab
                    ,p_first_column_is_template);
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
    p_cursor                   in out nocopy sys_refcursor,
    p_cur                      in out nocopy integer,
    p_cur_desc                 in out nocopy dbms_sql.desc_tab2,
    p_key_value_tab            in out nocopy key_value_tab,
    p_first_column_is_template boolean default false) 
  as
  begin
    open_cursor(p_cur    => p_cur
               ,p_cursor => p_cursor);
  
    describe_columns(p_cur                      => p_cur
                    ,p_cur_desc                 => p_cur_desc
                    ,p_key_value_tab            => p_key_value_tab
                    ,p_first_column_is_template => p_first_column_is_template);
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
    p_cur                      in integer,
    p_cur_desc                 in dbms_sql.desc_tab2,
    p_key_value_tab            in out nocopy key_value_tab,
    p_first_column_is_template boolean default false) 
  as
    l_column_name varchar2(30);
  begin
    for i in p_cur_desc.first .. p_cur_desc.last loop
      if p_first_column_is_template and i = 1 then
        l_column_name := c_row_template;
      else
        l_column_name := p_cur_desc(i).col_name;
      end if;
      
      -- Aktuellen Spaltenwerte auslesen
      if p_cur_desc(i).col_type = c_date_type then
        dbms_sql.column_value(p_cur, i, l_ref_rec.r_date);
        p_key_value_tab(l_column_name) := to_char(l_ref_rec.r_date, g_default_date_format);
      else
        dbms_sql.column_value(p_cur, i, p_key_value_tab(l_column_name));
      end if;
    end loop;
  end copy_values;
  

  /* Prozedur zum Kopieren einer Zeile in die vorbereitete PL/SQL-Tabelle
   * %param  p_cur                       ID des Cursor
   * %param  p_cur_desc                  DBMS_SQL.DESC_TAB2 mit den Details zu einem Cursor
   * %param [p_key_value_tab]            PL/SQL-Tabelle mit dem Spaltennamen (KEY) und 
   *                                     einem initialen NULL-Wert fuer jede Spalte des Cursors
   * %param [p_row_tab]                  Liste von Instanzen KEY_VALUE_TAB, fuer jede Zeile der
   *                                     Ergebnismenge des Cursors
   * %param [p_first_column_is_template] Flag, das anzeigt, ob in der ersten Spalte
   *                                     das Template fuer diese Zeile uebergeben wird.
   * %usage Wird verwendet, alle Zeilen eines Cursor in eine Liste aus 
   *        vorbereiteten PL/SQL-Tabellen zu uebernehmen
   */
  procedure copy_values(
    p_cur                      in integer,
    p_cur_desc                 in dbms_sql.desc_tab2,
    p_key_value_tab            in out nocopy key_value_tab,
    p_row_tab                  in out nocopy row_tab,
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
   */
  procedure copy_table_to_row_tab(
    p_stmt                     in clob,
    p_row_tab                  in out nocopy row_tab,
    p_first_column_is_template boolean default false) 
  as
    l_cur           integer;
    l_cur_desc      dbms_sql.desc_tab2;
    l_key_value_tab key_value_tab;
  begin
    describe_cursor(
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
  
    dbms_sql.close_cursor(l_cur);
  end copy_table_to_row_tab;


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
   * %param  p_key_value_tab  Tabelle von KEY-VALUE-Paaren, erzeugt ueber COPY_ROW_TO_KEY_VALUE_TAB
   * %param  p_result         Ergebnis der Umwandlung
   * %param  p_indent         Code wird um P_INDENT Leerzeichen eingerueckt
   * %usage  Der Prozedur werden ein Template und eine aufbereitete Liste von Ersetzungsankern und
   *         Ersetzungswerten uebergeben. Die Methode ersetzt alle Anker im Template durch
   *         die Ersetzungswerte in der PL/SQL-Tabelle und analysiert dabei NULL-Werte,
   *         um diese durch die Ersatzwerte zu ersetzen. Ist der Wert nicht NULL, werden
   *         PRE-und POSTFIX-Werte eingefuegt, falls im Ersetzungsanker definiert.
   */
  procedure bulk_replace(
    p_template      in clob,
    p_key_value_tab in key_value_tab,
    p_result        out clob,
    p_indent        in number) 
  as
    c_regex constant varchar2(20) := g_main_anchor_char || '.+?' || g_main_anchor_char;
    c_regex_anchor constant varchar2(20) := '[^|]+';
    c_regex_replacement constant varchar2(20) := '(.*?)(\||$)';
      
    /* SQL-Anweisung, um generisch aus einem Template alle Ersetzungsanker auszulesen und 
     * optionale Pre- und Postfixe sowie Ersatzwerte fuer NULL zu ermitteln
     */
    cursor replacement_cur(p_template in varchar2) is
        with anchors as (
                select trim(g_main_anchor_char from regexp_substr(p_template, c_regex, 1, level)) replacement_string
                  from dual
               connect by level <= regexp_count(p_template, g_main_anchor_char) / 2)
      select g_main_anchor_char || replacement_string || g_main_anchor_char as replacement_string,
             upper(regexp_substr(replacement_string, c_regex_anchor, 1, 1)) anchor,
             regexp_substr(replacement_string, c_regex_replacement, 1, 2, null, 1) prefix,
             regexp_substr(replacement_string, c_regex_replacement, 1, 3, null, 1) postfix,
             regexp_substr(replacement_string, c_regex_replacement, 1, 4, null, 1) null_value
        from anchors;
  
    l_anchor_value    clob;
    l_missing_anchors clob;
  begin
    msg_log.assert_not_null(
      p_condition => p_template,
      p_message_id => msg_pkg.no_template);
      
    -- Template auf Ergebnis umkopieren, um Rekursion durchfuehren zu koennen
    p_result := p_template;
  
    -- Zeichenfolgen ersetzen. Ersetzungen koennen wiederum Ersetzungsanker enthalten
    for rep in replacement_cur(p_template) loop
      if p_key_value_tab.exists(rep.anchor) then
        l_anchor_value := p_key_value_tab(rep.anchor);
        if l_anchor_value is not null then
          p_result := clob_replace(p_result, rep.replacement_string, rep.prefix || l_anchor_value || rep.postfix);
        else
          p_result := clob_replace(p_result, rep.replacement_string, rep.null_value);
        end if;
      else
        -- Ersetzungszeichenfolge ist in Ersetzungsliste nicht enthalten
        l_missing_anchors := l_missing_anchors || c_anchor_delimiter || rep.anchor;
      end if;
    end loop;
  
    if l_missing_anchors is not null and not g_ignore_missing_anchors then
      l_missing_anchors := ltrim(l_missing_anchors, c_anchor_delimiter);
      msg_log.error(
        msg_pkg.code_gen_missing_anchors,
        msg_args(l_missing_anchors));
    end if;
  
    -- Rekursiver Aufruf, falls Ersetzungen wiederum Anker beinhalten,
    -- bisheriges Ergebnis dient als Template fuer den rekursiven Aufruf
    -- Hierfuer geschachtelte sekundaere Ersetzungstzeichen durch primaeres ersetzen
    if p_template != p_result then
      bulk_replace(
        p_template => replace(p_result, g_secondary_anchor_char, g_main_anchor_char),
        p_key_value_tab => p_key_value_tab,
        p_result => p_result,
        p_indent => p_indent);
    else
      -- gesamtes Ergebnis um P_INDENT Zeichen einruecken
      if p_indent > 0 then
        p_result := clob_replace(p_result, chr(10), chr(10) || rpad(' ', p_indent, ' '));
      end if;
    end if;
  end bulk_replace;


  /* Ueberladung als Funktion */
  function bulk_replace(
    p_template      in clob,
    p_key_value_tab in key_value_tab,
    p_indent        in number) return clob 
  as
    l_result clob;
  begin
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
    if p_row_tab.count > 0 then
      l_template := p_template;
      dbms_lob.createtemporary(p_result, false, dbms_lob.call);
      
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
      
        dbms_lob.append(p_result, l_result);
      end loop;
    end if;
  end bulk_replace;


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
      end loop;
    else
      --      RAISE no_data_found;
      null;
    end if;
  end bulk_replace;


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
  

  /* Initialisierungsprozedur des Packages */
  procedure initialize as
  begin
    g_ignore_missing_anchors := true;
    g_default_date_format := 'dd.mm.yyyy hh24:mi:ss';
    g_main_anchor_char := '#';
    g_secondary_anchor_char := '^';
  end initialize;


  /* INTERFACE*/
  /* GET/SET-Methoden */
  procedure set_ignore_missing_anchors(p_flag in boolean) as
  begin
    g_ignore_missing_anchors := p_flag;
  end set_ignore_missing_anchors;

  function get_ignore_missing_anchors return boolean as
  begin
    return g_ignore_missing_anchors;
  end get_ignore_missing_anchors;

  procedure set_default_date_format(p_format in varchar2) as
  begin
    g_default_date_format := p_format;
  end set_default_date_format;

  function get_default_date_format return varchar2 as
  begin
    return g_default_date_format;
  end get_default_date_format;

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
  
  
  /* GENERATE_TEXT */
  -- Ueberladungen mit STMT
  procedure generate_text(
    p_stmt      in clob,
    p_result    out clob,
    p_delimiter in varchar2 default null,
    p_indent    in number default 0) 
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


  procedure generate_text(
    p_template  in varchar2,
    p_stmt      in clob,
    p_result    out varchar2,
    p_delimiter in varchar2 default null,
    p_indent    in number default 0) 
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


   -- Ueberladung mit CURSOR
  procedure generate_text(
    p_cursor    in out nocopy sys_refcursor,
    p_result    out varchar2,
    p_delimiter in varchar2 default null,
    p_indent    in number default 0) 
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
  end generate_text;


  -- Ueberladung als Funktion
  function generate_text(
    p_cursor    in sys_refcursor,
    p_delimiter in varchar2 default null,
    p_template  in varchar2 default null,
    p_indent    in number default 0) 
    return clob 
  as
    l_clob clob;
    l_cur  sys_refcursor := p_cursor;
  begin
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
    return l_clob;
  end generate_text;


  /* GENERATE_TEXT_TABLE */
  procedure generate_text_table(
    p_cursor    in out nocopy sys_refcursor,
    p_result    out clob_table,
    p_delimiter in varchar2 default null,
    p_template  in varchar2 default null,
    p_indent    in number default 0) 
  as
    l_row_tab row_tab;
  begin
    copy_table_to_row_tab(
      p_cursor => p_cursor,
      p_row_tab  => l_row_tab,
      p_first_column_is_template => p_template is null);
  
    bulk_replace(
      p_template => p_template,
      p_row_tab  => l_row_tab,
      p_delimiter => p_delimiter,
      p_result => p_result,
      p_first_column_is_template => p_template is null,
      p_indent => p_indent);
  end generate_text_table;
  
  
  -- Ueberladung als Funktion
  function generate_text_table(
    p_cursor    in sys_refcursor,
    p_delimiter in varchar2 default null,
    p_template  in varchar2 default null,
    p_indent    in number default 0) 
    return clob_table
  as
    l_clob_table clob_table;
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
    return l_clob_table;
  end generate_text_table;
  
  
  function bulk_replace(
    p_template in clob,
    p_chunks   in clob_table,
    p_indent   in number default 0)
    return clob
  as
    l_key_value_tab key_value_tab;
    l_result clob;
  begin
    l_result := p_template;
    if p_chunks is not null then
      for i in p_chunks.first .. p_chunks.last loop
        if mod(i, 2) = 1 then
          l_key_value_tab(replace(substr(p_chunks(i), 1, 30), g_main_anchor_char)) := p_chunks(i + 1);
        end if;
      end loop;
      bulk_replace(
        p_template => l_result,
        p_key_value_tab => l_key_value_tab,
        p_result => l_result,
        p_indent => p_indent);
    end if;
    return l_result;
  end bulk_replace;

begin
  initialize;
end code_generator;
/
