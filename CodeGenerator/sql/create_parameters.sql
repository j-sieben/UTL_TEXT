begin
  param_admin.edit_parameter_group(
    p_pgr_id => 'CODE_GEN',
    p_pgr_description => 'Parameter for CodeGenerator',
    p_pgr_is_modifiable => true);
   
  param_admin.edit_parameter(
    p_par_id => 'MAIN_ANCHOR_CHAR',
    p_par_pgr_id => 'CODE_GEN',
	  p_par_description => 'Char that is used to detect beginning and end of a replacmente anchor',
    p_par_string_value => '#'
    );
   
  param_admin.edit_parameter(
    p_par_id => 'MAIN_SEPARATOR_CHAR',
    p_par_pgr_id => 'CODE_GEN',
	  p_par_description => 'Char that is used to detect further attributes of a replacmente anchor',
    p_par_string_value => '|'
    );
   
  param_admin.edit_parameter(
    p_par_id => 'SECONDARY_ANCHOR_CHAR',
    p_par_pgr_id => 'CODE_GEN',
	  p_par_description => 'Char that is used to escape beginning and end of a replacmente anchor',
    p_par_string_value => '^'
    );
   
  param_admin.edit_parameter(
    p_par_id => 'SECONDARY_SEPARATOR_CHAR',
    p_par_pgr_id => 'CODE_GEN',
	  p_par_description => 'Char that is used to escape further attributes of a replacmente anchor',
    p_par_string_value => '~'
    );
    
  commit;
end;
/