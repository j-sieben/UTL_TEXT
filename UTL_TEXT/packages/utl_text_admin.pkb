create or replace package body utl_text_admin
as

  /** 
    Package: UTL_TEXT_ADMIN Body
      Package to maintain UTL_TEXT_TEMPLATES

    Author::
      Juergen Sieben, ConDeS GmbH
   */
  -- characters used to mask a CR in export files
  C_CR_CHAR constant varchar2(10) := '\CR\';
  g_newline_char varchar2(2 byte);
   


  /** 
    Procedure: initialize
      Initializes the package and reads parameter values
   */
  procedure initialize
  as
  begin
     -- Derive delimiter from OS
    case when regexp_like(dbms_utility.port_string, '(WIN|Windows)') then
      g_newline_char := chr(10);
    when regexp_like(dbms_utility.port_string, '(AIX)') then
      g_newline_char := chr(21);
    else
      g_newline_char := chr(10);
    end case;
  end initialize;
  
  
  /**
    Procedure: merge_template
      see: <UTL_TEXT_ADMIN.merge_template>
   */
  procedure merge_template(
    p_uttm_type in varchar2,
    p_uttm_name in varchar2,
    p_uttm_mode in varchar2,
    p_uttm_text in varchar2,
    p_uttm_log_text in varchar2 default null,
    p_uttm_log_severity in number default null)
  as
  begin
    merge into utl_text_templates t
    using (select p_uttm_name uttm_name,
                  p_uttm_type uttm_type,
                  p_uttm_mode uttm_mode,
                  replace(p_uttm_text, C_CR_CHAR, g_newline_char) uttm_text,
                  p_uttm_log_text uttm_log_text,
                  p_uttm_log_severity uttm_log_severity
             from dual) s
       on (t.uttm_name = s.uttm_name
       and t.uttm_type = s.uttm_type
       and t.uttm_mode = s.uttm_mode)
     when matched then update set
            t.uttm_text = s.uttm_text,
            t.uttm_log_text = s.uttm_log_text,
            t.uttm_log_severity = s.uttm_log_severity
     when not matched then insert(
            t.uttm_name, t.uttm_type, t.uttm_mode, t.uttm_text, t.uttm_log_text, t.uttm_log_severity)
          values(
            s.uttm_name, s.uttm_type, s.uttm_mode, s.uttm_text, s.uttm_log_text, s.uttm_log_severity);
  end merge_template;
    
    
  /** 
    Procedure: delete_template
      see: <UTL_TEXT_ADMIN.delete_template>
   */
  procedure delete_template(
    p_uttm_type in varchar2,
    p_uttm_name in varchar2 default null,
    p_uttm_mode in varchar2 default null)
  as
  begin
    delete from utl_text_templates
     where uttm_type = p_uttm_type
       and (uttm_name = p_uttm_name or p_uttm_name is null)
       and (uttm_mode = p_uttm_mode or p_uttm_mode is null);
  end delete_template;
    
  
  /** 
    Function: get_templates
      see: <UTL_TEXT_ADMIN.get_templates>
   */
  function get_templates(
    p_uttm_type in char_table default null,
    p_enclosing_chars in varchar2 default '{}')
    return clob
  as
    c_uttm_name constant varchar2(30) := 'EXPORT';
    c_uttm_type constant varchar2(30) := 'INTERNAL';
    l_script clob;
    
    l_prefix varchar2(20);
    l_postfix varchar2(20);
  begin
    
    utl_text.set_secondary_anchor_char('°');
    l_prefix := 'q''' || coalesce(substr(p_enclosing_chars, 1, 1), '{'); 
    l_postfix := coalesce(substr(p_enclosing_chars, 2, 1), substr(p_enclosing_chars, 1, 1),'}') || ''''; 
    
    select utl_text.generate_text(cursor(
             select uttm_text template,
                    g_newline_char cr,
                    utl_text.generate_text(cursor(
                      select t.uttm_text template,
                             d.uttm_name, d.uttm_type, d.uttm_mode,
                             utl_text.wrap_string(d.uttm_text, l_prefix, l_postfix) uttm_text,
                             utl_text.wrap_string(d.uttm_log_text, l_prefix, l_postfix) uttm_log_text,
                             d.uttm_log_severity
                        from utl_text_templates d
                        join (select column_value uttm_type
                                from table(p_uttm_type)) p
                          on d.uttm_type = p.uttm_type
                          or p.uttm_type is null
                       cross join (
                             select uttm_text
                               from utl_text_templates
                              where uttm_name = c_uttm_name
                                and uttm_type = c_uttm_type
                                and uttm_mode = 'METHODS') t
                       where d.uttm_type != c_uttm_type
                    ), g_newline_char || g_newline_char) methods
               from utl_text_templates d
              where uttm_name = c_uttm_name
                and uttm_type = c_uttm_type
                and uttm_mode = 'FRAME'
             )
           ) resultat
      into l_script
      from dual;

    return l_script;
  end get_templates;

begin
  initialize;
end utl_text_admin;
/