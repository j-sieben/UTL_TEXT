create or replace package utl_text
  authid current_user
as

  /** String utilities including a code generator */ 
  
  subtype ora_name_type is &ORA_NAME_TYPE.;
  subtype flag_type is &FLAG_TYPE.;
  subtype char_type is char(1 char);
  subtype max_char is varchar2(32767 byte);
  type clob_tab is table of clob index by ora_name_type;
  
  C_NO_DELIMITER constant varchar2(4) := 'NONE';
  C_WITH_PIT constant boolean := &PIT_INSTALLED.;
  C_TRUE constant flag_type := &C_TRUE.;
  C_FALSE constant flag_type := &C_FALSE.;
  C_DEL constant varchar2(10) := ':';

  /** Setter and getter methods for package configuration */
  /** Flag to indicate whether missing replacement anchors shall raise an error or not
   * %param  p_flag  Boolean flag
   *                 FALSE: missing replacement anchors are silently ignored
   *                 TRUE:  missing replacement anchors terminate processing with an exception
   *                 Defaults to setting in parameter IGNORE_MISSING_ANCHORS
   * %raises msg.INVALID_ANCHOR_NAMES_ERR
   */
  procedure set_ignore_missing_anchors(
    p_flag in boolean);

  function get_ignore_missing_anchors 
    return boolean;
  
  
  /** Default data format that is used if no explicit conversion has been taken place
   * Defaults to parameter DEFAULT_DATE_FORMAT
   * %param  p_format  Mask according to Oracle date formatting rules
   */
  procedure set_default_date_format(
    p_format in varchar2);

  function get_default_date_format
    return varchar2;
  
  
  /** Sets newline char
   * Defaults to CHR(21) on AIX, CHR(13)+CHR(10) on Windows and CHR(10) on Unix systems
   * %param  p_char  newline char
   */
  procedure set_newline_char(
    p_char in varchar2);

  function get_newline_char
    return varchar2;
  
  
  /** Sets delimiter char for multi line bulk replaces and text generation
   * %param  p_delimiter  Character that is used to identify a replacement anchor on first level
   *                      Defaults to parameter DEFAULT_DELIMITER_CHAR
   */
  procedure set_default_delimiter_char(
    p_delimiter in varchar2);

  function get_default_delimiter_char
    return varchar2;
  
  /** Sets primary anchor char for bulk replaces and text generation
   * %param  p_delimiter  Character that is used to identify a replacement anchor on first level
   *                      Defaults to parameter MAIN_ANCHOR_CHAR
   */
  procedure set_main_anchor_char(
    p_char in varchar2);
  
  function get_main_anchor_char 
    return varchar2;
    

  /** Sets secondary anchor char for bulk replaces and text generation
   * %param  p_delimiter  Character that is used to identify a replacement anchor on second level
   *                      Defaults to parameter SECONDARY_ANCHOR_CHAR
   */
  procedure set_secondary_anchor_char(
    p_char in varchar2);
  
  function get_secondary_anchor_char 
    return varchar2;
  
  
  /** Sets primary separator char for bulk replaces and text generation
   * %param  p_delimiter  Character that is used to separate substructure of a replacement anchor on first level
   *                      Defaults to parameter MAIN_SEPARATOR_CHAR
   */
  procedure set_main_separator_char(
    p_char in varchar2);
  
  function get_main_separator_char 
    return varchar2;
  
  
  /** Sets secondary separator char for bulk replaces and text generation
   * %param  p_delimiter  Character that is used to separate substructure of a replacement anchor on second level
   *                      Defaults to parameter SECONDARY_SEPARATOR_CHAR
   */
  procedure set_secondary_separator_char(
    p_char in varchar2);
  
  function get_secondary_separator_char 
    return varchar2;
                               
                               
  /** Method to split a multi line string into concatenated strings with a quote operator per line
   * %param  p_text     Multi line string
   * %param [p_prefix]  Override for start quote operator
   * %param [p_postfix] Override for end quote operator
   * %return List of single line texts wrapped in quote operators and concatenated
   * %usage  SQL*Plus has trouble working with multi line strings if not set up properly. To stabilize
   *         script execution, multi line strings such as code templates should be split into one line
   *         strings wrapped in quote operators concatenated. So a two line string then becomes
   *         q'[First line\CR\]' ||
   *         q'[Second line]';
   *         Attention: The maximum length of P_TEXT is limited to 32K at the moment
   */
  function wrap_string(
    p_text in clob,
    p_prefix in varchar2 default null,
    p_postfix in varchar2 default null)
    return clob;
    
  
  /** Method to unwrap a string based on the outcome of WRAP_STRING.
   * %param  p_text  Wrapped string
   * %usage  A wrapped string contains CR-replacements which make it hard for external code to create a multi line string
   *         of the wrapped string. This is achieved with this method. 
   *         Attention: The maximum length of P_TEXT is limited to 32K at the moment
   */
  function unwrap_string(
    p_text in clob)
    return clob;
    
  
  /** Method to replace an anchor within a CLOB instance with a CLOB value
   * %param  p_text  CLOB where the anchor has to be replaced
   * %param  p_what  Anchor that will be replaced
   * %param  p_with  CLOB instance to replace anchor with
   * %return CLOB instance with the replaced CLOB
   */
  function clob_replace(
    p_text in clob,
    p_what in varchar2,
    p_with in clob default null)
    return clob;
    
  
  /** STRING UTILITIES */
  /** Method to check whether a string is empty or not
   * %param  p_text  String to check
   * %return TRUE if String is not empty, FALSE otherwise
   */
  function not_empty(
    p_text in varchar2)
    return boolean;


  /** Method to append text to a string
   * %param  p_text       Text to append string to
   * %param  p_chunk      String to be appended
   * %param [p_delimiter] Delimiter that is used to separate string from text if required
   * %param [p_before]    Flag to indicate whether string should be append before or after text
   * %return Appended text
   * %usage  Is used to append strings with or withour delimiters to an existing text. Returns the appended text.
   *         If P_CHUNK is null, no delimiter is appended
   *         By setting p_berfore to a value != C_FALSE, string gets append before text, after otherwise
   *         Function implements this flag as a char to allow for usage from SQL, procedure overload implements it as boolean
   */
  function append(
    p_text in varchar2,
    p_chunk in varchar2,
    p_delimiter in varchar2 default null,
    p_before in varchar2 default C_FALSE)
    return varchar2;

  /** Procedure overload */
  procedure append(
    p_text in out nocopy varchar2,
    p_chunk in varchar2,
    p_delimiter in varchar2 default null,
    p_before in boolean default false);


  /** Method to append text to a CLOB
   * %param  p_clob   CLOB P_CHUNK shall be appended at
   * %param  p_chunk  String to append to P_CLOB
   * %return Appended CLOB
   * %usage  Is used to (securerly) add a string to a clob.
   *         If P_CLOB is null, its initialized
   *         If P_CHUNK is null, P_CLOB returns unchanged
   */
  function append_clob(
    p_clob in clob,
    p_chunk in clob)
    return clob;

  /** Procedure overload */
  procedure append_clob(
    p_clob in out nocopy clob,
    p_chunk in clob);


  /** Method concatenates entries of CHAR_TABLE instance to a single string comparable to LISTAGG function in SQL
   * %param  p_chunks        CHAR_TABLE instance with the strings to concatenate
   * %param [p_delimiter]    Optional delimiter char between entries of P_CHUNKS Defaults to a C_DEL
   * %param [p_ignore_nulls] Flag to indicate whether NULL values shall surpress delimiters (!= N, true) or not (N, false)
   * %return Concatenated text
   * %usage  Method is used as an overload for LISTAGG in that it allows to pass in an instance of CHAR_TABLE.
   */
  function concatenate(
    p_chunks in char_table,
    p_delimiter in varchar2 default C_DEL,
    p_ignore_nulls varchar2 default C_FALSE)
    return varchar2;

  /** Procedure overload */
  procedure concatenate(
    p_text in out nocopy varchar2,
    p_chunks in char_table,
    p_delimiter in varchar2 default C_DEL,
    p_ignore_nulls in boolean default true);
    

  /** Method to convert a string to an instance of CHAR_TABLE
   * %param  p_string      Text to split into entries of CHAR_TABLE
   * %param [p_delimiter]  Optional delimiter that is used to split text into entries of P_CHUNKS. Defaults to a C_DEL
   * %param [p_omit_empty] Flag to indicate whether empty recors should be surpressed (C_TRUE) or not (C_FALSE). Defaults to C_FALSE
   * %return Instance of CHAR_TABLE. Function overload is pipelined to allow for usage within a TABLE() function.
   */
  function string_to_table(
    p_string in varchar2,
    p_delimiter in varchar2 default C_DEL,
    p_omit_empty in flag_type default C_FALSE)
    return char_table
    pipelined;
    
  /** Procedure overload */
  procedure string_to_table(
    p_string in varchar2,
    p_table out nocopy char_table,
    p_delimiter in varchar2 default C_DEL,
    p_omit_empty in flag_type default C_FALSE);
    

  /** Method to convert a string to an instance of CHAR_TABLE
   * %param  p_table       Instance of CHAR_TABLE of char_table to join
   * %param [p_delimiter]  Optional delimiter that is used to join text. Defaults to a C_DEL
   * %param [p_max_length] Maximum output length. Defaults to 32767
   * %return String with P_MAX_LENGTH.
   */
  function table_to_string(
    p_table in char_table,
    p_delimiter in varchar2 default C_DEL,
    p_max_length in number default 32767)
    return varchar2;
    
  /** Procedure overload */
  procedure table_to_string(
    p_table in char_table,
    p_string out nocopy varchar2,
    p_delimiter in varchar2 default C_DEL,
    p_max_length in number default 32767);

  
  /** Method to convert a CLOB instance to BLOB
   * %param  p_clob  CLOB instance to convert
   * %return Converted BLOB instance
   */
  function clob_to_blob(
    p_clob in clob) 
    return blob;
    

  /** Method to (securely) check whether P_PATTERN is contained within P_TEXT
   * %param  p_text       Text that is evaluated for matches
   * %param  p_pattern    String that is searched within P_TEXT
   * %param [p_delimiter] Optional delimiter that is used to enclose P_PATTERN. Defaults to C_DEL
   * %return Flag that indicates whether P_PATTERN is contained within P_TEXT (C_TRUE) or not (C_FALSE)
   * %usage  Method encloses P_TEXT and P_PATTERN by P_DELIMITER and performs an INSTR search.
   *         Enclosing P_PATTERN assures that no false positives are possible. Fi the pattern
   *         TEST would be Found in TE,TESTING if not enclosed by P_DELIMITER Enclosing leads to
   *         instr(',TE,TESTING,', ',TEST,') which is 0
   */
  function contains(
    p_text in varchar2,
    p_pattern in varchar2,
    p_delimiter in varchar2 default C_DEL)
    return varchar2;


  /** Method to merge a pattern into a text
   * %param  p_text       Text that is evaluated for matches
   * %param  p_pattern    String that is searched within P_TEXT
   * %param [p_delimiter] Optional delimiter that is used to enclose P_PATTERN. Defaults to C_DEL
   * %return Merged text
   * %usage  Is used to assure that a pattern exists within a text only once. Order is not maintained, so
   *         if you merge A into A:B:C, the resulting text might be B:C:A.
   */
  function merge_string(
    p_text in varchar2,
    p_pattern in varchar2,
    p_delimiter in varchar2 default C_DEL)
    return varchar2;
    
  /** Procedure overload */
  procedure merge_string(
    p_text in out nocopy varchar2,
    p_pattern in varchar2,
    p_delimiter in varchar2 default C_DEL);
    
    
  /* BULK REPLACE methods */
  /** Procedure to replace all replacement anchors of a PL/SQL table in a template
   * %param  p_template  Template with replacement anchors. Syntax of the replacement anchors:
   *                     #<Name of replacement anchor, must correspond to table column>
   *                     |<Prefix, if value not zero>
   *                     |<Postfix, if value not null>
   *                     |<value if NULL>#
   *                     All PIPE characters and clauses are optional, but must be used in this order.
   *                     NB: The separator # corresponds to g_main_anchor_char
   *                     Example: #FIRENAME||, |# => If available, a comma is inserted after the first name
   * %param  p_clob_tab  Table of KEY-VALUE pairs
   * %param  p_result    Result of the conversion
   * %usage  The procedure will generate a template and a prepared list of replacement anchors and
   *         Pass replacement values. The method replaces all anchors in the template with
   *         the replacement values in the PL/SQL table and analyzes NULL values,
   *         to replace them with the replacement values. If the value is not NULL
   *         PRE and POSTFIX values inserted if defined in replacement anchor.
   */
  procedure bulk_replace(
    p_template in clob,
    p_clob_tab in clob_tab,
    p_result out nocopy clob);
    
    
  /** BULK_REPLACE-Methode mit den gleichen Moeglichkeiten der Ersetzung wie GENERATE_TEXT
  /** Procedure to replace all replacement anchors of a PL/SQL table in a template
   * %param  p_template  Template with replacement anchors. Syntax of the replacement anchors:
   *                     #<Name of replacement anchor, must correspond to table column>
   *                     |<Prefix, if value not zero>
   *                     |<Postfix, if value not null>
   *                     |<value if NULL>#
   *                     All PIPE characters and clauses are optional, but must be used in this order.
   *                     NB: The separator # corresponds to g_main_anchor_char
   *                     Example: #FIRENAME||, |# => If available, a comma is inserted after the first name
   * %param  p_clob_tab  Table of KEY-VALUE pairs
   * %param  p_chunks    List of alternating anchors and replacement characters
   * %return CLOB with the replaced text
   */
  procedure bulk_replace(
    p_template in out nocopy clob,
    p_chunks in char_table
  );
  
  /** Overload as a function */
  function bulk_replace(
    p_template in clob,
    p_chunks in char_table
  ) return clob;
                          

  /** Procedure for generating texts based on a dynamic template
  * %param  p_cursor     Open cursor with one or more result rows.
  *                      Convention:
  *                      {*} - TEMPLATE column: Template in which the anchors are to be inserted
  *                      {*} - LOG_TEMPLATE column: log template used to output a message
  *                      {*} - additional column labels correspond to the names of the replacement anchors in the templates
  * %param  p_result     Result of the conversion
  * %param  p_delimiter  Terminating character, which is placed between the individual instances of the prepared templates
  * %usage  Is used to generate a result text directly from an SQL statement and a template.
  *         If the SQL statement contains multiple rows, an optional P_DELIMITER parameter can be used as a separator between the
  *         can be passed to individual lines.
  *         Since no template is passed as a separate parameter, this overload expects the template as column 
  *         TEMPLATE of the SQL statement. The SQL statement must contain all replacement anchors in all transferred templates can fill.
  *         If the cursor contains a LOG_TEMPLATE column, this template is filled in parallel to the template of the TEMPLATE column
  */
  procedure generate_text(
    p_cursor in out nocopy sys_refcursor,
    p_result out nocopy clob,
    p_delimiter in varchar2 default null,
    p_indent in number default 0);
                          
  -- Ueberladung als Funktion
  function generate_text(
    p_cursor in sys_refcursor,
    p_delimiter in varchar2 default null,
    p_indent in number default 0
  ) return clob;
  
  -- Ueberladung mit Template und Werte-Statement
  procedure generate_text(
    p_template in varchar2,
    p_stmt in varchar2,
    p_result out nocopy clob,
    p_delimiter in varchar2 default null,
    p_indent in number default 0);
                          
  -- Ueberladung als Funktion
  function generate_text(
    p_template in varchar2,
    p_stmt in varchar2,
    p_delimiter in varchar2 default null,
    p_indent in number default 0
  ) return clob;
  
  $IF dbms_db_version.ver_le_12 $THEN
  -- Polymorphic table functions are not available on this database version
  $ELSE
  function generate_text(p_table in table)
    return table pipelined 
    row polymorphic 
    using utl_text;
    
  function describe (p_table in out nocopy dbms_tf.table_t)
    return dbms_tf.describe_t;
  $END
                         
                        
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
    
  
  $IF dbms_db_version.ver_le_12 $THEN
  -- Polymorphic table functions are not available on this database version
  $ELSE
  function generate_text_table(p_table in table)
    return table pipelined 
    row polymorphic 
    using utl_text;
    
  function gtt_describe (p_table in out nocopy dbms_tf.table_t)
    return dbms_tf.describe_t;
  $END
                               
  /** Lists the replacement anchors in templates from UTL_TEXT_TEMPLATES
   * %param  p_uttm_type          Type of the template
   * %param  p_uttm_name          Name of the template
   * %param  p_uttm_mode          Execution mode of the template
   * %param [p_with_replacements] Flag indicating whether all replacement strings should be displayed (C_TRUE) or not (C_FALSE)
   * %return char_table with anchors
   * %usage  Used to read the replacement anchors from a template and return them as a CHAR_TABLE instance
   */                               
  function get_anchors(
    p_uttm_type in varchar2,
    p_uttm_name in varchar2,
    p_uttm_mode in varchar2,
    p_with_replacements in flag_type default C_FALSE
  ) return char_table
    pipelined;
    
    
  /* Administration */
  
  /** Method for creating a template
   * %param  p_uttm_type          Type of the template
   * %param  p_uttm_name          Name of the template
   * %param  p_uttm_mode          Execution mode of the template
   * %param  p_uttm_text          Template with replacement anchors
   * %param [p_uttm_log_text]     Optional template with replacement anchors for logging tasks
   * %param [p_uttm_log_severity] Severity of the log message to control the log amount
   * %usage  Is used to create a template
   */
  procedure merge_template(
    p_uttm_type in varchar2,
    p_uttm_name in varchar2,
    p_uttm_mode in varchar2,
    p_uttm_text in varchar2,
    p_uttm_log_text in varchar2 default null,
    p_uttm_log_severity in number default null);
    
    
  /** Method to delete a template
   * %param  p_uttm_type  Type of the template
   * %param  p_uttm_name  Name of the template
   * %param  p_uttm_mode  Execution mode of the template
   * %usage  Used to remove a template
   */
  procedure delete_template(
    p_uttm_type in varchar2,
    p_uttm_name in varchar2,
    p_uttm_mode in varchar2);
    
  
  /** Method to remove all templates of a template type
   * %param  p_uttm_type Type of the template
   * %usage  Used to remove a template type
   */
  procedure remove_templates(
    p_uttm_type in varchar2);
    
  /** method exports all templates
   * %param [p_uttm_type] Type of template
   * %param [p_directory] Directory object in which the export file is to be written
   * %usage  Used to write a template export file to disc
   */
  procedure write_template_file(
    p_uttm_type in char_table default null,
    p_directory in varchar2 := 'DATA_DIR');
    
  
  /** method to output all templates as export
   * %param [p_uttm_type]      Type of template
   * %param [p_enclosing_char] Optional chars that control the enclosing of the quote operator when wrapping
   * %return SQL statement with Pacakge calls to generate the templates
   * %usage  Used to create a template export file in SQL
   */
  function get_templates(
    p_uttm_type in char_table default null,
    p_enclosing_chars in varchar2 default '{}')
    return clob;
    
  /** Initialization method
   * %usage  Resets Package to default values
   */
  procedure initialize;

end utl_text;
/
