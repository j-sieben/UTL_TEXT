CREATE OR REPLACE PACKAGE dwh_frame.code_generator AS

  /* DATENTYPEN */
  TYPE key_value_tab IS TABLE OF CLOB INDEX BY VARCHAR2(30);
  TYPE row_tab IS TABLE OF key_value_tab INDEX BY BINARY_INTEGER;
  
  
  /* Set-Methode zum Einstellen, ob fehlende Ersetzungsanker zu einem Fehler 
   * fuehren sollen oder nicht.
   * %param p_flag Flag, das steuert, ob im Fall fehlender Anker ein Fehler geworfen
   *        werden soll (FALSE) oder nicht (TRUE). Standard ist TRUE.
   */
  PROCEDURE set_ignore_missing_anchors(p_flag IN BOOLEAN);

  /* Get-Methode, die den aktuellen Stand des Flags IGNORE_MISSING_ANCHORS zurueckgibt.
   */
  FUNCTION get_ignore_missing_anchors RETURN BOOLEAN;
  
  
  /* Set-Methode stellt das Default-Datumsformat ein, das verwendet wird, 
   * falls keine explizite Konvertierung vorgenommen wurde.
   * Standardformat ist DD.MM.YYYY HH24:MI:SS
   * %param p_format Formatmaske
   */
  PROCEDURE set_default_date_format(p_format in varchar2);

  /* Get-Methode, die den aktuellen Wert des Standard-Datumsformats zurueckgibt
   */
  FUNCTION get_default_date_format RETURN VARCHAR2;
  
  
  /* Set Methode stellt das Hauptersetzungszeichen ein
   * Standardzeichen ist #
   * %param p_char Zeichen, das als Ersetzungszeichen vewendet werdern soll
   */
  procedure set_main_anchor_char(p_char in varchar2);
  
  function get_main_anchor_char return varchar2;
  
  
  /* Set Methode stellt das Nebenersetzungszeichen ein
   * Standardzeichen ist ^
   * %param p_char Zeichen, das als Ersetzungszeichen vewendet werdern soll
   */
  procedure set_secondary_anchor_char(p_char in varchar2);
  
  function get_secondary_anchor_char return varchar2;

  /* Prozedur zum Kopieren einer einzelnen Zeile der SQL-Anweisung in eine PL/SQL-Tabelle
   * %param p_stmt SQL-Anweisung, die fuer jeden Ersetzungsanker eine Spalte generiert.
   *               Limitiert auf eine Zeile
   * %param p_key_value_tab PL/SQL-Tabelle, die als KEY-VALUE-Tabelle die Ergebnisse
   *                        von P_STMT als <Spaltenname> : <Spaltenwert> liefert.
   * %usage Wird verwendet, um eine SQL-Anweisung in eine PL/SQL-Tabelle mit benannten
   *        Schluesselwerten zu migrieren
   */
  PROCEDURE copy_row_to_key_value_tab(p_stmt          IN CLOB,
                                      p_key_value_tab IN OUT NOCOPY key_value_tab);

  /* Ueberladung fuer Cursor mit einer Ergebniszeile 
  * %param p_cursor Geoffneter Cursor
  * %param p_key_value_tab PL/SQL-Tabelle, die als KEY-VALUE-Tabelle die Ergebnisse
  *                        von P_STMT als <Spaltenname> : <Spaltenwert> liefert.
  * %usage Wird verwendet, um einen Cursor in eine PL/SQL-Tabelle mit benannten
  *        Schluesselwerten zu migrieren
  */
  PROCEDURE copy_row_to_key_value_tab(p_cursor        IN OUT NOCOPY SYS_REFCURSOR,
                                      p_key_value_tab IN OUT NOCOPY key_value_tab);

  /* Prozedur zum Kopieren einer Ergebnismenge einer SQL-Anweisung in eine Liste
  *  von KEY-VALUE-Tabellen. Jeder Eintrag der Tabelle enthaelt eine KEY-VALUE-Tabelle
  *  gem. COPY_ROW_TO_KEY_VALUE_TAB. Die ERgebnisliste ist INDEX BY BINARY_INTEGER.
  * %param p_stmt SQL-Anweisung mit einer Spalte pro Ersetzungsanker. Nicht auf eine
  *               Zeile limitiert
  * %param p_row_tab PL/SQL-Tabelle, die in jedem Eintrag eine PL/SQL-Tabelle mit#
  *                  KEY-VALUE-Paaren gem. COPY_ROW_TO_KEY_VALUE_TAB enthaelt
  * %usage Wird verwendet, um eine Liste von merhreren Ersetzungsankern in einem
  *        Durchgang in eine doppelte KEY-VALUE-Tabelle zu konvertieren.
  */
  PROCEDURE copy_table_to_row_tab(p_stmt                     IN CLOB,
                                  p_row_tab                  IN OUT NOCOPY row_tab,
                                  p_first_column_is_template BOOLEAN DEFAULT FALSE);

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
  PROCEDURE copy_table_to_row_tab(p_cursor                   IN OUT NOCOPY SYS_REFCURSOR,
                                  p_row_tab                  IN OUT NOCOPY row_tab,
                                  p_first_column_is_template BOOLEAN DEFAULT FALSE);

  /* Prozedur zum Ersetzen aller Ersetzungsanker einer PL/SQL-Tabelle in einem Template
  * %param p_template Template mit Ersetzungsankern. Syntax der Ersetzungsanker:
  *        #<Name des Ersetzungsankers, muss Tabellenspalte entsprechen>
  *        |<Pr�fix, falls Wert not null>
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
  PROCEDURE bulk_replace(p_template      IN VARCHAR2,
                         p_key_value_tab IN key_value_tab,
                         p_result        OUT VARCHAR2);
                         
  /* Ueberladung als Funktion */
  FUNCTION bulk_replace(p_template      IN VARCHAR2,
                        p_key_value_tab IN key_value_tab) RETURN VARCHAR2;

  /* Prozedur zum Ersetzen aller Ersetzungsanker mehrer PL/SQL-Tabellen in einem Template
  * %param p_template Template mit Ersetzungsankern. Syntax der Ersetzungsanker:
  *        #<Name des Ersetzungsankers, muss Tabellenspalte entsprechen>
  *        |<Pr�fix, falls Wert not null>
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
  PROCEDURE bulk_replace(p_template                 IN VARCHAR2,
                         p_row_tab                  IN row_tab,
                         p_delimiter                IN VARCHAR2,
                         p_result                   OUT CLOB,
                         p_first_column_is_template BOOLEAN DEFAULT FALSE);

  /* Prozedur zum direkten Ersetzen von Zeichenfolgen in einem Template durch die 
   * Ergebnisse der SQL-Abfrage
   * %param p_template Template mit Ersetzungsankern. Syntax der Ersetzungsanker:
   *        #<Name des Ersetzungsankers, muss Tabellenspalte entsprechen>
   *        |<Pr�fix, falls Wert not null>
   *        |<Postfix, falls Wert not null>
   *        |<Wert, falls NULL># 
   *        Alle PIPE-Zeichen und Klauseln sind optional, muessen aber, wenn sie 
   *        verwendet werden, in dieser Reihenfolge eingesetzt werden.
   *        Beispiel: #VORNAME||, |# => Falls vorhanden wird hinter dem Vornamen ein Komma eingefuegt
   *        Soll innerhalb einer Ersetzungszeichenfolge ein Anker verwendet werden, muss dieser
   *        abweichend durch eine Tilde (~) maskiert werden. Auf diese Weise kann ein Anker im 
   *        auf einen weiteren Anker verweisen.
   *        Beispiel: #NACHNAME||, |~VORNAME~# => Liefert, Vorname, falls Nachname NULL
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
  PROCEDURE generate_text(p_template  IN VARCHAR2,
                          p_stmt      IN CLOB,
                          p_result    OUT VARCHAR2,
                          p_delimiter IN VARCHAR2 DEFAULT NULL);

  /* Prozedur zum direkten Ersetzen von Zeichenfolgen in einem Template durch die 
  * Ergebnisse der SQL-Abfrage
  * %param p_template Template mit Ersetzungsankern. Syntax der Ersetzungsanker:
  *        #<Name des Ersetzungsankers, muss Tabellenspalte entsprechen>
  *        |<Pr�fix, falls Wert not null>
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
  PROCEDURE generate_text(p_template  IN VARCHAR2,
                          p_cursor    IN OUT NOCOPY SYS_REFCURSOR,
                          p_result    OUT VARCHAR2,
                          p_delimiter IN VARCHAR2 DEFAULT NULL);

  /* Prozedur zur Generierung von Texten basierend auf einem dynamischen Template
  * %param p_cursor Geoffneter Cursor mit einer oder mehreren Ergebniszeilen,
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
  PROCEDURE generate_text(p_cursor    IN OUT NOCOPY SYS_REFCURSOR,
                          p_result    OUT VARCHAR2,
                          p_delimiter IN VARCHAR2 DEFAULT NULL);

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
  PROCEDURE generate_text(p_stmt      IN CLOB,
                          p_result    OUT CLOB,
                          p_delimiter IN VARCHAR2 DEFAULT NULL);

  PROCEDURE generate_text(p_stmt      IN CLOB,
                          p_result    OUT dbms_sql.varchar2a,
                          p_delimiter IN VARCHAR2 DEFAULT NULL);
                          
  PROCEDURE generate_text(p_cursor    IN OUT NOCOPY sys_refcursor,
                          p_result    OUT dbms_sql.varchar2a,
                          p_delimiter IN VARCHAR2 DEFAULT NULL);

  PROCEDURE generate_text(p_cursor    IN OUT NOCOPY sys_refcursor,
                          p_result    OUT clob_table,
                          p_delimiter IN VARCHAR2 DEFAULT NULL);
                          
  FUNCTION generate_text(p_cursor    IN SYS_REFCURSOR,
                         p_delimiter IN VARCHAR2 DEFAULT NULL) RETURN CLOB;

  FUNCTION generate_text(p_stmt      IN CLOB,
                         p_delimiter IN VARCHAR2 DEFAULT NULL) RETURN CLOB;

END code_generator;
/
