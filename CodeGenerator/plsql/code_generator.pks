create or replace package code_generator 
as

  
  /* Set-Methode zum Einstellen, ob fehlende Ersetzungsanker zu einem Fehler 
   * fuehren sollen oder nicht.
   * %param p_flag Flag, das steuert, ob im Fall fehlender Anker ein Fehler geworfen
   *        werden soll (FALSE) oder nicht (TRUE). Standard ist TRUE.
   */
  procedure set_ignore_missing_anchors(p_flag in boolean);

  /* Get-Methode, die den aktuellen Stand des Flags IGNORE_MISSING_ANCHORS zurueckgibt.
   */
  function get_ignore_missing_anchors return boolean;
  
  
  /* Set-Methode stellt das Default-Datumsformat ein, das verwendet wird, 
   * falls keine explizite Konvertierung vorgenommen wurde.
   * Standardformat ist DD.MM.YYYY HH24:MI:SS
   * %param p_format Formatmaske
   */
  procedure set_default_date_format(p_format in varchar2);

  /* Get-Methode, die den aktuellen Wert des Standard-Datumsformats zurueckgibt
   */
  function get_default_date_format return varchar2;
  
  
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
                               
  
  /* BULK_REPLACE-Methode mit den gleichen Moeglichkeiten der Ersetzung wie GENERATE_TEXT
   * %param  p_template  Template mit Ersetzungsankern. Syntax der Ersetzungsanker:
   *                     #<Name des Ersetzungsankers, muss Tabellenspalte entsprechen>
   *                     |<Praefix, falls Wert not null>
   *                     |<Postfix, falls Wert not null>
   *                     |<Wert, falls NULL># 
   *                     Alle PIPE-Zeichen und Klauseln sind optional, muessen aber, wenn sie 
   *                     verwendet werden, in dieser Reihenfolge eingesetzt werden.
   *                     Beispiel: #VORNAME||, |# => Falls vorhanden wird hinter dem Vornamen ein Komma eingefuegt
   *                     Soll innerhalb einer Ersetzungszeichenfolge ein Anker verwendet werden, muss dieser
   *                     abweichend durch eine Tilde (~) maskiert werden. Auf diese Weise kann ein Anker im 
   *                     auf einen weiteren Anker verweisen.
   *                     Beispiel: #NACHNAME||, |~VORNAME~# => Liefert, Vorname, falls Nachname NULL
   * %param  p_chunks    Liste von Ankern und Ersetzungszeichen im Wechsel
   * %param [p_indent]   Optionale Angabe einer Einrueckung
   * %return CLOB mit dem ersetzten Text
   */
  function bulk_replace(
    p_template in clob,
    p_chunks   in clob_table,
    p_indent   in number default 0)
    return clob;


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
  procedure generate_text(p_template  in varchar2,
                          p_stmt      in clob,
                          p_result    out varchar2,
                          p_delimiter in varchar2 default null,
                          p_indent    in number default 0);
                          

  /* Prozedur zur Generierung von Texten basierend auf einem dynamischen Template
  * %param SQL-Anweisung mit einer Spalte pro Ersetzungsanker. Nicht auf eine Zeile limitiert.
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
  procedure generate_text(p_stmt      in clob,
                          p_result    out clob,
                          p_delimiter in varchar2 default null,
                          p_indent    in number default 0);

  procedure generate_text(p_stmt      in clob,
                          p_result    out dbms_sql.clob_table,
                          p_delimiter in varchar2 default null,
                          p_indent    in number default 0);

  function generate_text(p_stmt      in clob,
                         p_delimiter in varchar2 default null,
                         p_indent    in number default 0) return clob;
                          

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
  procedure generate_text(p_cursor    in out nocopy sys_refcursor,
                          p_result    out varchar2,
                          p_delimiter in varchar2 default null,
                          p_indent    in number default 0);
                          

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
  procedure generate_text(p_template  in varchar2,
                          p_cursor    in out nocopy sys_refcursor,
                          p_result    out varchar2,
                          p_delimiter in varchar2 default null,
                          p_indent    in number default 0);
                          
  procedure generate_text(p_cursor    in out nocopy sys_refcursor,
                          p_result    out dbms_sql.clob_table,
                          p_delimiter in varchar2 default null,
                          p_template  in varchar2 default null,
                          p_indent    in number default 0);
                          
  -- Ueberladung als Funktion
  function generate_text(p_cursor    in sys_refcursor,
                         p_delimiter in varchar2 default null,
                         p_template  in varchar2 default null,
                         p_indent    in number default 0) return clob;
                         
                        
  --Methoden zur Erzeugung von Listen von CLOBs                        
  procedure generate_text_table(p_cursor    in out nocopy sys_refcursor,
                                p_result    out clob_table,
                                p_delimiter in varchar2 default null,
                                p_template  in varchar2 default null,
                                p_indent    in number default 0);
                          
  -- Ueberladung als Funktion
  function generate_text_table(p_cursor    in sys_refcursor,
                               p_delimiter in varchar2 default null,
                               p_template  in varchar2 default null,
                               p_indent    in number default 0) return clob_table;

end code_generator;
/
