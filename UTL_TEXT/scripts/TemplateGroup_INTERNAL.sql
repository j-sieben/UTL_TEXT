
set define off

begin

  utl_text_admin.merge_template(
    p_uttm_name => 'EXPORT',
    p_uttm_type => 'INTERNAL',
    p_uttm_mode => 'FRAME',
    p_uttm_text => q'^set define off#CR##CR#begin#CR##METHODS##CR#  commit;#CR#end;#CR#/#CR#set define on^',
    p_uttm_log_text => q'^^',
    p_uttm_log_severity => 70
  );

  utl_text_admin.merge_template(
    p_uttm_name => 'EXPORT',
    p_uttm_type => 'INTERNAL',
    p_uttm_mode => 'METHODS',
    p_uttm_text => q'^  utl_text_admin.merge_template(
    p_uttm_name => '#UTTM_NAME#',
    p_uttm_type => '#UTTM_TYPE#',
    p_uttm_mode => '#UTTM_MODE#',
    p_uttm_text => #UTTM_TEXT|||null#,
    p_uttm_log_text => #UTTM_LOG_TEXT|||null#,
    p_uttm_log_severity => #UTTM_LOG_SEVERITY|||null#
  );^',
    p_uttm_log_text => q'^^',
    p_uttm_log_severity => 70
  );
 
end;
/
set define on
