CREATE OR REPLACE PACKAGE BODY dwh_frame.code_generator AS

  c_row_template CONSTANT VARCHAR2(30) := '$$ROW_TEMPLATE';
  c_date_type    CONSTANT BINARY_INTEGER := 12;
  g_ignore_missing_anchors BOOLEAN;
  g_default_date_format varchar2(200);
  g_main_anchor_char char(1 char);
  g_secondary_anchor_char char(1 char);

  TYPE ref_rec_type IS RECORD(
     r_string VARCHAR2(32767)
    ,r_date   DATE
    ,r_clob   CLOB);
  l_ref_rec ref_rec_type;
  
  /* Hilfsfunktionen */

  /* Prozedur zum Oeffnen eines Cursors
   * %param p_cur ID des Cursors
   * %usage Oeffnet einen neuen Cursor fuer eine uebergebene SQL-Anweisung
   */
  PROCEDURE open_cursor(p_cur OUT INTEGER)
  AS
  BEGIN
    IF NOT dbms_sql.is_open(c => p_cur) THEN
      p_cur := dbms_sql.open_cursor;
    END IF;
  END open_cursor;
  

  /* Prozedur zum Oeffnen eines Cursors
   * %param p_cur ID des Cursors
   * %param p_cursor SYS_REFCURSOR, Ueberladung fuer einen bereits geoffneten Cursor
   * %usage Wird verwendet, wenn im aufrufenden Code bereits ein Cursor existiert
   *        und nicht nur eine SQL-Anweisung. Konvertiert diesen Cursor in einen
   *        DBMS_SQL-Cursor, der anschliessend analysiert werden kann.
   */
  PROCEDURE open_cursor(p_cur    OUT INTEGER,
                        p_cursor IN OUT NOCOPY SYS_REFCURSOR) 
  AS
  BEGIN
    p_cur := dbms_sql.to_cursor_number(p_cursor);
  END open_cursor;


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
  PROCEDURE describe_columns(p_cur                      IN INTEGER,
                             p_cur_desc                 IN OUT NOCOPY dbms_sql.desc_tab2,
                             p_key_value_tab            IN OUT NOCOPY key_value_tab,
                             p_first_column_is_template BOOLEAN DEFAULT FALSE) AS
    l_column_name  VARCHAR2(30);
    l_column_count INTEGER := 1;
    l_column_type  INTEGER;
    l_cnt          BINARY_INTEGER := 0;
  BEGIN
    -- DESCRIBE_COLUMNS ist deprecated wegen limitierter Spaltenlaenge
    dbms_sql.describe_columns2(c       => p_cur
                              ,col_cnt => l_column_count
                              ,desc_t  => p_cur_desc);
    FOR i IN 1 .. l_column_count LOOP
      IF i = 1 AND
         p_first_column_is_template THEN
        l_column_name := c_row_template;
      ELSE
        l_column_name := p_cur_desc(i).col_name;
      END IF;
      l_column_type := p_cur_desc(i).col_type;
      -- Spalte als leeren Wert in der PL/SQL-Tabelle anlegen, um ihn als Variable
      -- referenzieren zu koennen
      l_cnt := l_cnt + 1;
      p_key_value_tab(l_column_name) := NULL;
      -- Registriere Variable als Ausgabevariable dieser Spalte
      IF l_column_type = c_date_type THEN
        dbms_sql.define_column(c        => p_cur
                              ,position => l_cnt
                              ,column   => l_ref_rec.r_date);
      ELSE
        dbms_sql.define_column(c        => p_cur
                              ,position => l_cnt
                              ,column   => l_ref_rec.r_clob);
      END IF;
    END LOOP;
  END describe_columns;


  /* Prozedur zum Beschreiben eines Cursors
  * %param p_stmt SQL-Anweisung, die analysiert werden soll
  * %param p_cur ID des Cursors
  * %param p_cur_desc DBMS_SQL.DESC_TAB2 mit den Details zu einem Cursor
  * %param p_key_value_tab PL/SQL-Tabelle mit dem Spaltennamen (KEY) und 
  *        einem initialen NULL-Wert fuer jede Spalte des Cursors
  * %usage Wird verwendet, um eine SQL-Anweisung zu analysieren und eine PL/SQL-Tabelle
  *        zur Aufnahme der jeweiligen Spaltenwerte unter dem Spaltennamen zu erzeugen.
  */
  PROCEDURE describe_cursor(p_stmt                     IN CLOB,
                            p_cur                      IN OUT NOCOPY INTEGER,
                            p_cur_desc                 IN OUT NOCOPY dbms_sql.desc_tab2,
                            p_key_value_tab            IN OUT NOCOPY key_value_tab,
                            p_first_column_is_template BOOLEAN DEFAULT FALSE) AS
    l_ignore INTEGER;
  BEGIN
    open_cursor(p_cur);
    dbms_sql.parse(p_cur
                  ,'select * from (' || p_stmt || ')'
                  ,dbms_sql.native);
    l_ignore := dbms_sql.execute(p_cur);
    describe_columns(p_cur
                    ,p_cur_desc
                    ,p_key_value_tab
                    ,p_first_column_is_template);
  END describe_cursor;


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
  PROCEDURE describe_cursor(p_cursor                   IN OUT NOCOPY SYS_REFCURSOR,
                            p_cur                      IN OUT NOCOPY INTEGER,
                            p_cur_desc                 IN OUT NOCOPY dbms_sql.desc_tab2,
                            p_key_value_tab            IN OUT NOCOPY key_value_tab,
                            p_first_column_is_template BOOLEAN DEFAULT FALSE) AS
  BEGIN
    open_cursor(p_cur    => p_cur
               ,p_cursor => p_cursor);
  
    describe_columns(p_cur                      => p_cur
                    ,p_cur_desc                 => p_cur_desc
                    ,p_key_value_tab            => p_key_value_tab
                    ,p_first_column_is_template => p_first_column_is_template);
  END describe_cursor;


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
  PROCEDURE copy_values(p_cur                      IN INTEGER,
                        p_cur_desc                 IN dbms_sql.desc_tab2,
                        p_key_value_tab            IN OUT NOCOPY key_value_tab,
                        p_first_column_is_template BOOLEAN DEFAULT FALSE) AS
    l_column_name VARCHAR2(30);
  BEGIN
    FOR i IN p_cur_desc.first .. p_cur_desc.last LOOP
    
      IF i = 1 AND
         p_first_column_is_template THEN
        l_column_name := c_row_template;
      ELSE
        l_column_name := p_cur_desc(i).col_name;
      END IF;
    
      -- Aktuellen Spaltenwerte auslesen
      IF p_cur_desc(i).col_type = c_date_type THEN
        dbms_sql.column_value(p_cur
                             ,i
                             ,l_ref_rec.r_date);
        p_key_value_tab(l_column_name) := to_char(l_ref_rec.r_date
                                                 ,g_default_date_format);
      ELSE
        dbms_sql.column_value(p_cur
                             ,i
                             ,p_key_value_tab(l_column_name));
      END IF;
    END LOOP;
  END copy_values;

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
  PROCEDURE copy_values(p_cur                      IN INTEGER,
                        p_cur_desc                 IN dbms_sql.desc_tab2,
                        p_key_value_tab            IN OUT NOCOPY key_value_tab,
                        p_row_tab                  IN OUT NOCOPY row_tab,
                        p_first_column_is_template BOOLEAN DEFAULT FALSE) AS
  BEGIN
    WHILE dbms_sql.fetch_rows(p_cur) > 0 LOOP
      copy_values(p_cur                      => p_cur
                 ,p_cur_desc                 => p_cur_desc
                 ,p_key_value_tab            => p_key_value_tab
                 ,p_first_column_is_template => p_first_column_is_template);
    
      p_row_tab(dbms_sql.last_row_count) := p_key_value_tab;
    END LOOP;
  END copy_values;

  /* Initialisierungsprozedur des Packages */
  PROCEDURE initialize 
  AS
  BEGIN
    g_ignore_missing_anchors := TRUE;
    g_default_date_format := 'dd.mm.yyyy hh24:mi:ss';
    g_main_anchor_char := '#';
    g_secondary_anchor_char := '^';
  END initialize;


  /* INTERFACE */
  /* GET/SET-Methoden */
  PROCEDURE set_ignore_missing_anchors(p_flag IN BOOLEAN) AS
  BEGIN
    g_ignore_missing_anchors := p_flag;
  END set_ignore_missing_anchors;

  FUNCTION get_ignore_missing_anchors RETURN BOOLEAN AS
  BEGIN
    RETURN g_ignore_missing_anchors;
  END get_ignore_missing_anchors;
  
  
  PROCEDURE set_default_date_format(p_format in varchar2)
  AS
  BEGIN
    g_default_date_format := p_format;
  END set_default_date_format;

  FUNCTION get_default_date_format RETURN VARCHAR2 AS
  BEGIN
    RETURN g_default_date_format;
  END get_default_date_format;
  
  
  procedure set_main_anchor_char(p_char in varchar2)
  as
  begin
    g_main_anchor_char := p_char;
  end set_main_anchor_char;
  
  function get_main_anchor_char return varchar2
  as
  begin
    return g_main_anchor_char;
  end get_main_anchor_char;
  
  
  procedure set_secondary_anchor_char(p_char in varchar2)
  as
  begin
    g_secondary_anchor_char := p_char;
  end set_secondary_anchor_char;
  
  function get_secondary_anchor_char return varchar2
  as
  begin
    return g_secondary_anchor_char;
  end get_secondary_anchor_char;


  PROCEDURE copy_row_to_key_value_tab(p_stmt          IN CLOB,
                                      p_key_value_tab IN OUT NOCOPY key_value_tab) AS
    l_cur      INTEGER;
    l_cur_desc dbms_sql.desc_tab2;
  BEGIN
    describe_cursor(p_stmt          => p_stmt
                   ,p_cur           => l_cur
                   ,p_cur_desc      => l_cur_desc
                   ,p_key_value_tab => p_key_value_tab);
  
    IF dbms_sql.fetch_rows(l_cur) > 0 THEN
      copy_values(l_cur
                 ,l_cur_desc
                 ,p_key_value_tab);
    END IF;
  
    dbms_sql.close_cursor(l_cur);
  END copy_row_to_key_value_tab;

  PROCEDURE copy_row_to_key_value_tab(p_cursor        IN OUT NOCOPY SYS_REFCURSOR,
                                      p_key_value_tab IN OUT NOCOPY key_value_tab) AS
    l_cur      INTEGER;
    l_cur_desc dbms_sql.desc_tab2;
  BEGIN
    describe_cursor(p_cursor        => p_cursor
                   ,p_cur           => l_cur
                   ,p_cur_desc      => l_cur_desc
                   ,p_key_value_tab => p_key_value_tab);
  
    IF dbms_sql.fetch_rows(l_cur) > 0 THEN
      copy_values(l_cur
                 ,l_cur_desc
                 ,p_key_value_tab);
    END IF;
  
    dbms_sql.close_cursor(l_cur);
  END copy_row_to_key_value_tab;


  PROCEDURE copy_table_to_row_tab(p_stmt                     IN CLOB,
                                  p_row_tab                  IN OUT NOCOPY row_tab,
                                  p_first_column_is_template BOOLEAN DEFAULT FALSE) AS
    l_cur           INTEGER;
    l_cur_desc      dbms_sql.desc_tab2;
    l_key_value_tab key_value_tab;
  BEGIN
    describe_cursor(p_stmt                     => p_stmt
                   ,p_cur                      => l_cur
                   ,p_cur_desc                 => l_cur_desc
                   ,p_key_value_tab            => l_key_value_tab
                   ,p_first_column_is_template => p_first_column_is_template);
  
    copy_values(p_cur                      => l_cur
               ,p_cur_desc                 => l_cur_desc
               ,p_key_value_tab            => l_key_value_tab
               ,p_row_tab                  => p_row_tab
               ,p_first_column_is_template => p_first_column_is_template);
    
    dbms_sql.close_cursor(l_cur);
  END copy_table_to_row_tab;
  

  PROCEDURE copy_table_to_row_tab(p_cursor                   IN OUT NOCOPY SYS_REFCURSOR,
                                  p_row_tab                  IN OUT NOCOPY row_tab,
                                  p_first_column_is_template BOOLEAN DEFAULT FALSE) AS
    l_cur           INTEGER;
    l_cur_desc      dbms_sql.desc_tab2;
    l_key_value_tab key_value_tab;
  BEGIN
    describe_cursor(p_cursor                   => p_cursor
                   ,p_cur                      => l_cur
                   ,p_cur_desc                 => l_cur_desc
                   ,p_key_value_tab            => l_key_value_tab
                   ,p_first_column_is_template => p_first_column_is_template);
  
    copy_values(p_cur                      => l_cur
               ,p_cur_desc                 => l_cur_desc
               ,p_key_value_tab            => l_key_value_tab
               ,p_row_tab                  => p_row_tab
               ,p_first_column_is_template => p_first_column_is_template);
               
    dbms_sql.close_cursor(l_cur);
  END copy_table_to_row_tab;
  

  /* Basismethode, liefert das Ergebnis fuer eine Zeile als Varchar2 */
  PROCEDURE bulk_replace(p_template      IN VARCHAR2,
                         p_key_value_tab IN key_value_tab,
                         p_result        OUT VARCHAR2) AS
    /* SQL-Anweisung, um generisch aus einem Template alle Ersetzungsanker
      auszulesen und optionale Pre- und Postfixe sowie Ersatzwerte fuer NULL
      zu ermitteln
      Syntax des Ersetzungsankers:
      #<Name>[|<Prefix>[|<Postfix>[|<NULL-Ersatzwert>]]]#
      Beispiele:
       #COLUMN_VALUE#
       #COLUMN_VALUE||, #
       #EMP_ID|(|), |ohne ID#
      NB: Das Trennzeichen # entspricht g_main_anchor_char
    */
    c_regex constant varchar2(20) := g_main_anchor_char || '.+?' || g_main_anchor_char;
    
    CURSOR replacement_cur(p_template IN VARCHAR2) IS
        WITH data AS(
               SELECT p_template template
                 FROM dual),
             anchors AS(
               SELECT trim(g_main_anchor_char from regexp_substr(template, c_regex, 1, LEVEL)) replacement_string
                 FROM data
              CONNECT BY LEVEL <= regexp_count(template,g_main_anchor_char) / 2)
      SELECT g_main_anchor_char||replacement_string||g_main_anchor_char AS replacement_string
            ,upper(regexp_substr(replacement_string, '[^|]+', 1, 1)) anchor
            ,regexp_substr(replacement_string, '(.*?)(\||$)', 1, 2, null, 1) prefix
            ,regexp_substr(replacement_string, '(.*?)(\||$)', 1, 3, null, 1) postfix                         
            ,regexp_substr(replacement_string, '(.*?)(\||$)', 1, 4, null, 1) null_value
        FROM anchors;
        
    l_anchor          VARCHAR2(32767);
    l_missing_anchors VARCHAR2(32767);
  BEGIN
    p_result := p_template;
    
    -- Zeichenfolgen ersetzen. Ersetzungen koennen wiederum Ersetzungsanker enthalten
    FOR rep IN replacement_cur(p_template) LOOP
      IF p_key_value_tab.exists(rep.anchor) THEN
        l_anchor := p_key_value_tab(rep.anchor);
        IF l_anchor IS NOT NULL THEN
          p_result := REPLACE(p_result
                             ,rep.replacement_string
                             ,rep.prefix || l_anchor || rep.postfix);
        ELSE
          p_result := REPLACE(p_result
                             ,rep.replacement_string
                             ,rep.null_value);
        END IF;
      ELSE
        -- Ersetzungszeichenfolge ist in Ersetzungsliste nicht enthalten
        l_missing_anchors := l_missing_anchors || '|' || rep.anchor;
      END IF;
    END LOOP;
  
    IF l_missing_anchors IS NOT NULL AND NOT g_ignore_missing_anchors THEN
      l_missing_anchors := LTRIM(l_missing_anchors, '|');
      msg_log.error(msg_pkg.code_gen_missing_anchors
                   ,msg_args(l_missing_anchors));
    END IF;
    
    -- Rekursiver Aufruf, falls Ersetzungen wiederum Anker beinhalten,
    -- bisheriges Ergebnis dient als Template fuer den rekursiven Aufruf
    IF p_template != p_result THEN
      bulk_replace (
        p_template => replace(p_result, g_secondary_anchor_char, g_main_anchor_char),
        p_key_value_tab => p_key_value_tab,
        p_result => p_result);
    END IF;
  END bulk_replace;
  
  
  /* Ueberladung als Funktion */
  FUNCTION bulk_replace(p_template      IN VARCHAR2,
                        p_key_value_tab IN key_value_tab) RETURN VARCHAR2
  AS
    l_result varchar2(32767);
  BEGIN
    bulk_replace(p_template, p_key_value_tab, l_result);
    return l_result;
  END bulk_replace;
  

  PROCEDURE bulk_replace(p_template                 IN VARCHAR2,
                         p_row_tab                  IN row_tab,
                         p_delimiter                IN VARCHAR2,
                         p_result                   OUT CLOB,
                         p_first_column_is_template BOOLEAN DEFAULT FALSE) AS
    l_result        VARCHAR2(32767);
    l_template      VARCHAR2(4000);
    l_key_value_tab key_value_tab;
  BEGIN
    dbms_lob.createtemporary(p_result, false, dbms_lob.call);
    l_template := p_template;
    IF p_row_tab.count > 0 THEN
      FOR i IN p_row_tab.first .. p_row_tab.last LOOP
        l_key_value_tab := p_row_tab(i);
      
        IF p_first_column_is_template THEN
          l_template := l_key_value_tab(c_row_template);
        END IF;
      
        bulk_replace(p_template      => l_template
                    ,p_key_value_tab => l_key_value_tab
                    ,p_result        => l_result);
      
        IF i < p_row_tab.last THEN
          l_result := l_result || p_delimiter;
        END IF;
      
        dbms_lob.append(p_result, l_result);
      END LOOP;
    ELSE
      RAISE no_data_found;
    END IF;
  END bulk_replace;
  
  
  /* Array: JZ 2.5.17 */
  PROCEDURE bulk_replace(p_template                 IN VARCHAR2,
                         p_row_tab                  IN row_tab,
                         p_delimiter                IN VARCHAR2,
                         p_result                   OUT dbms_sql.varchar2a,
                         p_first_column_is_template BOOLEAN DEFAULT FALSE) AS
    l_result        VARCHAR2(32767);
    l_template      VARCHAR2(4000);
    l_key_value_tab key_value_tab;
  BEGIN
    l_template := p_template;
    IF p_row_tab.count > 0 THEN
      FOR i IN p_row_tab.first .. p_row_tab.last LOOP
        l_key_value_tab := p_row_tab(i);
      
        IF p_first_column_is_template THEN
          l_template := l_key_value_tab(c_row_template);
        END IF;
      
        bulk_replace(p_template      => l_template
                    ,p_key_value_tab => l_key_value_tab
                    ,p_result        => l_result);
      
        IF i < p_row_tab.last THEN
          l_result := l_result || p_delimiter;
        END IF;
      
        p_result(i) := l_result;
      END LOOP;
    ELSE
      RAISE no_data_found;
    END IF;
  END bulk_replace;
  

  PROCEDURE bulk_replace(p_template                 IN VARCHAR2,
                         p_row_tab                  IN row_tab,
                         p_delimiter                IN VARCHAR2,
                         p_result                   OUT clob_table,
                         p_first_column_is_template BOOLEAN DEFAULT FALSE) AS
    l_result        VARCHAR2(32767);
    l_template      VARCHAR2(4000);
    l_key_value_tab key_value_tab;
  BEGIN
    l_template := p_template;
    IF p_row_tab.count > 0 THEN
      FOR i IN p_row_tab.first .. p_row_tab.last LOOP
        l_key_value_tab := p_row_tab(i);
      
        IF p_first_column_is_template THEN
          l_template := l_key_value_tab(c_row_template);
        END IF;
      
        bulk_replace(p_template      => l_template
                    ,p_key_value_tab => l_key_value_tab
                    ,p_result        => l_result);
      
        IF i < p_row_tab.last THEN
          l_result := l_result || p_delimiter;
        END IF;
      
        p_result(i) := l_result;
      END LOOP;
    ELSE
      RAISE no_data_found;
    END IF;
  END bulk_replace;
  

  PROCEDURE generate_text(p_template  IN VARCHAR2,
                          p_stmt      IN CLOB,
                          p_result    OUT VARCHAR2,
                          p_delimiter IN VARCHAR2 DEFAULT NULL) AS
    l_row_tab row_tab;
  BEGIN
    copy_table_to_row_tab(p_stmt                     => p_stmt
                         ,p_row_tab                  => l_row_tab
                         ,p_first_column_is_template => FALSE);
                         
    bulk_replace(p_template  => p_template
                ,p_row_tab   => l_row_tab
                ,p_delimiter => p_delimiter
                ,p_result    => p_result);
  END generate_text;
  

  PROCEDURE generate_text(p_template  IN VARCHAR2,
                          p_cursor    IN OUT NOCOPY SYS_REFCURSOR,
                          p_result    OUT VARCHAR2,
                          p_delimiter IN VARCHAR2 DEFAULT NULL) AS
    l_row_tab row_tab;
  BEGIN
    copy_table_to_row_tab(p_cursor                   => p_cursor
                         ,p_row_tab                  => l_row_tab
                         ,p_first_column_is_template => FALSE);
                         
    bulk_replace(p_template  => p_template
                ,p_row_tab   => l_row_tab
                ,p_delimiter => p_delimiter
                ,p_result    => p_result);
  END generate_text;
  

  PROCEDURE generate_text(p_cursor    IN OUT NOCOPY SYS_REFCURSOR,
                          p_result    OUT VARCHAR2,
                          p_delimiter IN VARCHAR2 DEFAULT NULL) AS
    l_row_tab row_tab;
  BEGIN
    copy_table_to_row_tab(p_cursor                   => p_cursor
                         ,p_row_tab                  => l_row_tab
                         ,p_first_column_is_template => TRUE);
  
    bulk_replace(p_template                 => NULL
                ,p_row_tab                  => l_row_tab
                ,p_delimiter                => p_delimiter
                ,p_result                   => p_result
                ,p_first_column_is_template => TRUE);
  END generate_text;


  PROCEDURE generate_text(p_stmt      IN CLOB,
                          p_result    OUT CLOB,
                          p_delimiter IN VARCHAR2 DEFAULT NULL) AS
    l_row_tab row_tab;
  BEGIN
    copy_table_to_row_tab(p_stmt                     => p_stmt
                         ,p_row_tab                  => l_row_tab
                         ,p_first_column_is_template => TRUE);
  
    bulk_replace(p_template                 => NULL
                ,p_row_tab                  => l_row_tab
                ,p_delimiter                => p_delimiter
                ,p_result                   => p_result
                ,p_first_column_is_template => TRUE);
  END generate_text;
  

  PROCEDURE generate_text(p_stmt      IN CLOB,
                          p_result    OUT dbms_sql.varchar2a,
                          p_delimiter IN VARCHAR2 DEFAULT NULL) AS
    l_row_tab row_tab;
  BEGIN
    copy_table_to_row_tab(p_stmt                     => p_stmt
                         ,p_row_tab                  => l_row_tab
                         ,p_first_column_is_template => TRUE);
  
    bulk_replace(p_template                 => NULL
                ,p_row_tab                  => l_row_tab
                ,p_delimiter                => p_delimiter
                ,p_result                   => p_result
                ,p_first_column_is_template => TRUE);
  END generate_text;
  

  PROCEDURE generate_text(p_cursor    IN OUT NOCOPY sys_refcursor,
                          p_result    OUT dbms_sql.varchar2a,
                          p_delimiter IN VARCHAR2 DEFAULT NULL) AS
    l_row_tab row_tab;
  BEGIN
    copy_table_to_row_tab(p_cursor                   => p_cursor
                         ,p_row_tab                  => l_row_tab
                         ,p_first_column_is_template => TRUE);
  
    bulk_replace(p_template                 => NULL
                ,p_row_tab                  => l_row_tab
                ,p_delimiter                => p_delimiter
                ,p_result                   => p_result
                ,p_first_column_is_template => TRUE);
  END generate_text;
  
  
  PROCEDURE generate_text(p_cursor    IN OUT NOCOPY sys_refcursor,
                          p_result    OUT clob_table,
                          p_delimiter IN VARCHAR2 DEFAULT NULL) AS
    l_row_tab row_tab;
  BEGIN
    copy_table_to_row_tab(p_cursor                   => p_cursor
                         ,p_row_tab                  => l_row_tab
                         ,p_first_column_is_template => TRUE);
  
    bulk_replace(p_template                 => NULL
                ,p_row_tab                  => l_row_tab
                ,p_delimiter                => p_delimiter
                ,p_result                   => p_result
                ,p_first_column_is_template => TRUE);
  END generate_text;
  

  FUNCTION generate_text(p_stmt      IN CLOB,
                         p_delimiter IN VARCHAR2 DEFAULT NULL) RETURN CLOB 
  AS
    l_clob CLOB;
  BEGIN
    dbms_lob.createtemporary(l_clob, false, dbms_lob.call);
    generate_text(p_stmt      => p_stmt
                 ,p_result    => l_clob
                 ,p_delimiter => p_delimiter);
    RETURN l_clob;
  END generate_text;
  

  FUNCTION generate_text(p_cursor    IN SYS_REFCURSOR,
                         p_delimiter IN VARCHAR2 DEFAULT NULL) RETURN CLOB 
  AS
    l_clob CLOB;
    l_cur  SYS_REFCURSOR := p_cursor;
  BEGIN
    dbms_lob.createtemporary(l_clob, false, dbms_lob.call);
    generate_text(p_cursor    => l_cur
                 ,p_result    => l_clob
                 ,p_delimiter => p_delimiter);
    RETURN l_clob;
  END generate_text;
  
  
BEGIN
  initialize;
END code_generator;
/
