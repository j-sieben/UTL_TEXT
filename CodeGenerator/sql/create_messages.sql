begin
  pit_admin.merge_message_group(
    p_pmg_name => 'CODE_GEN',
    p_pmg_description => 'Parameter für den Code-Generator');
    
    
  pit_admin.merge_message(
    p_pms_name => 'INVALID_ANCHOR_NAMES',
    p_pms_text => q'^Bei Ausführung des CodeGenerators entsprachen folgende Ersetzungsanker nicht den Namenskonventionen: #1#^',
    p_pms_pse_id => 20,
    p_pms_pmg_name => 'CODE_GEN',
    p_pms_pml_name => 'GERMAN',
    p_error_number => null);
    
    
  pit_admin.merge_message(
    p_pms_name => 'MISSING_ANCHORS',
    p_pms_text => q'^Bei Ausführung des CodeGenerators fehlten folgende Ersetzungsanker: #1#^',
    p_pms_pse_id => 20,
    p_pms_pmg_name => 'CODE_GEN',
    p_pms_pml_name => 'GERMAN',
    p_error_number => null);
    
    
  pit_admin.merge_message(
    p_pms_name => 'NO_TEMPLATE',
    p_pms_text => q'^Kein Template gefunden.^',
    p_pms_pse_id => 30,
    p_pms_pmg_name => 'CODE_GEN',
    p_pms_pml_name => 'GERMAN',
    p_error_number => null);
    
    
  pit_admin.merge_message(
    p_pms_name => 'LOG_CONVERSION',
    p_pms_text => q'^#1#^',
    p_pms_pse_id => 70,
    p_pms_pmg_name => 'CODE_GEN',
    p_pms_pml_name => 'GERMAN',
    p_error_number => null);
    

  pit_admin.create_message_package;
end;
/
