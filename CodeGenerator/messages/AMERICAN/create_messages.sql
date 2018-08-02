begin
  pit_admin.merge_message_group(
    p_pmg_name => 'CODE_GEN',
    p_pmg_description => 'Parameter für den Code-Generator');
    
    
  pit_admin.merge_message(
    p_pms_name => 'INVALID_ANCHOR_NAMES',
    p_pms_text => q'^the following replacement anchors dont adhere to the naming conventions: #1#^',
    p_pms_description => q'^Tow name schemes for replacement anchors are allowed: numeric (#1#, #2# etc.) or according to Oracle naming convention, e.g. as a column name. Assure that all replacement anchor names comply with these conventions.^',
    p_pms_pse_id => 20,
    p_pms_pmg_name => 'CODE_GEN',
    p_pms_pml_name => 'AMERICAN',
    p_error_number => null);
    
    
  pit_admin.merge_message(
    p_pms_name => 'MISSING_ANCHORS',
    p_pms_text => q'^The following replacement anchors are missing: #1#^',
    p_pms_description => q'^If configured that way, CodeGenerator expects a replacement char for any replacement anchor. For the given anchors, this wasn't true..^',
    p_pms_pse_id => 20,
    p_pms_pmg_name => 'CODE_GEN',
    p_pms_pml_name => 'AMERICAN',
    p_error_number => null);
    
    
  pit_admin.merge_message(
    p_pms_name => 'NO_TEMPLATE',
    p_pms_text => q'^No template found.^',
    p_pms_description => q'^A template that was referenced in the SQL query couldn't be found.^',
    p_pms_pse_id => 30,
    p_pms_pmg_name => 'CODE_GEN',
    p_pms_pml_name => 'AMERICAN',
    p_error_number => null);
    
    
  pit_admin.merge_message(
    p_pms_name => 'LOG_CONVERSION',
    p_pms_text => q'^#1#^',
    p_pms_description => q'^Placeholder-Template to pass any log information^',
    p_pms_pse_id => 70,
    p_pms_pmg_name => 'CODE_GEN',
    p_pms_pml_name => 'AMERICAN',
    p_error_number => null);
    
    
  pit_admin.merge_message(
    p_pms_name => 'INVALID_PARAMETER_COMBI',
    p_pms_text => q'^indents are allowed only when a delimiter is present.^',
    p_pms_description => q'^Indents are useful only if a delimiter is present. To cirucmvent this, you may define a blank as a delimiter and deduct this from the indent.^',
    p_pms_pse_id => 30,
    p_pms_pmg_name => 'CODE_GEN',
    p_pms_pml_name => 'AMERICAN',
    p_error_number => null);
    

  pit_admin.create_message_package;
end;
/
