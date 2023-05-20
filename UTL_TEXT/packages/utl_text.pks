create or replace package utl_text
  authid current_user
as

  /** 
    Package: UTL_TEXT
      String utilities including a code generator

    Author::
      Juergen Sieben, ConDeS GmbH
   */ 
  
  /** 
    Group: Types
   */
  
  /**
    Types: public subtypes
    
    ora_name_type - Type to store Oracle name types, such as column or table names
    flag_type - Adjustable type to store boolean values in a SQL usable manner
    char_type - Type to store one character flag values
    max_char - PL/SQL max varchar2 size
    clob_tab - Table of CLOB
   */
  subtype ora_name_type is &ORA_NAME_TYPE.;
  subtype flag_type is &FLAG_TYPE.;
  subtype char_type is char(1 char);
  subtype max_char is varchar2(32767 byte);
  type clob_tab is table of clob index by ora_name_type;
  
  /**
    Constants: Public constants
   
    C_DO_DELIMITER - Value to indicate that no delimiter is requested
    C_WITH_PT - Flag to indicate whether PIT is installed
    C_TRUE - Adjustable boolean TRUE value as <FLAG_TYPE>
    C_FALSE - Adjustable boolean FALSE value as <FLAG_TYPE>
    C_DEL - Generic delimiter char
   */
  C_NO_DELIMITER constant varchar2(4) := 'NONE';
  C_WITH_PIT constant boolean := &PIT_INSTALLED.;
  C_TRUE constant flag_type := &C_TRUE.;
  C_FALSE constant flag_type := &C_FALSE.;
  C_DEL constant varchar2(10) := ':';

  /** 
    Group: Setter and getter methods for package configuration 
   */
  /** 
    Method: set/get_ignore_missing_anchors
      Flag to indicate whether missing replacement anchors raise an error or not
      
    Parameter: p_flag - Boolean flag
                        FALSE: missing replacement anchors are silently ignored
                        TRUE:  missing replacement anchors terminate processing with an exception
                        Defaults to setting in parameter IGNORE_MISSING_ANCHORS
   */
  procedure set_ignore_missing_anchors(
    p_flag in boolean);

  function get_ignore_missing_anchors 
    return boolean;
  
  
  /** 
    Method: set/get_default_date_format
      Default data format that is used if no explicit conversion has been taken place. 
      Defaults to parameter DEFAULT_DATE_FORMAT
   
     Prameter: 
       p_format - Mask according to Oracle date formatting rules
   */
  procedure set_default_date_format(
    p_format in varchar2);

  function get_default_date_format
    return varchar2;
  
  
  /** 
    Method: set/get_newline_char
      Gest or sets newline char
      Defaults to CHR(21) on AIX, CHR(13)+CHR(10) on Windows and CHR(10) on Unix systems
      
    Parameter:
      p_char - newline char
   */
  procedure set_newline_char(
    p_char in varchar2);

  function get_newline_char
    return varchar2;
  
  
  /**
    Method: set/get_default_delimiter_char
      Sets delimiter char for multi line bulk replaces and text generation
   
    Parameter:
      p_delimiter - Character that is used to identify a replacement anchor on first level
                    Defaults to parameter <DEFAULT_DELIMITER_CHAR>
   */
  procedure set_default_delimiter_char(
    p_delimiter in varchar2);

  function get_default_delimiter_char
    return varchar2;
  
  /**
    Method: set/get_main_anchor_char
      Sets primary anchor char for bulk replaces and text generation
   
    Parameter:
      p_delimiter - Character that is used to identify a replacement anchor on first level
                    Defaults to parameter <MAIN_ANCHOR_CHAR>
   */
  procedure set_main_anchor_char(
    p_char in char_type);
  
  function get_main_anchor_char 
    return char_type;
    

  /** 
    Method: set/get_secondary_anchor_char
      Sets secondary anchor char for bulk replaces and text generation
   
    Parameter:
      p_delimiter - Character that is used to identify a replacement anchor on second level
                    Defaults to parameter SECONDARY_ANCHOR_CHAR
   */
  procedure set_secondary_anchor_char(
    p_char in char_type);
  
  function get_secondary_anchor_char 
    return char_type;
  
  
  /** 
    Method: set/get_main_separator_char
      Sets primary separator char for bulk replaces and text generation
   
    Paramtere:
      p_delimiter - Character that is used to separate substructure of a replacement anchor on first level
                    Defaults to parameter MAIN_SEPARATOR_CHAR
   */
  procedure set_main_separator_char(
    p_char in char_type);
  
  function get_main_separator_char 
    return char_type;
  
  
  /** 
    Method: set/get_secondary_separator_char
      Sets secondary separator char for bulk replaces and text generation
   
    Parameter:
      p_delimiter - Character that is used to separate substructure of a replacement anchor on second level
                    Defaults to parameter SECONDARY_SEPARATOR_CHAR
   */
  procedure set_secondary_separator_char(
    p_char in char_type);
  
  function get_secondary_separator_char 
    return char_type;
    
  
  /**
    Function: get_text_template (result_cache)
      Method to retrieve a given text template
      
    Parameter:
      p_type - Type of the template
      p_name - Name of the template
      p_mode - Mode of the template
      
    Returns:
      Template text of the requested template
   */
  function get_text_template(
    p_type in utl_text_templates.uttm_type%type,
    p_name in utl_text_templates.uttm_name%type,
    p_mode in utl_text_templates.uttm_mode%type)
    return utl_text_templates.uttm_text%type
    result_cache;
                               
                               
  /** 
    Function: wrap_string
      Method to split a multi line string into concatenated strings with a quote operator per line.
      
      SQL*Plus has trouble working with multi line strings if not set up properly. To stabilize
      script execution, multi line strings such as code templates should be split into one line
      strings wrapped in quote operators concatenated. So a two line string then becomes
      
      q'[First line\CR\]' ||
      
      q'[Second line]';
      
      Attention: The maximum length of P_TEXT is limited to 32K
      
    Parameters:
      p_text - Multi line string
      p_prefix - Optional override for start quote operator
      p_postfix - Optional override for end quote operator
      
    Returns:
      List of single line texts wrapped in quote operators and concatenated
   */
  function wrap_string(
    p_text in clob,
    p_prefix in varchar2 default null,
    p_postfix in varchar2 default null)
    return clob;
    
  
  /** 
    Function: unwrap_string
      Method to unwrap a string based on the outcome of WRAP_STRING.
      
      A wrapped string contains CR-replacements which makes it hard for external code to create 
      a multi line string of the wrapped string. This is achieved with this method. 
      
      Attention: The maximum length of P_TEXT is limited to 32K
      
    Parameter:
      p_text - Wrapped string
   */
  function unwrap_string(
    p_text in clob)
    return clob;
    
      
  /**
    Function: blob_to_clob
      Method to convert a BLOB to CLOB
   
    Parameter:
      p_data - BLOB to convert
   
    Returns:
      Instance of CLOB
   */
  function blob_to_clob(
    p_data in blob)
    return clob;
    
  
  /** 
    Function: clob_replace
      Method to replace an anchor within a CLOB instance with a CLOB value
      
    Parameters:
      p_text - CLOB where the anchor has to be replaced
      p_what - Anchor that will be replaced
      p_with - CLOB instance to replace anchor with
   
    Returns:
      CLOB instance with the replaced CLOB
   */
  function clob_replace(
    p_text in clob,
    p_what in varchar2,
    p_with in clob default null)
    return clob;
    
  
  /** 
    Group: STRING UTILITIES 
  */
  /** 
    Function: not_empty
      Method to check whether a string is empty or not
   
    Paramter:
      p_text  String to check
   
    Returns:
      TRUE if String is not empty, FALSE otherwise
   */
  function not_empty(
    p_text in varchar2)
    return boolean;


  /** 
    Function: append
      Method to append text to a string.
      
      Is used to append strings with or withour delimiters to an existing text. Returns the appended text.
      If P_CHUNK is null, no delimiter is appended, by setting p_berfore to a value != C_FALSE, string gets append before text, after otherwise
   
      Function implements this flag as a char to allow for usage from SQL, procedure overload implements it as boolean
      
    Parameters:
      p_text - Text to append string to
      p_chunk - String to be appended
      p_delimiter - Optional delimiter that is used to separate string from text if required
      p_before - Optional flag to indicate whether string should be append before or after text
      
    Returns: 
      Appended text
   */
  function append(
    p_text in varchar2,
    p_chunk in varchar2,
    p_delimiter in varchar2 default null,
    p_before in varchar2 default C_FALSE)
    return varchar2;

  /**
    Procedure: apppend
      Procedure overload.
   */
  procedure append(
    p_text in out nocopy varchar2,
    p_chunk in varchar2,
    p_delimiter in varchar2 default null,
    p_before in boolean default false);


  /**
    Function : append_clob
      Method to  (securerly) add a string to a clob.
   
    - If P_CLOB is null, its initialized
    - If P_CHUNK is null, P_CLOB returns unchanged
    
    Parameters:
      p_clob - CLOB P_CHUNK shall be appended at
      p_chunk - String to append to P_CLOB
    
    Returns:
      Appended CLOB
   */
  function append_clob(
    p_clob in clob,
    p_chunk in clob)
    return clob;


  /**
    Procedure: append_clob
      Procedure overload.
   */
  procedure append_clob(
    p_clob in out nocopy clob,
    p_chunk in clob);


  /**
    Function: concatenate
      Method concatenates entries of CHAR_TABLE instance to a single string comparable to LISTAGG function in SQL
      
    Parameters:
      p_chunks - CHAR_TABLE instance with the strings to concatenate
      p_delimiter - Optional delimiter char between entries of P_CHUNKS. Defaults to a <C_DEL>
      p_ignore_nulls - Optional flag to indicate whether NULL values surpress delimiters. Defaults to <C_FALSE>
      
    Returns: Concatenated text
      Method is used as an overload for LISTAGG in that it allows to pass in an instance of CHAR_TABLE.
   */
  function concatenate(
    p_chunks in char_table,
    p_delimiter in varchar2 default C_DEL,
    p_ignore_nulls varchar2 default C_FALSE)
    return varchar2;


  /**
    Procedure: concatenate
      Procedure overload.
   */
  procedure concatenate(
    p_text in out nocopy varchar2,
    p_chunks in char_table,
    p_delimiter in varchar2 default C_DEL,
    p_ignore_nulls in boolean default true);
    

  /** 
    Function: string_to_table
      Method to convert a string to an instance of CHAR_TABLE
      
    Parameters:
      p_string - Text to split into entries of CHAR_TABLE
      p_delimiter - Optional delimiter that is used to split text into entries of P_CHUNKS. Defaults to a <C_DEL>
      p_omit_empty - Optional flag to indicate whether empty recors should be surpressed (<C_TRUE>) or not (<C_FALSE>). Defaults to <C_FALSE>
    
    Returns:
      Instance of CHAR_TABLE. Function overload is pipelined to allow for usage within a TABLE() function.
   */
  function string_to_table(
    p_string in varchar2,
    p_delimiter in varchar2 default C_DEL,
    p_omit_empty in flag_type default C_FALSE)
    return char_table
    pipelined;
    
    
  /**
    Procedure: string_to_table
      Procedure overload.
   */
  procedure string_to_table(
    p_string in varchar2,
    p_table out nocopy char_table,
    p_delimiter in varchar2 default C_DEL,
    p_omit_empty in flag_type default C_FALSE);
    

  /** 
    Function: table_to_string
      Method to convert a string to an instance of CHAR_TABLE
      
    Parameters:
      p_table - Instance of CHAR_TABLE of char_table to join
      p_delimiter - Optional delimiter that is used to join text. Defaults to a <C_DEL>
      p_max_length - Optional maximum output length. Defaults to 32767
      
    Returns:
      String with P_MAX_LENGTH.
   */
  function table_to_string(
    p_table in char_table,
    p_delimiter in varchar2 default C_DEL,
    p_max_length in number default 32767)
    return varchar2;
    
    
  /**
    Procedure: table_to_string
      Procedure overload.
   */
  procedure table_to_string(
    p_table in char_table,
    p_string out nocopy varchar2,
    p_delimiter in varchar2 default C_DEL,
    p_max_length in number default 32767);

  
  /** 
    Function: clob_to_blob
      Method to convert a CLOB instance to BLOB
      
    Parameters:
      p_clob  CLOB instance to convert
      
    Returns:
      Converted BLOB instance
   */
  function clob_to_blob(
    p_clob in clob) 
    return blob;
    

  /** 
    Function: contains
      Method to (securely) check whether P_PATTERN is contained within P_TEXT.
      
      Method encloses P_TEXT and P_PATTERN by P_DELIMITER and performs an INSTR search.
      Enclosing P_PATTERN assures that no false positives are possible. Fi the pattern
      TEST would be found in TESTING if not enclosed by P_DELIMITER. Enclosing leads to
      instr(':TE:TESTING:', ':TEST:') which is 0
      
    Parameters:
      p_text - Text that is evaluated for matches
      p_pattern - String that is searched within P_TEXT
      p_delimiter - Optional delimiter that is used to enclose P_PATTERN. Defaults to <C_DEL>
      
    Returns:
      Flag that indicates whether P_PATTERN is contained within P_TEXT (<C_TRUE>) or not (<C_FALSE>)
   */
  function contains(
    p_text in varchar2,
    p_pattern in varchar2,
    p_delimiter in varchar2 default C_DEL)
    return varchar2;


  /** 
    Function: merge_string
      Method to merge a pattern into a text. Is used to assure that a pattern exists within a text only once. 
      Order is not maintained, so if you merge A into A:B:C, the resulting text might be B:C:A.
      
    Parameters:
      p_text - Text that is evaluated for matches
      p_pattern - String that is searched within P_TEXT
      p_delimiter - Optional delimiter that is used to enclose P_PATTERN. Defaults to <C_DEL>
   
    Returns:
      Merged text
   */
  function merge_string(
    p_text in varchar2,
    p_pattern in varchar2,
    p_delimiter in varchar2 default C_DEL)
    return varchar2;
    
    
  /**
    Procedure: merge_string
      Procedure overload.
   */
  procedure merge_string(
    p_text in out nocopy varchar2,
    p_pattern in varchar2,
    p_delimiter in varchar2 default C_DEL);
    
    
  /**
    Group: BULK REPLACE methods 
   */
  /**
    Procedure: bulk_replace
      Procedure to replace all replacement anchors of a PL/SQL table in a template.
      The procedure will generate a template and a prepared list of replacement anchors and ass replacement values. 
      The method replaces all anchors in the template with the replacement values in the PL/SQL table and
      analyzes NULL values to replace them with the replacement values. 
      If the value is not NULL PRE and POSTFIX values inserted if defined in replacement anchor.
    
    Parameters:
      p_template - Template with replacement anchors. Syntax of the replacement anchors:      
                   #<Name of replacement anchor, must correspond to table column>
                   |<Prefix, if value not zero>
                   |<Postfix, if value not null>
                   |<value if NULL>#
                   All PIPE characters and clauses are optional, but must be used in this order.
                   NB: The separator # corresponds to g_main_anchor_char
                   Example: #FIRENAME||, |# => If available, a comma is inserted after the first name
      p_clob_tab - Table of KEY-VALUE pairs
      p_result - Result of the conversion
   */
  procedure bulk_replace(
    p_template in clob,
    p_clob_tab in clob_tab,
    p_result out nocopy clob);
    
    
  /**
    Function: bulk_replace
      Procedure to replace all replacement anchors of a PL/SQL table in a template
      p_template - Template with replacement anchors. Syntax of the replacement anchors:      
                   #<Name of replacement anchor, must correspond to table column>
                   |<Prefix, if value not zero>
                   |<Postfix, if value not null>
                   |<value if NULL>#
                   All PIPE characters and clauses are optional, but must be used in this order.
                   NB: The separator # corresponds to g_main_anchor_char
                   Example: #FIRENAME||, |# => If available, a comma is inserted after the first name
      p_clob_tab - Table of KEY-VALUE pairs
      p_chunks - List of alternating anchors and replacement characters
      
    Returns: converted CLOB
   */
  function bulk_replace(
    p_template in clob,
    p_chunks in char_table
  ) return clob;   
    
    
  /**
    Procedure: bulk_replace
      Procedure overload.
   */
  procedure bulk_replace(
    p_template in out nocopy clob,
    p_chunks in char_table
  );
                         

  /** 
    Function: generate_text
      Method for generating texts based on a dynamic template.
      Is used to generate a result text directly from an SQL statement containing a template.
      If the SQL statement contains multiple rows, an optional P_DELIMITER parameter can be used as a separator 
      between the lines.
      Since no template is passed as a separate parameter, this overload expects the template as column 
      TEMPLATE of the SQL statement. The SQL statement must contain all replacement anchors in all transferred templates can fill.
      If the cursor contains a LOG_TEMPLATE column, this template is filled in parallel to the template of the TEMPLATE column
      
    Parameters:
      p_cursor - Opened cursor with one or more result rows.
                 Convention:
                 
                 - TEMPLATE column: Template in which the anchors are to be inserted
                 - LOG_TEMPLATE column: log template used to output a message
                 - additional column labels correspond to the names of the replacement anchors in the templates
                 
      p_result - Result of the conversion
      p_delimiter -Optional terminating character, which is placed between the individual instances of the prepared templates
      
    Returns:
      Converted CLOB
  */
  function generate_text(
    p_cursor in sys_refcursor,
    p_delimiter in varchar2 default null,
    p_indent in number default 0
  ) return clob;
  
    
  /**
    Procedure: generate_text
      Procedure overload.
   */
  procedure generate_text(
    p_cursor in out nocopy sys_refcursor,
    p_result out nocopy clob,
    p_delimiter in varchar2 default null,
    p_indent in number default 0);
                         
                        
  /**
    Function: generate_text_table
      see <generate_text>, but the result is a table of CLOB for each row of the cursor
   */
  function generate_text_table(
    p_cursor in sys_refcursor
  ) return clob_table
    pipelined;
  
    
  /**
    Procedure: generate_text_table
      Procedure overload.
   */
  procedure generate_text_table(
    p_cursor in out nocopy sys_refcursor,
    p_result out nocopy clob_table
  );
  
                               
  /** 
    Function: get_anchors
      Lists the replacement anchors in templates from <UTL_TEXT_TEMPLATES>.
      
    Parameters:
      p_uttm_type - Type of the template
      p_uttm_name - Name of the template
      p_uttm_mode - Execution mode of the template
      p_with_replacements - Optional flag indicating whether all replacement strings should be displayed (<C_TRUE>) or not (<C_FALSE>)
      
    Returns: 
      char_table with anchors
   */                               
  function get_anchors(
    p_uttm_type in varchar2,
    p_uttm_name in varchar2,
    p_uttm_mode in varchar2,
    p_with_replacements in flag_type default C_FALSE
  ) return char_table
    pipelined;
    
  /** Initialization method
   * %usage  Resets Package to default values
   */
  procedure initialize;

end utl_text;
/
