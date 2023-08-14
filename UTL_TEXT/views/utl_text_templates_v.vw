create or replace force view utl_text_templates_v as
select uttm_name, uttm_type, uttm_mode, uttm_text, uttm_log_text, uttm_log_severity
  from utl_text_templates;
