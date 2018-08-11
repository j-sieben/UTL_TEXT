
set define off

begin

  code_generator.merge_template(
    p_cgtm_name => 'EXPORT',
    p_cgtm_type => 'INTERNAL',
    p_cgtm_mode => 'FRAME',
    p_cgtm_text => q'°set define off#CR#set sqlprefix off#CR##CR#begin#CR##METHODS##CR#  commit;#CR#end;#CR#/#CR#set define on#CR#set sqlprefix on°',
    p_cgtm_log_text => q'°°',
    p_cgtm_log_severity => 70
  );

  code_generator.merge_template(
    p_cgtm_name => 'EXPORT',
    p_cgtm_type => 'INTERNAL',
    p_cgtm_mode => 'METHODS',
    p_cgtm_text => q'°  code_generator.merge_template(
    p_cgtm_name => '#CGTM_NAME#',
    p_cgtm_type => '#CGTM_TYPE#',
    p_cgtm_mode => '#CGTM_MODE#',
    p_cgtm_text => #CGTM_TEXT#,
    p_cgtm_log_text => #CGTM_LOG_TEXT#,
    p_cgtm_log_severity => #CGTM_LOG_SEVERITY|||null#
  );°',
    p_cgtm_log_text => q'°°',
    p_cgtm_log_severity => 70
  );
 
end;
/
set define on
