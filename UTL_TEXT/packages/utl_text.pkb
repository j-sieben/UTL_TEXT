create or replace package body utl_text
as

  C_ROW_TEMPLATE constant ora_name_type := 'TEMPLATE';
  C_LOG_TEMPLATE constant ora_name_type := 'LOG_TEMPLATE';
  C_DATE_TYPE constant binary_integer := 12;
  C_PARAM_GROUP constant ora_name_type := 'UTL_TEXT';
  C_CR_CHAR constant varchar2(10) := '\CR\';

  g_ignore_missing_anchors boolean;
  g_default_date_format varchar2(200);
  g_default_delimiter_char varchar2(100);
  g_main_anchor_char char_type;
  g_secondary_anchor_char char_type;
  g_main_separator_char char_type;
  g_secondary_separator_char char_type;
  g_newline_char varchar2(2 byte);

  type row_tab is table of clob_tab index by binary_integer;

  type ref_rec_type is record(
    r_string max_char,
    r_date date,
    r_clob clob);
  g_ref_rec ref_rec_type;


  /**
    Group: Helper methods
   */
  /** 
    Procedure: open_cursor
      Method to open a cursor
      
    Parameters:
      p_cur - Cursor ID
      p_cursor - SYS_REFCURSOR
   */
  procedure open_cursor(
    p_cur out nocopy binary_integer,
    p_cursor in out nocopy sys_refcursor)
  as
  begin
    p_cur := dbms_sql.to_cursor_number(p_cursor);
  end open_cursor;


  /** 
    Procedure: describe_columns
      Method to analyze a cursor. The following functionality is implemented:
   
      - analyze cursor
      - initialize PL/SQL with column_name as key an NULL as payload
      - register out variables for each column with cursor
      
    Parameters:
      p_cur - Cursor ID
      p_cur_desc - DBMS_SQL.DESC_TAB2 with details to the actual cursor
      p_clob_tab - PL/SQL table with column_name (KEY) and initial NULL value for each column
      p_template - Optional template. If present, no template is expected to be part of the cursor
   */
  procedure describe_columns(
    p_cur in binary_integer,
    p_cur_desc in out nocopy dbms_sql.desc_tab2,
    p_clob_tab in out nocopy clob_tab,
    p_template in varchar2 default null)
  as
    l_column_name ora_name_type;
    l_column_count binary_integer := 1;
    l_column_type binary_integer;
    l_cnt binary_integer := 0;
    l_cur_contains_template boolean := true;
  begin
    dbms_sql.describe_columns2(
      c => p_cur,
      col_cnt => l_column_count,
      desc_t => p_cur_desc);

    if p_template is not null then
      p_clob_tab(c_row_template) := p_template;
      l_cur_contains_template := false;
    end if;

    for i in 1 .. l_column_count loop
      if i = 1 and l_cur_contains_template then
        l_column_name := C_ROW_TEMPLATE;
      else
        l_column_name := p_cur_desc(i).col_name;
      end if;

      l_column_type := p_cur_desc(i).col_type;

      -- Add column to PL/SQL table to enable referencing as out variable
      l_cnt := l_cnt + 1;
      p_clob_tab(l_column_name) := null;

      -- register out variable for this column
      if l_column_type = C_DATE_TYPE then
        dbms_sql.define_column(
          c => p_cur,
          position => l_cnt,
          column => g_ref_rec.r_date);
      else
        dbms_sql.define_column(
          c => p_cur,
          position => l_cnt,
          column => g_ref_rec.r_clob);
      end if;
    end loop;
  end describe_columns;


  /** 
    Procedure: copy_row_values
      Method to copy row values in prepared PL/SQL table
      
    Parameters:
      p_cur - Cursor ID
      p_cur_desc - DBMS_SQL.DESC_TAB2 with details to the actual cursor
      p_clob_tab - PL/SQL table with column_name (KEY) and initial NULL value for each column
   */
  procedure copy_row_values(
    p_cur in binary_integer,
    p_cur_desc in dbms_sql.desc_tab2,
    p_clob_tab in out nocopy clob_tab)
  as
    l_column_name ora_name_type;
  begin
    for i in 1 .. p_cur_desc.count loop
      l_column_name := p_cur_desc(i).col_name;

      -- get actual column value
      if p_cur_desc(i).col_type = C_DATE_TYPE then
        dbms_sql.column_value(p_cur, i, g_ref_rec.r_date);
        p_clob_tab(l_column_name) := to_char(g_ref_rec.r_date, g_default_date_format);
      else
        dbms_sql.column_value(p_cur, i, p_clob_tab(l_column_name));
      end if;
    end loop;
  end copy_row_values;


  /** 
    Procedure copy_table_values
      Method to copy multiple row values into a nested PL/SQL table 
      (one entry per row in the outer table, on entry per column in the inner table).
      
      Copies all rows of a cursor including their column values into a nested PL/SQL table.
      Parameter P_CLOB_TAB is necessary as it has been prepared upfront and must be passed all the way through the layers
      
    Paramteres:
      p_cur - Cursor ID
      p_cur_desc - DBMS_SQL.DESC_TAB2 with details to the actual cursor
      p_clob_tab - PL/SQL table with one entry per column
      p_row_tab - PL/SQL with one entry of type P_CLOB_TAB per row
   */
  procedure copy_table_values(
    p_cur in binary_integer,
    p_cur_desc in dbms_sql.desc_tab2,
    p_clob_tab in out nocopy clob_tab,
    p_row_tab in out nocopy row_tab)
  as
  begin
    while dbms_sql.fetch_rows(p_cur) > 0 loop
      copy_row_values(
        p_cur => p_cur,
        p_cur_desc => p_cur_desc,
        p_clob_tab => p_clob_tab);

      p_row_tab(dbms_sql.last_row_count) := p_clob_tab;
    end loop;
  end copy_table_values;


  /** 
    Procedure: copy_table_to_row_tab
      Method to copy a table into a nested PL/SQL table. Designed as a helper method as it is called three times
      
    Parameters:
      p_cur - Cursor ID of a cursor that is allowed to contain multiple rows
      p_row_tab - PL/SQL table with the rows and column values
      p_template - Optional template. If present, no template is expected to be part of the cursor
   */
  procedure copy_table_to_row_tab(
    p_cur in out nocopy binary_integer,
    p_row_tab in out nocopy row_tab,
    p_template in varchar2 default null)
  as
    l_cur_desc dbms_sql.desc_tab2;
    l_clob_tab clob_tab;
  begin
    describe_columns(
      p_cur => p_cur,
      p_cur_desc => l_cur_desc,
      p_clob_tab => l_clob_tab,
      p_template => p_template);

    copy_table_values(
      p_cur => p_cur,
      p_cur_desc => l_cur_desc,
      p_clob_tab => l_clob_tab,
      p_row_tab => p_row_tab);

    dbms_sql.close_cursor(p_cur);
  end copy_table_to_row_tab;


  /** 
    Function: get_delimiter
      Method to calculate the actual delimiter sign. Allows to switch delimiter off by passing in <C_NO_DELIMITER>
      
    Parameter:
      p_delimiter - Delimiter char. If NULL, <G_DEFAULT_DELIMITER> is used
      
    Returns:
      Delimiter character
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


  /** 
    Procedure: bulk_replace
      Method to replace all anchors with respective values from P_ROW_TAB
      
    Parameters:
      p_row_tab - Nested PL/SQL table, created by <COPY_TABLE_TO_ROW_TAB>
      p_delimiter - Delimiter char to separate optional compponents within an anchor
      p_indent - Optional amount of blanks to indent each resulting row
      p_result - CLOB instance with the converted result
   */
  procedure bulk_replace(
    p_row_tab in row_tab,
    p_delimiter in varchar2,
    p_indent in number,
    p_result out nocopy clob,
    p_enable_second_level in flag_type default C_FALSE)
  as
    l_result clob;
    l_template clob;
    l_log_message clob;
    l_clob_tab clob_tab;
    l_delimiter g_default_delimiter_char%type;
    l_indent varchar2(1000);
  begin
    l_delimiter := get_delimiter(p_delimiter);

    if p_row_tab.count > 0 and p_result is null then
      dbms_lob.createtemporary(p_result, false, dbms_lob.call);
    end if;

    for i in 1 .. p_row_tab.count loop
      l_clob_tab := p_row_tab(i);
      if l_clob_tab.exists(C_ROW_TEMPLATE) then
        l_template := l_clob_tab(C_ROW_TEMPLATE);
      else
        l_template := l_clob_tab(l_clob_tab.first);
      end if;

      bulk_replace(
        p_template => l_template,
        p_clob_tab => l_clob_tab,
        p_result => l_result,
        p_enable_second_level => p_enable_second_level);

      -- If column C_LOG_TEMPLATE is present, use it for logging
      if l_clob_tab.exists(C_LOG_TEMPLATE) and l_clob_tab(C_LOG_TEMPLATE) is not null then
        bulk_replace(
          p_template => l_clob_tab(C_LOG_TEMPLATE),
          p_clob_tab => l_clob_tab,
          p_result => l_log_message,
          p_enable_second_level => p_enable_second_level);

        $IF utl_text.C_WITH_PIT $THEN
        pit.log(msg.UTL_TEXT_LOG_CONVERSION, msg_args(l_log_message));
        $ELSE
        dbms_output.put_line(l_log_message);
        $END
      end if;

      if i < p_row_tab.last then
        l_result := l_result || l_delimiter;
      end if;

      p_result := p_result || l_result;
    end loop;

    -- indent complete result by P_INDENT
    if p_indent > 0 then
      l_indent := l_delimiter || rpad(' ', p_indent, ' ');
      p_result := replace(p_result, l_delimiter, l_indent);
    end if;

  end bulk_replace;


  /** 
    Procedure: bulk_replace
      Method to replace all anchors with respective values from P_ROW_TAB
    
    Paramters:
      p_row_tab - Nested PL/SQL table, created by <COPY_TABLE_TO_ROW_TAB>
      p_delimiter - Delimiter char to separate optional compponents within an anchor
      p_result - <CLOB_TABLE> instance with the converted result (one CLOB instance per row)
   */
  procedure bulk_replace(
    p_row_tab in row_tab,
    p_delimiter in varchar2,
    p_result out nocopy clob_table,
    p_enable_second_level in flag_type default C_FALSE)
  as
    l_result clob;
    l_template clob;
    l_log_message clob;
    l_clob_tab clob_tab;
    l_delimiter g_default_delimiter_char%type;
  begin
    -- Initialize
    p_result := clob_table();
    l_delimiter := get_delimiter(p_delimiter);

    for i in 1 .. p_row_tab.count loop
      l_clob_tab := p_row_tab(i);

      l_template := l_clob_tab(C_ROW_TEMPLATE);

      bulk_replace(
        p_template => l_template,
        p_clob_tab => l_clob_tab,
        p_result => l_result,
        p_enable_second_level => p_enable_second_level);

      if l_clob_tab.exists(C_LOG_TEMPLATE) and l_clob_tab(C_LOG_TEMPLATE) is not null then
        bulk_replace(
          p_template => l_clob_tab(C_LOG_TEMPLATE),
          p_clob_tab => l_clob_tab,
          p_result => l_log_message,
          p_enable_second_level => p_enable_second_level);


        $IF utl_text.C_WITH_PIT $THEN
        pit.log(msg.UTL_TEXT_LOG_CONVERSION, msg_args(l_log_message));
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


  /** 
    Procedure: initialize
      Initializes the package and reads parameter values
   */
  procedure initialize
  as
  begin
    $IF utl_text.C_WITH_PIT $THEN
    g_ignore_missing_anchors := param.get_boolean(
                                  p_par_id => 'IGNORE_MISSING_ANCHORS',
                                  p_par_pgr_id => C_PARAM_GROUP);
    g_default_delimiter_char := param.get_string(
                                  p_par_id => 'DEFAULT_DELIMITER_CHAR',
                                  p_par_pgr_id => C_PARAM_GROUP);
    g_default_date_format := param.get_string(
                               p_par_id => 'DEFAULT_DATE_FORMAT',
                               p_par_pgr_id => C_PARAM_GROUP);
    g_main_anchor_char := param.get_string(
                            p_par_id => 'MAIN_ANCHOR_CHAR',
                            p_par_pgr_id => C_PARAM_GROUP);
    g_secondary_anchor_char := param.get_string(
                                 p_par_id => 'SECONDARY_ANCHOR_CHAR',
                                 p_par_pgr_id => C_PARAM_GROUP);
    g_main_separator_char := param.get_string(
                               p_par_id => 'MAIN_SEPARATOR_CHAR',
                               p_par_pgr_id => C_PARAM_GROUP);
    g_secondary_separator_char := param.get_string(
                                    p_par_id => 'SECONDARY_SEPARATOR_CHAR',
                                    p_par_pgr_id => C_PARAM_GROUP);
    $ELSE
    g_ignore_missing_anchors := true;
    g_default_delimiter_char := chr(10);
    g_default_date_format := 'yyyy-mm-dd hh24:mi:ss';
    g_main_anchor_char := '#';
    g_secondary_anchor_char := '^';
    g_main_separator_char := '|';
    g_secondary_separator_char := '~';
    $END

    -- Derive delimiter from OS
    case when regexp_like(dbms_utility.port_string, '(WIN|Windows)') then
      g_newline_char := chr(13) || chr(10);
    when regexp_like(dbms_utility.port_string, '(AIX)') then
      g_newline_char := chr(21);
    else
      g_newline_char := chr(10);
    end case;
  end initialize;


  /** 
    Group: INTERFACE
   */
  /** 
    Procedure: set_default_delimiter_char
      see: <UTL_TEXT.set_default_delimiter_char>
   */
  procedure set_ignore_missing_anchors(
    p_flag in boolean)
  as
  begin
    g_ignore_missing_anchors := p_flag;
  end set_ignore_missing_anchors;
    
  
  /** 
    Function: get_ignore_missing_anchors
      see: <UTL_TEXT.get_ignore_missing_anchors>
   */
  function get_ignore_missing_anchors
    return boolean
  as
  begin
    return g_ignore_missing_anchors;
  end get_ignore_missing_anchors;
    
  
  /** 
    Procedure: set_default_delimiter_char
      see: <UTL_TEXT.set_default_delimiter_char>
   */
  procedure set_default_delimiter_char(
    p_delimiter in varchar2)
  as
  begin
    g_default_delimiter_char := p_delimiter;
  end set_default_delimiter_char;
    
  
  /** 
    Function: get_default_delimiter_char
      see: <UTL_TEXT.get_default_delimiter_char>
   */
  function get_default_delimiter_char
    return varchar2
  as
  begin
    return g_default_delimiter_char;
  end get_default_delimiter_char;
    
  
  /** 
    Procedure: set_main_anchor_char
      see: <UTL_TEXT.set_main_anchor_char>
   */
  procedure set_main_anchor_char(p_char in char_type) as
  begin
    g_main_anchor_char := p_char;
  end set_main_anchor_char;
    
  
  /** 
    Function: get_main_anchor_char
      see: <UTL_TEXT.get_main_anchor_char>
   */
  function get_main_anchor_char return char_type as
  begin
    return g_main_anchor_char;
  end get_main_anchor_char;
    
  
  /** 
    Procedure: set_secondary_anchor_char
      see: <UTL_TEXT.set_secondary_anchor_char>
   */
  procedure set_secondary_anchor_char(p_char in char_type) as
  begin
    g_secondary_anchor_char := p_char;
  end set_secondary_anchor_char;
    
  
  /** 
    Function: get_secondary_anchor_char
      see: <UTL_TEXT.get_secondary_anchor_char>
   */
  function get_secondary_anchor_char return char_type as
  begin
    return g_secondary_anchor_char;
  end get_secondary_anchor_char;
    
  
  /** 
    Procedure: set_main_separator_char
      see: <UTL_TEXT.set_main_separator_char>
   */
  procedure set_main_separator_char(
    p_char in char_type)
  as
  begin
    g_main_separator_char := p_char;
  end set_main_separator_char;
    
  
  /** 
    Function: get_main_separator_char
      see: <UTL_TEXT.get_main_separator_char>
   */
  function get_main_separator_char
    return char_type
  as
  begin
    return g_main_separator_char;
  end get_main_separator_char;
    
  
  /** 
    Procedure: set_secondary_separator_char
      see: <UTL_TEXT.set_secondary_separator_char>
   */
  procedure set_secondary_separator_char(
    p_char in char_type)
  as
  begin
    g_secondary_separator_char := p_char;
  end set_secondary_separator_char;
    
  
  /** 
    Function: get_secondary_separator_char
      see: <UTL_TEXT.get_secondary_separator_char>
   */
  function get_secondary_separator_char
    return char_type
  as
  begin
    return g_secondary_separator_char;
  end get_secondary_separator_char;
    
  
  /** 
    Function: get_text_template
      see: <UTL_TEXT.get_text_template>
   */
  function get_text_template(
    p_type in utl_text_templates.uttm_type%type,
    p_name in utl_text_templates.uttm_name%type,
    p_mode in utl_text_templates.uttm_mode%type)
    return utl_text_templates.uttm_text%type
    result_cache
  as
    l_template utl_text_templates.uttm_text%type;
  begin
    select uttm_text
      into l_template
      from utl_text_templates
     where uttm_type = p_type
       and uttm_name = p_name
       and uttm_mode = p_mode;
    return l_template;
  end get_text_template;
    
  
  /** 
    Procedure: set_default_date_format
      see: <UTL_TEXT.set_default_date_format>
   */
  procedure set_default_date_format(p_format in varchar2) as
  begin
    g_default_date_format := p_format;
  end set_default_date_format;
    
  
  /** 
    Function: get_default_date_format
      see: <UTL_TEXT.get_default_date_format>
   */
  function get_default_date_format return varchar2 as
  begin
    return g_default_date_format;
  end get_default_date_format;
    
  
  /** 
    Procedure: set_newline_char
      see: <UTL_TEXT.set_newline_char>
   */
  procedure set_newline_char(
    p_char in varchar2)
  as
  begin
    g_newline_char := p_char;
  end set_newline_char;
    
  
  /** 
    Function: get_newline_char
      see: <UTL_TEXT.get_newline_char>
   */
  function get_newline_char
    return varchar2
  as
  begin
    return g_newline_char;
  end get_newline_char;
    
  
  /** 
    Function: not_empty
      see: <UTL_TEXT.not_empty>
   */
  function not_empty(
    p_text in varchar2)
    return boolean
  as
  begin
    return length(trim(p_text)) > 0;
  end not_empty;
    
  
  /** 
    Function: append
      see: <UTL_TEXT.append>
   */
  function append(
    p_text in varchar2,
    p_chunk in varchar2,
    p_delimiter in varchar2 default null,
    p_before in flag_type default C_FALSE)
    return varchar2
  as
    l_result max_char;
  begin
    if not_empty(p_chunk) then
      if p_before != c_false then
        l_result := p_text || case when p_text is not null then p_delimiter end || p_chunk;
      else
        l_result := p_text || p_chunk || p_delimiter;
      end if;
    else
      l_result := p_text;
    end if;
    return l_result;
  end append;
    
  
  /** 
    Procedure: append
      see: <UTL_TEXT.append>
   */
  procedure append(
    p_text in out nocopy varchar2,
    p_chunk in varchar2,
    p_delimiter in varchar2 default null,
    p_before in boolean default false)
  as
    l_before flag_type := C_FALSE;
  begin
    if p_before then
      l_before := C_TRUE;
    end if;
    p_text := append(p_text, p_chunk, p_delimiter, l_before);
  end append;
    
  
  /** 
    Function: append_clob
      see: <UTL_TEXT.append_clob>
   */
  function append_clob(
    p_clob in clob,
    p_chunk in clob)
    return clob
  as
    l_clob clob;
  begin
    if length(p_chunk) > 0 then
      l_clob := p_clob;
      if l_clob is null then
        dbms_lob.createtemporary(l_clob, false, dbms_lob.call);
      end if;
      l_clob := l_clob || p_chunk;
    end if;
    return l_clob;
  end append_clob;
    
  
  /** 
    Procedure: append_clob
      see: <UTL_TEXT.append_clob>
   */
  procedure append_clob(
    p_clob in out nocopy clob,
    p_chunk in clob)
  as
  begin
     p_clob := append_clob(p_clob, p_chunk);
  end append_clob;
    
  
  /** 
    Function: blob_to_clob
      see: <UTL_TEXT.blob_to_clob>
   */
  function blob_to_clob(
    p_data in blob)
    return clob
  as
    l_clob clob;
    l_dest_offset  PLS_INTEGER := 1;
    l_src_offset   PLS_INTEGER := 1;
    l_lang_context PLS_INTEGER := DBMS_LOB.default_lang_ctx;
    l_warning      PLS_INTEGER;
  begin
    dbms_lob.createtemporary(
      lob_loc => l_clob,
      cache   => FALSE,
      dur     => dbms_lob.call);

    dbms_lob.converttoclob(
     dest_lob      => l_clob,
     src_blob      => p_data,
     amount        => dbms_lob.lobmaxsize,
     dest_offset   => l_dest_offset,
     src_offset    => l_src_offset, 
     blob_csid     => dbms_lob.default_csid,
     lang_context  => l_lang_context,
     warning       => l_warning);
    dbms_lob.append(l_clob, sqlerrm);
    return l_clob;
  end blob_to_clob;
    
  
  /** 
    Function: concatenate
      see: <UTL_TEXT.concatenate>
   */
  function concatenate(
    p_chunks in char_table,
    p_delimiter in varchar2 default C_DEL,
    p_ignore_nulls flag_type default C_FALSE)
    return varchar2
  as
    l_result max_char;
  begin
    for i in p_chunks.first .. p_chunks.last loop
      if (not_empty(p_chunks(i)) and p_ignore_nulls = C_TRUE) or (p_ignore_nulls = C_FALSE) then
        append(
          p_text => l_result,
          p_chunk => p_chunks(i),
          p_delimiter => p_delimiter
        );
      end if;
    end loop;
    return trim(p_delimiter from l_result);
  end concatenate;
    
  
  /** 
    Procedure: concatenate
      see: <UTL_TEXT.concatenate>
   */
  procedure concatenate(
    p_text in out nocopy varchar2,
    p_chunks in char_table,
    p_delimiter in varchar2 default C_DEL,
    p_ignore_nulls in boolean default true)
  as
    l_ignore_nulls flag_type;
  begin
    if p_ignore_nulls then
      l_ignore_nulls := c_true;
    else
      l_ignore_nulls := c_false;
    end if;
    p_text := concatenate(p_chunks, p_delimiter, l_ignore_nulls);
  end concatenate;
    
  
  /** 
    Function: string_to_table
      see: <UTL_TEXT.string_to_table>
   */
  function string_to_table(
    p_string in varchar2,
    p_delimiter in varchar2 default C_DEL,
    p_omit_empty in flag_type default C_FALSE)
    return char_table
    pipelined
  as
    l_char_table char_table;
  begin
    string_to_table(p_string, l_char_table, p_delimiter, p_omit_empty);
    for i in 1 .. l_char_table.count loop
      pipe row (l_char_table(i));
    end loop;
    return;
  end string_to_table;
    
  
  /** 
    Procedure: string_to_table
      see: <UTL_TEXT.string_to_table>
   */
  procedure string_to_table(
    p_string in varchar2,
    p_table out nocopy char_table,
    p_delimiter in varchar2 default C_DEL,
    p_omit_empty in flag_type default C_FALSE)
  as
    l_chunk max_char;
  begin
    if p_table is null then
      p_table := char_table();
    end if;
    if p_string is not null then
      for i in 1 .. regexp_count(p_string, '\' || p_delimiter) + 1 loop
        l_chunk := regexp_substr(p_string, '[^\' || p_delimiter || ']+', 1, i);
        if p_omit_empty = C_FALSE or l_chunk is not null then
          p_table.extend;
          p_table(p_table.last) := l_chunk;
        end if;
      end loop;
    end if;
  end string_to_table;
    
  
  /** 
    Function: table_to_string
      see: <UTL_TEXT.table_to_string>
   */
  function table_to_string(
    p_table in char_table,
    p_delimiter in varchar2 default C_DEL,
    p_max_length in number default 32767)
    return varchar2
  as
    l_result max_char;
  begin
    table_to_string(p_table, l_result, p_delimiter, p_max_length);
    
    return l_result;
  end table_to_string;
    
  
  /** 
    Procedure: table_to_string
      see: <UTL_TEXT.table_to_string>
   */
  procedure table_to_string(
    p_table in char_table,
    p_string out nocopy varchar2,
    p_delimiter in varchar2 default C_DEL,
    p_max_length in number default 32767)
  as
  begin
    for i in 1 .. p_table.count loop
      if length(p_string) + length(p_table(i)) > least(p_max_length, 32767) then
        exit;
      end if;
      if i > 1 then
        p_string := p_string || p_delimiter;
      end if;
      p_string := p_string || p_table(i);
    end loop;
  end table_to_string;
    
  
  /** 
    Function: clob_to_blob
      see: <UTL_TEXT.clob_to_blob>
   */
  function clob_to_blob(
    p_clob in clob)
    return blob
  as
    l_blob blob;
    l_lang_context  integer := dbms_lob.DEFAULT_LANG_CTX;
    l_warning       integer := dbms_lob.WARN_INCONVERTIBLE_CHAR;
    l_dest_offset   integer := 1;
    l_source_offset integer := 1;
  begin
    $IF utl_text.C_WITH_PIT $THEN   
    pit.assert(dbms_lob.getlength(p_clob) > 0);
    $ELSE
    return null;
    $END
    
    dbms_lob.createtemporary(l_blob, true, dbms_lob.call);
    dbms_lob.converttoblob (
      dest_lob => l_blob,
      src_clob => p_clob,
      amount => dbms_lob.LOBMAXSIZE,
      dest_offset => l_dest_offset,
      src_offset => l_source_offset,
      blob_csid => dbms_lob.DEFAULT_CSID,
      lang_context => l_lang_context,
      warning => l_warning
    );

    return l_blob;
  $IF utl_text.C_WITH_PIT $THEN   
  exception
    when msg.PIT_ASSERT_IS_NOT_NULL_ERR then
      return null;
  $END
  end clob_to_blob;
    
  
  /** 
    Function: contains
      see: <UTL_TEXT.contains>
   */
  function contains(
    p_text in varchar2,
    p_pattern in varchar2,
    p_delimiter in varchar2 default C_DEL)
    return varchar2
  as
    l_result flag_type := c_false;
  begin
    if instr(p_delimiter || p_text || p_delimiter, p_delimiter || p_pattern || p_delimiter) > 0 then
      l_result := c_true;
    end if;
    return l_result;
  end contains;
    
  
  /** 
    Function: merge_string
      see: <UTL_TEXT.merge_string>
   */
  function merge_string(
    p_text in varchar2,
    p_pattern in varchar2,
    p_delimiter in varchar2 default C_DEL)
    return varchar2
  as
    l_result max_char;
    l_strings char_table;
    l_patterns char_table;
    l_exists boolean := false;
  begin
    l_strings := string_to_table(p_text, p_delimiter);
    l_patterns := string_to_table(p_pattern, p_delimiter);
    for i in 1 .. l_patterns.count loop
      for k in 1 .. l_strings.count loop
        if l_strings(k) = l_patterns(i) then
          l_exists := true;
        end if;
      end loop;
      if l_exists then
        -- already in list, ignore
        null;
      else
        l_strings.extend;
        l_strings(l_strings.last) := l_patterns(i);
      end if;
      l_exists := false;
    end loop;
    l_result := concatenate(l_strings, p_delimiter);
    return l_result;
  end merge_string;
    
  
  /** 
    Procedure: merge_string
      see: <UTL_TEXT.merge_string>
   */
  procedure merge_string(
    p_text in out nocopy varchar2,
    p_pattern in varchar2,
    p_delimiter in varchar2 default C_DEL)
  as
  begin
    p_text := merge_string(p_text, p_pattern, p_delimiter);
  end merge_string;
    
  
  /** 
    Function: wrap_string
      see: <UTL_TEXT.wrap_string>
   */
  function wrap_string(
    p_text in clob,
    p_prefix in varchar2 default null,
    p_postfix in varchar2 default null)
    return clob
  as
    l_text clob;
    l_prefix varchar2(20) := coalesce(p_prefix, q'[q'°]');
    l_postfix varchar2(20) := coalesce(p_postfix, q'[°']');
    C_REGEX_NEWLINE constant varchar2(30) := '(' || chr(13) || chr(10) || '|' || chr(10) || '|' || chr(13) || ' |' || chr(21) || ')';
    C_REPLACEMENT constant varchar2(100) := C_CR_CHAR || l_postfix || ' || ' || g_newline_char || l_prefix;
  begin
    if p_text is not null then
      if instr(p_text, chr(13) || chr(10)) > 0 then
        l_text := replace(p_text, chr(13) || chr(10), C_REPLACEMENT);
      end if;
      if instr(p_text, chr(10)) > 0 then
        l_text := replace(p_text, chr(10), C_REPLACEMENT);
      end if;
      if instr(p_text, chr(13)) > 0 then
        l_text := replace(p_text, chr(13), C_REPLACEMENT);
      end if;
      l_text := l_prefix || coalesce(l_text, p_text) || l_postfix;
    end if;
    l_text := coalesce(l_text, l_prefix || l_postfix);    
    return l_text;
  end wrap_string;
    
  
  /** 
    Function: unwrap_string
      see: <UTL_TEXT.unwrap_string>
   */
  function unwrap_string(
    p_text in clob)
    return clob
  as
    l_text clob;
  begin
    if p_text is not null then
      l_text := replace(p_text, C_CR_CHAR, g_newline_char);
    end if;
    return l_text;
  end unwrap_string;


  function clob_replace(
    p_text in clob,
    p_what in varchar2,
    p_with in clob default null)
    return clob
  as
    l_result clob;
    l_before clob;
    l_after clob;
    l_idx binary_integer;
  begin
    l_idx := instr(p_text, p_what);
    if l_idx > 0 then
      l_before := substr(p_text, 1, l_idx - 1);
      l_after := substr(p_text, l_idx + length(p_what));
      l_result :=  l_before || p_with || l_after;
      return l_result;
    else
      return p_text;
    end if;
  end clob_replace;
    
  
  /** 
    Procedure: bulk_replace
      see: <UTL_TEXT.bulk_replace>
   */
  procedure bulk_replace(
    p_template in clob,
    p_clob_tab in clob_tab,
    p_result out nocopy clob,
    p_enable_second_level in flag_type default C_FALSE)
  as
    C_REGEX varchar2(20) := replace('\#A#[A-Z0-9].*?\#A#', '#A#', g_main_anchor_char);
    C_REGEX_ANCHOR varchar2(20) := '[^\' || g_main_anchor_char || ']+';
    C_REGEX_SEPARATOR varchar2(20) := '(.*?)(\' || g_main_separator_char || '|$)';
    C_REGEX_ANCHOR_NAME constant varchar2(50) := q'^(^[0-9]+$|^[A-Z][A-Z0-9_\$#]*$)^';

    /** Cursor detects all replacement anchors within a template and extracts any substructure */
    cursor replacement_cur(p_template in clob) is
        with anchors as (
                select trim(g_main_anchor_char from regexp_substr(p_template, C_REGEX, 1, level)) replacement_string
                  from dual
               connect by level <= regexp_count(p_template, '\' || g_main_anchor_char) / 2),
             parts as(
             select g_main_anchor_char || replacement_string || g_main_anchor_char as replacement_string,
                    upper(regexp_substr(replacement_string, C_REGEX_SEPARATOR, 1, 1, null, 1)) anchor,
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
    l_template clob;
  begin
    $IF utl_text.C_WITH_PIT $THEN
    pit.assert(
      p_condition => length(p_template) > 0,
      p_message_name => msg.UTL_TEXT_NO_TEMPLATE);
    $ELSE
    if p_template is null then
      raise_application_error(-20000, 'Template must not be null');
    end if;
    $END

    -- Copy template to result to allow for easy recursion
    p_result := p_template;

    -- Replace replacement anchors. Replacements may contain replacement anchors
    for rep in replacement_cur(p_template) loop
      case
      when rep.valid_anchor_name = 0 then
        l_invalid_anchors := l_invalid_anchors || g_main_anchor_char || rep.anchor;
      when p_clob_tab.exists(rep.anchor) then
        l_anchor_value := p_clob_tab(rep.anchor);
        if l_anchor_value is not null then
          p_result := clob_replace(p_result, rep.replacement_string, rep.prefix || l_anchor_value || rep.postfix);
        else
          p_result := clob_replace(p_result, rep.replacement_string, rep.null_value);
        end if;
      else
        -- replacement anchor is missing
        l_missing_anchors := l_missing_anchors || g_main_anchor_char || rep.anchor;
        null;
      end case;
    end loop;

    if l_missing_anchors is not null and not g_ignore_missing_anchors then
      l_missing_anchors := ltrim(l_missing_anchors, g_main_anchor_char);
      $IF utl_text.C_WITH_PIT $THEN
      pit.error(
        msg.UTL_TEXT_MISSING_ANCHORS,
        msg_args(l_missing_anchors));
      $ELSE
      raise_application_error(-20002, 'The following anchors are missing: ' || l_missing_anchors);
      $END
    end if;

    -- Call recursively to replace newly entered replacement anchors.
    -- To make this possible, replace secondary anchor chars with their primary pendants before recursion
    if p_template != p_result then
      if p_enable_second_level = C_TRUE then
        l_template := replace(replace(p_result,
                          g_secondary_anchor_char, g_main_anchor_char),
                          g_secondary_separator_char, g_main_separator_char);
      end if;
      if length(l_template) > 0 then
        bulk_replace(
          p_template => l_template,
          p_clob_tab => p_clob_tab,
          p_result => p_result);
      end if;
    end if;
  end bulk_replace;
    
  
  /** 
    Procedure: bulk_replace
      see: <UTL_TEXT.bulk_replace>
   */
  procedure bulk_replace(
    p_template in out nocopy clob,
    p_chunks in char_table,
    p_enable_second_level in flag_type default C_FALSE)
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
      p_result => l_result,
      p_enable_second_level => p_enable_second_level);
    p_template := l_result;
  end bulk_replace;


  function bulk_replace(
    p_template in clob,
    p_chunks in char_table,
    p_enable_second_level in flag_type default C_FALSE) 
  return clob
  as
    l_result clob;
  begin
    l_result := p_template;
    bulk_replace(
      p_template => l_result,
      p_chunks => p_chunks,
      p_enable_second_level => p_enable_second_level);
    return l_result;
  end bulk_replace;
    
  
  /** 
    Procedure: generate_text
      see: <UTL_TEXT.generate_text>
   */
  procedure generate_text(
    p_cursor in out nocopy sys_refcursor,
    p_result out nocopy clob,
    p_delimiter in varchar2 default null,
    p_indent in number default 0,
    p_enable_second_level in flag_type default C_FALSE)
  as
    l_row_tab row_tab;
    l_cur binary_integer;
  begin
    $IF utl_text.C_WITH_PIT $THEN
    pit.assert(
      p_condition => (coalesce(p_delimiter, c_no_delimiter) = c_no_delimiter and p_indent = 0) or (p_delimiter != c_no_delimiter),
      p_message_name => msg.UTL_TEXT_INVALID_PARAMETER_COMBI);
    $ELSE
    if not((p_delimiter = c_no_delimiter and p_indent = 0) or (p_delimiter != c_no_delimiter)) then
      raise_application_error(-20003, 'Indenting is allowed only if a delimiter is present.');
    end if;
    $END

    open_cursor(
      p_cur => l_cur,
      p_cursor => p_cursor);

    copy_table_to_row_tab(
      p_cur => l_cur,
      p_row_tab => l_row_tab);

    bulk_replace(
      p_row_tab => l_row_tab,
      p_delimiter => p_delimiter,
      p_result => p_result,
      p_indent => p_indent,
      p_enable_second_level => p_enable_second_level);
  end generate_text;
    
  
  /** 
    Function: generate_text
      see: <UTL_TEXT.generate_text>
   */
  function generate_text(
    p_cursor in sys_refcursor,
    p_delimiter in varchar2 default null,
    p_indent in number default 0,
    p_enable_second_level in flag_type default C_FALSE)
    return clob
  as
    l_clob clob;
    l_cur sys_refcursor := p_cursor;
  begin
    generate_text(
      p_cursor => l_cur,
      p_result => l_clob,
      p_delimiter => p_delimiter,
      p_indent => p_indent,
      p_enable_second_level => p_enable_second_level);
    return l_clob;
  end generate_text;
    
  
  /** 
    Procedure: generate_text_table
      see: <UTL_TEXT.generate_text_table>
   */
  procedure generate_text_table(
    p_cursor in out nocopy sys_refcursor,
    p_result out nocopy clob_table,
    p_enable_second_level in flag_type default C_FALSE)
  as
    l_cur binary_integer;
    l_row_tab row_tab;
  begin
    open_cursor(
      p_cur => l_cur,
      p_cursor => p_cursor);

    copy_table_to_row_tab(
      p_cur => l_cur,
      p_row_tab => l_row_tab);

    bulk_replace(
      p_row_tab => l_row_tab,
      p_delimiter => null,
      p_result => p_result,
      p_enable_second_level => p_enable_second_level);
  end generate_text_table;
    
  
  /** 
    Function: generate_text_table
      see: <UTL_TEXT.generate_text_table>
   */
  function generate_text_table(
    p_cursor in sys_refcursor,
    p_enable_second_level in flag_type default C_FALSE)
    return clob_table
    pipelined
  as
    l_clob_table clob_table;
    l_cursor sys_refcursor := p_cursor;
  begin
    generate_text_table(
      p_cursor => l_cursor,
      p_result => l_clob_table,
      p_enable_second_level => p_enable_second_level);

    for i in 1 .. l_clob_table.count loop
      if length(l_clob_table(i)) > 0 then
        pipe row (l_clob_table(i));
      end if;
    end loop;
    return;
  end generate_text_table;
    
  
  /** 
    Function: get_anchors
      see: <UTL_TEXT.get_anchors>
   */
  function get_anchors(
    p_uttm_type in varchar2,
    p_uttm_name in varchar2,
    p_uttm_mode in varchar2,
    p_with_replacements in flag_type default C_FALSE
  ) return char_table
    pipelined
  as
    C_REGEX_ANCHOR_complete constant varchar2(100) :=
      '\' || g_main_anchor_char || '[A-Z0-9_\$\' || g_main_separator_char || '].*?\' || g_main_anchor_char || '';
    C_REGEX_ANCHOR_only constant varchar2(100) :=
      '\' || g_main_anchor_char || '[A-Z0-9_\$].*?(\' || g_main_separator_char || '|\' || g_main_anchor_char || ')';

    l_regex varchar2(200);
    l_retval char_table;
    l_template utl_text_templates.uttm_text%type;
    l_str varchar2(50 char);
    l_cnt pls_integer := 1;
  begin
    select uttm_text
      into l_template
      from utl_text_templates
     where uttm_name = upper(p_uttm_name)
       and uttm_type = upper(p_uttm_type)
       and uttm_mode = upper(p_uttm_mode);

    -- Template found, initialize
    case when p_with_replacements = C_TRUE then
      l_regex := C_REGEX_ANCHOR_COMPLETE;
    else
      l_regex := C_REGEX_ANCHOR_ONLY;
    end case;

    -- Find replacement anchors and prepare them for replacement
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
end utl_text;
/