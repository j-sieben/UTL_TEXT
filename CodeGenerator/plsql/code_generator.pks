create or replace package code_generator 
as

  type key_value_tab is table of clob index by varchar2(30);
  type row_tab is table of key_value_tab index by binary_integer;


  /* Setter zum Einstellen, ob fehlende Ersetzungsanker zu einem Fehler fuehren sollen
   * oder nicht.
   * %param p_flag Flag, das steuert, ob im Fall fehlender Anker ein Fehler geworfen
   *        werden soll (FALSE) oder nicht (TRUE). Standard ist TRUE.
   */
  procedure set_ignore_missing_anchors(
    p_flag in boolean);


  /* Getter, der den aktuellen Stand des Flags IGNORE_MISSING_ANCHORS zurueckgibt.
   */
  function get_ignore_missing_anchors return boolean;


  /* Prozedur zum Kopieren einer einzelnen Zeile der SQL-Anweisung in eine PL/SQL-Tabelle
   * %param p_stmt SQL-ANweisung, die fuer jeden Ersetzungsanker eine Spalte generiert.
   *               Limitiert auf eine Zeile
   * %param p_key_value_tab PL/SQL-Tabelle, die als KEY-VALUE-Tabelle die Ergebnisse
   *                        von P_STMT als <Spaltenname> : <Spaltenwert> liefert.
   * %usage Wird verwendet, um eine SQL-Anweisung in eine PL/SQL-Tabelle mit benannten
   *        Schluesselwerten zu migrieren
   */
  procedure copy_row_to_key_value_tab(
    p_stmt in clob,
    p_key_value_tab in out nocopy key_value_tab);


  /* Ueberladung fuer Cursor mit einer Ergebniszeile 
   * %param p_cursor Geoffneter Cursor
   * %param p_key_value_tab PL/SQL-Tabelle, die als KEY-VALUE-Tabelle die Ergebnisse
   *                        von P_STMT als <Spaltenname> : <Spaltenwert> liefert.
   * %usage Wird verwendet, um einen Cursor in eine PL/SQL-Tabelle mit benannten
   *        Schluesselwerten zu migrieren
   */
  procedure copy_row_to_key_value_tab(
    p_cursor in out nocopy sys_refcursor,
    p_key_value_tab in out nocopy key_value_tab);


  /* Prozedur zum Kopieren einer Ergebnismenge einer SQL-Anweisung in eine Liste
   * von KEY-VALUE-Tabellen. Jeder Eintrag der Tabelle enthaelt eine KEY-VALUE-Tabelle
   * gem. COPY_ROW_TO_KEY_VALUE_TAB. Die ERgebnisliste ist INDEX BY BINARY_INTEGER.
   * %param p_stmt SQL-Anweisung mit einer Spalte pro Ersetzungsanker. Nicht auf eine
   *               Zeile limitiert
   * %param p_row_tab PL/SQL-Tabelle, die in jedem Eintrag eine PL/SQL-Tabelle mit#
   *                  KEY-VALUE-Paaren gem. COPY_ROW_TO_KEY_VALUE_TAB enthaelt
   * %usage Wird verwendet, um eine Liste von merhreren Ersetzungsankern in einem
   *        Durchgang in eine doppelte KEY-VALUE-Tabelle zu konvertieren.
   */
  procedure copy_table_to_row_tab(
    p_stmt in clob,
    p_row_tab in out nocopy row_tab,
    p_first_column_is_template boolean default false);


  /* Prozedur zum Kopieren einer Ergebnismenge einer SQL-Anweisung in eine Liste
   * von KEY-VALUE-Tabellen. Jeder Eintrag der Tabelle enthaelt eine KEY-VALUE-Tabelle
   * gem. COPY_ROW_TO_KEY_VALUE_TAB. Die ERgebnisliste ist INDEX BY BINARY_INTEGER.
   * %param p_cursor Geoffneter Cursor, der mehr als eine Zeile liefern kann
   * %param p_row_tab PL/SQL-Tabelle, die in jedem Eintrag eine PL/SQL-Tabelle mit#
   *        KEY-VALUE-Paaren gem. COPY_ROW_TO_KEY_VALUE_TAB enthaelt
   * %param p_first_column_is_template Flag, das anzeigt, ob in der ersten Spalte
   *        das Template fuer diese Zeile uebergeben wird.
   * %usage Wird verwendet, um eine Liste von merhreren Ersetzungsankern in einem
   *        Durchgang in eine doppelte KEY-VALUE-Tabelle zu konvertieren.
   */
  procedure copy_table_to_row_tab(
    p_cursor in out nocopy sys_refcursor,
    p_row_tab in out nocopy row_tab,
    p_first_column_is_template boolean default false);


  /* Funktion zum Ersetzen alle Ersezungsanker in einem Template
   + %param p_template Template mit Ersetzungsankern. Syntax der Ersetzungsanker:
   *        #<Name des Ersetzungsankers, muss Tabellenspalte entsprechen>
   *        |<Praefix, falls Wert not null>
   *        |<Postfix, falls Wert not null>
   *        |<Wert, falls NULL>#
   *        Alle PIPE-Zeichen und Klauseln sind optional, muessen aber, wenn sie 
   *        verwendet werden, in dieser Reihenfolge eingesetzt werden.
   *        Beispiel: #VORNAME||, |# => Falls vorhanden wird hinter dem Vornamen ein Komma eingefuegt
   * %param p_chunks Instanz vom Typ CHAR_TABLE, uebergibt eine Liste von Ankern und Ersetzungswerten
   *                 analog zu z.B. Funktion DECODE
   * %param p_result Ergebnis der Umwandlung
   * %usage Der Prozedur werden ein Template und eine Liste von Ersetzungsankern und Ersetzungszeichenfolgen
   *        uebergeben. Alle Ersetzungsanker werden im Template ersetzt und als Zeichenkette zurueckgegeben
   */
  function bulk_replace(
    p_template in varchar2,
    p_chunks in char_table)
    return varchar2;
    
  /* Ueberladung als Prozedur, Template wird nicht geaendert
   */
  procedure bulk_replace(
    p_template in varchar2,
    p_chunks in char_table,
    p_result out varchar2);
    
    
  /* Ueberladung als Prozedur, P_TEXT wird mit ersetzten Zeichenfolgen zurueckgegeben
   */
  procedure bulk_replace(
    p_text in out nocopy varchar2,
    p_chunks in char_table);


  /* Prozedur zum Ersetzen aller Ersetzungsanker einer PL/SQL-Tabelle in einem Template
   * %param p_template Template mit Ersetzungsankern. Syntax der Ersetzungsanker:
   *        #<Name des Ersetzungsankers, muss Tabellenspalte entsprechen>
   *        |<Praefix, falls Wert not null>
   *        |<Postfix, falls Wert not null>
   *        |<Wert, falls NULL>#
   *        Alle PIPE-Zeichen und Klauseln sind optional, muessen aber, wenn sie 
   *        verwendet werden, in dieser Reihenfolge eingesetzt werden.
   *        Beispiel: #VORNAME||, |# => Falls vorhanden wird hinter dem Vornamen ein Komma eingefuegt
   * %param p_key_value_tab Tabelle von KEY-VALUE-Paaren, erzeugt ueber COPY_ROW_TO_KEY_VALUE_TAB
   * %param p_result Ergebnis der Umwandlung
   * %usage Der Prozedur werden ein Template und eine aufbereitete Liste von Ersetzungsankern und
   *        Ersetzungswerten uebergeben. Die Methode ersetzt alle Anker im Template durch
   *        die Ersetzungswerte in der PL/SQL-Tabelle und analysiert dabei NULL-Werte,
   *        um diese durch die Ersatzwerte zu ersetzen. Ist der Wert nicht NULL, werden
   *        PRE-und POSTFIX-Werte eingefuegt, falls im Ersetzungsanker definiert.
   */
  procedure bulk_replace(
    p_template in varchar2,
    p_key_value_tab in key_value_tab,
    p_result out varchar2);


  /* Prozedur zum Ersetzen aller Ersetzungsanker mehrer PL/SQL-Tabellen in einem Template
   * %param p_template Template mit Ersetzungsankern. Syntax der Ersetzungsanker:
   *        #<Name des Ersetzungsankers, muss Tabellenspalte entsprechen>
   *        |<Praefix, falls Wert not null>
   *        |<Postfix, falls Wert not null>
   *        |<Wert, falls NULL>#
   *        Alle PIPE-Zeichen und Klauseln sind optional, muessen aber, wenn sie 
   *        verwendet werden, in dieser Reihenfolge eingesetzt werden.
   *        Beispiel: #VORNAME||, |# => Falls vorhanden wird hinter dem Vornamen ein Komma eingefuegt
   * %param p_row_tab Liste mit Tabelle von KEY-VALUE-Paaren, erzeugt ueber COPY_TABLE_TO_ROW_TAB
   * %param p_delimiter Abschlusszeichen, das zwischen die einzelnen Instanzen der
   *        aufbereiteten Templates gestellt wird
   * %param p_result Ergebnis der Umwandlung
   * %param p_first_column_is_template Flag, das anzeigt, ob in der ersten Spalte
   *        das Template fuer diese Zeile uebergeben wird.
   * %usage Der Prozedur werden ein Template und eine Liste mit aufbereiteten Ersetzungsankern und
   *        Ersetzungswerten uebergeben. Die Methode ersetzt fuer jede Zeile der Liste
   *        P_ROW_TAB alle Anker im Template durch die Ersetzungswerte in der PL/SQL-Tabelle 
   *        und analysiert dabei NULL-Werte, um diese durch die Ersatzwerte zu ersetzen. 
   *        Ist der Wert nicht NULL, werden PRE-und POSTFIX-Werte eingefuegt, falls im Ersetzungsanker definiert.
   *        Das Ergebnis umfasst alle Ersetzungen in Templates fuer jede Zeile der Liste
   *        P_ROW_TAB, die einzelnen Ersetzungszeichenfolgen sind durch P_DELIMITER
   *        aneinander gekoppelt. Der letzte Eintrag endet nicht auf P_DELIMITER
   */
  procedure bulk_replace(
    p_template in varchar2,
    p_row_tab in row_tab,
    p_delimiter in varchar2,
    p_result out varchar2,
    p_first_column_is_template boolean default false);


  /* Prozedur zum direkten Ersetzen von Zeichenfolgen in einem Template durch die 
   * Ergebnisse der SQL-Abfrage
   * %param p_template Template mit Ersetzungsankern. Syntax der Ersetzungsanker:
   *        #<Name des Ersetzungsankers, muss Tabellenspalte entsprechen>
   *        |<Praefix, falls Wert not null>
   *        |<Postfix, falls Wert not null>
   *        |<Wert, falls NULL>#
   *        Alle PIPE-Zeichen und Klauseln sind optional, muessen aber, wenn sie 
   *        verwendet werden, in dieser Reihenfolge eingesetzt werden.
   *        Beispiel: #VORNAME||, |# => Falls vorhanden wird hinter dem Vornamen ein Komma eingefuegt
   * %param p_stmt SQL-Anweisung mit einer Spalte pro Ersetzungsanker. Nicht auf eine
   *               Zeile limitiert
   * %param p_result Ergebnis der Umwandlung
   * %param p_delimiter Abschlusszeichen, das zwischen die einzelnen Instanzen der
   *        aufbereiteten Templates gestellt wird
   * %usage Wird verwendet, um direkt aus einer SQL-Anweisung und einem Template
   *        einen Ergebnistext zu erzeugen. Umfasst die SQL-Anweisung mehrere Zeilen,
   *        kann optional ein Parameter P_DELIMITER als Trennzeichen zwischen den
   *        einzelnen Zeilen uebergeben werden.
   */
  procedure generate_text(
    p_template in varchar2,
    p_stmt in clob,
    p_result out varchar2,
    p_delimiter in varchar2 default null);


  /* Prozedur zum direkten Ersetzen von Zeichenfolgen in einem Template durch die 
   * Ergebnisse der SQL-Abfrage
   * %param p_template Template mit Ersetzungsankern. Syntax der Ersetzungsanker:
   *        #<Name des Ersetzungsankers, muss Tabellenspalte entsprechen>
   *        |<Praefix, falls Wert not null>
   *        |<Postfix, falls Wert not null>
   *        |<Wert, falls NULL>#
   *        Alle PIPE-Zeichen und Klauseln sind optional, muessen aber, wenn sie 
   *        verwendet werden, in dieser Reihenfolge eingesetzt werden.
   *        Beispiel: #VORNAME||, |# => Falls vorhanden wird hinter dem Vornamen ein Komma eingefuegt
   * %param p_cursor Geoffneter Cursor mit einer oder mehreren Ergebniszeilen
   * %param p_result Ergebnis der Umwandlung
   * %param p_delimiter Abschlusszeichen, das zwischen die einzelnen Instanzen der
   *        aufbereiteten Templates gestellt wird
   * %usage Wird verwendet, um direkt aus einer SQL-Anweisung und einem Template
   *        einen Ergebnistext zu erzeugen. Umfasst die SQL-Anweisung mehrere Zeilen,
   *        kann optional ein Parameter P_DELIMITER als Trennzeichen zwischen den
   *        einzelnen Zeilen uebergeben werden.
   */
  procedure generate_text(
    p_template in varchar2,
    p_cursor in out nocopy sys_refcursor,
    p_result out varchar2,
    p_delimiter in varchar2 default null);


  /* Prozedur zur Generierung von Texten basierend auf einem dynamischen Template
   * %param p_cursor Geoffneter Cursor mit einer oder mehreren Ergebniszeilen,
   *                 Diese Ueberladung erwartet das Template, in das die Anker
   *                 eingefuegt werden sollen, als erste Spalte
   * %param p_result Ergebnis der Umwandlung
   * %param p_delimiter Abschlusszeichen, das zwischen die einzelnen Instanzen der
   *        aufbereiteten Templates gestellt wird
   * %usage Wird verwendet, um direkt aus einer SQL-Anweisung und einem Template
   *        einen Ergebnistext zu erzeugen. Umfasst die SQL-Anweisung mehrere Zeilen,
   *        kann optional ein Parameter P_DELIMITER als Trennzeichen zwischen den
   *        einzelnen Zeilen uebergeben werden.
   *        Da kein Template uebergeben wird, erwartet diese Ueberladung das 
   *        Template als erste Spalte der SQL-Anweisung. Die SQL-Anweisung muss
   *        alle Ersetzungsanker in allen uebergebenen Templates fuellen koennen.
   */
  procedure generate_text(
    p_cursor in out nocopy sys_refcursor,
    p_result out varchar2,
    p_delimiter in varchar2 default null);


  /* Prozedur zur Generierung von Texten basierend auf einem dynamischen Template
   * %param SQL-Anweisung mit einer Spalte pro Ersetzungsanker. Nicht auf eine Zeile limitiert.
   *                 Diese Ueberladung erwartet das Template, in das die Anker
   *                 eingef�gt werden sollen, als erste Spalte
   * %param p_result Ergebnis der Umwandlung
   * %param p_delimiter Abschlusszeichen, das zwischen die einzelnen Instanzen der
   *        aufbereiteten Templates gestellt wird
   * %usage Wird verwendet, um direkt aus einer SQL-Anweisung und einem Template
   *        einen Ergebnistext zu erzeugen. Umfasst die SQL-Anweisung mehrere Zeilen,
   *        kann optional ein Parameter P_DELIMITER als Trennzeichen zwischen den
   *        einzelnen Zeilen uebergeben werden.
   *        Da kein Template uebergeben wird, erwartet diese Ueberladung das 
   *        Template als erste Spalte der SQL-Anweisung. Die SQL-Anweisung muss
   *        alle Ersetzungsanker in allen uebergebenen Templates fuellen koennen.
   */
  procedure generate_text(
    p_stmt in clob,
    p_result out varchar2,
    p_delimiter in varchar2 default null);

  procedure generate_text(
    p_stmt in clob,
    p_result out dbms_sql.varchar2a,
    p_delimiter in varchar2 default null);

  function generate_text(
    p_cursor in sys_refcursor,
    p_delimiter in varchar2 default null) return varchar2;

  function generate_text(
    p_stmt in clob,
    p_delimiter in varchar2 default null) return varchar2;

end code_generator;
/

