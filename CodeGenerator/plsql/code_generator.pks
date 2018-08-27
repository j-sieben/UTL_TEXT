create or replace package code_generator
  authid current_user
as

  c_no_delimiter constant varchar2(4) := 'NONE';
  $IF $$PIT_INSTALLED $THEN
  c_with_pit constant boolean := true;
  $ELSE
  c_with_pit constant boolean := false;
  $END

  /* Set-Methode zum Einstellen, ob fehlende Ersetzungsanker zu einem Fehler 
   * fuehren sollen oder nicht.
   * %param p_flag Flag, das steuert, ob im Fall fehlender Anker ein Fehler geworfen
   *        werden soll (FALSE) oder nicht (TRUE). 
   *        Standard ist definiert durch Parameter IGNORE_MISSING_ANCHORS
   */
  procedure set_ignore_missing_anchors(
    p_flag in boolean);

  function get_ignore_missing_anchors 
    return boolean;
  
  
  /* Set-Methode stellt das Default-Datumsformat ein, das verwendet wird, 
   * falls keine explizite Konvertierung vorgenommen wurde.
   * Standardformat ist definiert durch Parameter DEFAULT_DATE_FORMAT
   * %param p_format Formatmaske
   */
  procedure set_default_date_format(
    p_format in varchar2);

  function get_default_date_format
    return varchar2;
  
  
  /* Set-Methode stellt das Default-Datumsformat ein, das verwendet wird, 
   * falls keine explizite Konvertierung vorgenommen wurde.
   * Standardformat ist definiert durch Parameter DEFAULT_DATE_FORMAT
   * %param p_format Formatmaske
   */
  procedure set_newline_char(
    p_char in varchar2);

  function get_newline_char
    return varchar2;
    

  /* Set-Methode stellt das Standard-Trennzeichen bei mehrzeiligen Ergebnissen ein
   * %param p_delimiter Definiert das Trennzeichen fuer mehrzeilige Ersetzungen
   *        Standard ist definiert durch Parameter DEFAULT_DELIMITER_CHAR
   */
  procedure set_default_delimiter_char(
    p_delimiter in varchar2);

  function get_default_delimiter_char
    return varchar2;
  
  
  /* Set Methode stellt das Hauptersetzungszeichen ein
   * Standardzeichen ist definiert durch Parameter MAIN_ANCHOR_CHAR
   * %param p_char Zeichen, das als Ersetzungszeichen vewendet werdern soll
   */
  procedure set_main_anchor_char(
    p_char in varchar2);
  
  function get_main_anchor_char 
    return varchar2;
  
  
  /* Set Methode stellt das Nebenersetzungszeichen ein
   * Standardzeichen ist definiert durch Parameter SECONDARY_ANCHOR_CHAR
   * %param p_char Zeichen, das als Ersetzungszeichen vewendet werdern soll
   */
  procedure set_secondary_anchor_char(
    p_char in varchar2);
  
  function get_secondary_anchor_char 
    return varchar2;
  
  
  /* Set Methode stellt das Haupttrennzeichen ein
   * Standardzeichen ist definiert durch Parameter MAIN_SEPARATOR_CHAR
   * %param p_char Zeichen, das als Trennzeichen vewendet werdern soll
   */
  procedure set_main_separator_char(
    p_char in varchar2);
  
  function get_main_separator_char 
    return varchar2;
  
  
  /* Set Methode stellt das Nebentrennzeichen ein
   * Standardzeichen ist definiert durch Parameter SECONDARY_SEPARATOR_CHAR
   * %param p_char Zeichen, das als Trennzeichen vewendet werdern soll
   */
  procedure set_secondary_separator_char(
    p_char in varchar2);
  
  function get_secondary_separator_char 
    return varchar2;
                               
                               
  /* Funktion zum Aufteilen eines Strings mit Zeilenumbruechen auf einzelne Zeilen mit Konkatenatoren
   * %param  p_string   Zeichenkette mit Zeilenumbruechen
   * %param [p_prefix]  Optionales Startzeichen der Einzelzeile
   * %param [p_postfix] Optionales Endzeichen der Einzelzeile
   * %param [p_newline] Optionals Zeilentrennzeichen. Default: CHR(10)
   * %return Zeichenkette, deren einzelne Zeilen ueber Konkatenatoren verbunden sind
   */
  function wrap_string(
    p_string in varchar2,
    p_prefix in varchar2 default q'^q'°^',
    p_postfix in varchar2 default q'^°'^')
    return varchar2;
    
  
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
    p_chunks in char_table
  ) return clob;
                          

  /* Prozedur zur Generierung von Texten basierend auf einem dynamischen Template
  * %param p_cursor Geoffneter Cursor mit einer oder mehreren Ergebniszeilen.
  *                 Konvention:
  *                 - Spalte TEMPLATE: Template, in das die Anker eingefuegt werden sollen
  *                 - Spalte LOG_TEMPLATE: Log-Template, das verwendet wird, um eine Meldung auszugeben
  *                 - weitere Spaltenbezeichner entsprechen den Namen der Ersetzungsanker in den Templates
  * %param p_result Ergebnis der Umwandlung
  * %param p_delimiter Abschlusszeichen, das zwischen die einzelnen Instanzen der aufbereiteten Templates gestellt wird
  * %usage Wird verwendet, um direkt aus einer SQL-Anweisung und einem Template einen Ergebnistext zu erzeugen.
  *        Umfasst die SQL-Anweisung mehrere Zeilen, kann optional ein Parameter P_DELIMITER als Trennzeichen zwischen den
  *        einzelnen Zeilen uebergeben werden.
  *        Da kein Template als separater Prameter uebergeben wird, erwartet diese Ueberladung das Template als Spalte 
  *        TEMPLATE der SQL-Anweisung. Die SQL-Anweisung mussalle Ersetzungsanker in allen uebergebenen Templates 
  *        fuellen koennen.
  *        Enthaelt der Cursor eine Spalte LOG_TEMPLATE, wird dieses Template parallel zum Template der Spalte TEMPLATE 
  *        gefuellt und ueber das Logging-Package ausgegeben
  */
  procedure generate_text(
    p_cursor in out nocopy sys_refcursor,
    p_result out nocopy varchar2,
    p_delimiter in varchar2 default null,
    p_indent in number default 0
  );
                          
  -- Ueberladung als Funktion
  function generate_text(
    p_cursor in sys_refcursor,
    p_delimiter in varchar2 default null,
    p_indent in number default 0
  ) return clob;
                         
                        
  --Methoden zur Erzeugung von Listen von CLOBs                        
  procedure generate_text_table(
    p_cursor in out nocopy sys_refcursor,
    p_result out nocopy clob_table
  );
                          
                          
  -- Ueberladung als Funktion
  function generate_text_table(
    p_cursor in sys_refcursor
  ) return clob_table
    pipelined;
    
                               
  /* Listet die Ersetzungsanker in Templates aus CODE_GENERATOR_TEMPLATES auf
   * %param  p_cgtm_name          Name des Templates
   * %param  p_cgtm_type          Typ des Templates
   * %param  p_cgtm_mode          Ausfuehrungsodus des Templates
   * %param [p_with_replacements] Flag, das anzeigt, ob alle Ersetzungszeichenfolgen angezeigt werden sollen (1) oder nicht (0)
   * %return char_table mit Ankern
   * %usage  Wird verwendet, um die Ersetungsanker aus einem Template zu lesen und als Varchar2-Tabelle zurückzuliefern
   */                               
  function get_anchors(
    p_cgtm_name in varchar2,
    p_cgtm_type in varchar2,
    p_cgtm_mode in varchar2,
    p_with_replacements in number default 0
  ) return char_table
    pipelined;
    
    
  /* Administrationsfunktionen */
  
  /* Methode zur Erzeugung eines Templates
   * %param  p_cgtm_name       Name des Templates
   * %param  p_cgtm_type       Typ des Templates
   * %param  p_cgtm_mode       Ausfuehrungsmodus des Templates
   * %param  cgtm_text         Template mit Ersetzungsankern
   * %param [cgtm_log_text]    Optionales Template mit Ersetzungsankern für Loggingaufgaben
   * %param [cgtm_logseverity] Schweregrad der Logmeldung zur Steuerung der Logmenge
   * %usage  Wird verwendet, um ein Template zu erzeugen
   */
  procedure merge_template(
    p_cgtm_name in varchar2,
    p_cgtm_type in varchar2,
    p_cgtm_mode in varchar2,
    p_cgtm_text in varchar2,
    p_cgtm_log_text in varchar2,
    p_cgtm_log_severity in number);
    
    
  /* Methode exportiert alle Templates
   * %param [p_directory] Directory-Objekt, in das die Exportdatei geschrieben werden soll
   */
  procedure write_template_file(
    p_cgtm_type in char_table default null,
    p_directory in varchar2 := 'DATA_DIR');
    
  
  /* Methode, um alle Templates als Export ausgeben zu lassen
   * %return SQL-Anweisung mit Pacakgeaufrufen zur Generierung der Templates
   */
  function get_templates(
    p_cgtm_type in char_table default null)
    return clob;
    
  /* Initialisierungmethode
   * %usage  Stellt Package auf Grundwerte zurueck
   */
  procedure initialize;

end code_generator;
/
