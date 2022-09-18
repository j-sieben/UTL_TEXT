create or replace package utl_text_admin
  authid definer
as


  /** 
    Package: UTL_TEXT_ADMIN
      Package to maintain UTL_TEXT_TEMPLATES

    Author::
      Juergen Sieben, ConDeS GmbH
   */ 
    
  /**
    Procedure: merge_template
      Method for merging a template into <UTL_TEXT_TEMPLATES>
      
    Parameters:
      p_uttm_type - Type of the template
      p_uttm_name - Name of the template
      p_uttm_mode - Execution mode of the template
      p_uttm_text - Template with replacement anchors
      p_uttm_log_text - Optional template with replacement anchors for logging tasks
      p_uttm_log_severity - Optional severity of the log message to control the log amount
   */
  procedure merge_template(
    p_uttm_type in varchar2,
    p_uttm_name in varchar2,
    p_uttm_mode in varchar2,
    p_uttm_text in varchar2,
    p_uttm_log_text in varchar2 default null,
    p_uttm_log_severity in number default null);
    
    
  /** 
    Procedure: delete_template
      Method to delete a template from <UTL_TEXT_TEMPLATE>
      
    Paramters:
      p_uttm_type - Type of the template
      p_uttm_name - Name of the template
      p_uttm_mode - Execution mode of the template
   */
  procedure delete_template(
    p_uttm_type in varchar2,
    p_uttm_name in varchar2 default null,
    p_uttm_mode in varchar2 default null);
    
  
  /** 
    Function: get_templates
      Method to output all templates as export script
      
    Parameters:
      p_uttm_type - Optional type of template. If NULL, all templates are exported
      p_enclosing_char - Optional chars that sets the enclosing of the quote operator when wrapping
      
    Returns:
      SQL script with package calls to generate the templates
   */
  function get_templates(
    p_uttm_type in char_table default null,
    p_enclosing_chars in varchar2 default '{}')
    return clob;
    
end utl_text_admin;
/