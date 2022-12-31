create or replace package utl_text_admin
  authid definer
as


  /** 
    Package: UTL_TEXT_ADMIN
      Package to maintain UTL_TEXT_TEMPLATES

    Author::
      Juergen Sieben, ConDeS GmbH
   */ 
  
  type utl_text_template_table is table of utl_text_templates%rowtype;
  type utl_text_template_type_table is table of utl_text_templates.uttm_type%type;
    
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
    Function: get_template_script
      Method to output all templates as export script
      
    Parameters:
      p_uttm_type - Optional type of template. If NULL, all templates are exported
      p_enclosing_char - Optional chars that sets the enclosing of the quote operator when wrapping
      
    Returns:
      SQL script with package calls to generate the templates
   */
  function get_template_script(
    p_uttm_type in char_table default null,
    p_enclosing_chars in varchar2 default '{}')
    return clob;
    
  
  /**
    Function: get_templates
      Method to retrieve all text templates for the given parameter selection
    
    Parameters:
      p_type - Type of the templates to return
      p_name - Optional Name of the templates
      
    Returns:
      Row instance of table UTL_TEXT_TEMPLATES
   */
  function get_templates(
    p_type in utl_text_templates.uttm_type%type,
    p_name in utl_text_templates.uttm_name%type default null,
    p_mode in utl_text_templates.uttm_mode%type default null)
    return utl_text_template_table
    pipelined;
    
  
  /**
    Function: get_template_types
      Method to retrieve all text templates for the given parameter selection
    
    Parameters:
      p_type - Type of the templates to return
      p_name - Optional Name of the templates
      
    Returns:
      Row instance of table UTL_TEXT_TEMPLATES
   */
  function get_template_types
    return utl_text_template_type_table
    pipelined;
    
end utl_text_admin;
/