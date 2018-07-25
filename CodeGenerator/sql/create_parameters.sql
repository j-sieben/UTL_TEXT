begin
  param_admin.edit_parameter_group(
    p_pgr_id => 'CODE_GEN',
    p_pgr_description => 'Parameter for CodeGenerator',
    p_pgr_is_modifiable => true);
   
  param_admin.edit_parameter(
    p_par_id => 'IGNORE_MISSING_ANCHORS',
    p_par_pgr_id => 'CODE_GEN',
	  p_par_description => 'Flag to indicate whether missing anchors shall raise an error or not',
    p_par_boolean_value => true
    );
   
  param_admin.edit_parameter(
    p_par_id => 'DEFAULT_DELIMITER_CHAR',
    p_par_pgr_id => 'CODE_GEN',
	  p_par_description => 'Char that is used to delimit several rows',
    p_par_string_value => chr(10)
    );
   
  param_admin.edit_parameter(
    p_par_id => 'MAIN_ANCHOR_CHAR',
    p_par_pgr_id => 'CODE_GEN',
	  p_par_description => 'Char that is used to detect beginning and end of a replacmente anchor',
    p_par_string_value => '#', 
    p_par_validation_string => q'^length('#STRING#') = 1^',
    p_par_validation_message => q'^Es ist nur ein Zeichen erlaubt^'
    );
   
  param_admin.edit_parameter(
    p_par_id => 'MAIN_SEPARATOR_CHAR',
    p_par_pgr_id => 'CODE_GEN',
	  p_par_description => 'Char that is used to detect further attributes of a replacmente anchor',
    p_par_string_value => '|', 
    p_par_validation_string => q'^length('#STRING#') = 1^',
    p_par_validation_message => q'^Es ist nur ein Zeichen erlaubt^'
    );
   
  param_admin.edit_parameter(
    p_par_id => 'SECONDARY_ANCHOR_CHAR',
    p_par_pgr_id => 'CODE_GEN',
	  p_par_description => 'Char that is used to escape beginning and end of a replacmente anchor',
    p_par_string_value => '^', 
    p_par_validation_string => q'^length('#STRING#') = 1^',
    p_par_validation_message => q'^Es ist nur ein Zeichen erlaubt^'
    );
   
  param_admin.edit_parameter(
    p_par_id => 'SECONDARY_SEPARATOR_CHAR',
    p_par_pgr_id => 'CODE_GEN',
	  p_par_description => 'Char that is used to escape further attributes of a replacmente anchor',
    p_par_string_value => '~', 
    p_par_validation_string => q'^length('#STRING#') = 1^',
    p_par_validation_message => q'^Es ist nur ein Zeichen erlaubt^'
    );
   
  param_admin.edit_parameter(
    p_par_id => 'DEFAULT_DATE_FORMAT',
    p_par_pgr_id => 'CODE_GEN',
	  p_par_description => 'Date format that is used for date conversions',
    p_par_string_value => 'YYYY-MM-DD HH24:MI:SS', 
    p_par_validation_string => q'^to_char(sysdate, '#STRING#') is not null^'
    );
    
  commit;
end;
/