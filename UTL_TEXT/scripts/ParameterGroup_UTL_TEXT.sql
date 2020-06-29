begin

  param_admin.edit_parameter_group(
    p_pgr_id => 'UTL_TEXT',
    p_pgr_description => 'Parameter for CodeGenerator',
    p_pgr_is_modifiable => true
  );

  param_admin.edit_parameter(
    p_par_id => 'DEFAULT_DATE_FORMAT'
   ,p_par_pgr_id => 'UTL_TEXT'
   ,p_par_description => 'Date format that is used for date conversions'
  );

  param_admin.edit_parameter(
    p_par_id => 'DEFAULT_DELIMITER_CHAR'
   ,p_par_pgr_id => 'UTL_TEXT'
   ,p_par_description => 'Char that is used to delimit several rows'
  );

  param_admin.edit_parameter(
    p_par_id => 'IGNORE_MISSING_ANCHORS'
   ,p_par_pgr_id => 'UTL_TEXT'
   ,p_par_description => 'Flag to indicate whether missing anchors raise an error or not'
  );

  param_admin.edit_parameter(
    p_par_id => 'MAIN_ANCHOR_CHAR'
   ,p_par_pgr_id => 'UTL_TEXT'
   ,p_par_description => 'Char that is used to detect beginning and end of a replacmente anchor'
  );

  param_admin.edit_parameter(
    p_par_id => 'MAIN_SEPARATOR_CHAR'
   ,p_par_pgr_id => 'UTL_TEXT'
   ,p_par_description => 'Char that is used to detect further attributes of a replacmente anchor'
  );

  param_admin.edit_parameter(
    p_par_id => 'SECONDARY_ANCHOR_CHAR'
   ,p_par_pgr_id => 'UTL_TEXT'
   ,p_par_description => 'Char that is used to escape beginning and end of a replacmente anchor'
  );

  param_admin.edit_parameter(
    p_par_id => 'SECONDARY_SEPARATOR_CHAR'
   ,p_par_pgr_id => 'UTL_TEXT'
   ,p_par_description => 'Char that is used to escape further attributes of a replacmente anchor'
  );

  commit;
end;
/