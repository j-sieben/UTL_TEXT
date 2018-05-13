begin  
  pit_admin.merge_message(
    p_pms_name => 'CODE_GEN_MISSING_ANCHORS',
    p_pms_text => q'^Bei Ausführung des CodeGenerators fehlten folgende Ersetzungsanker: #1#^',
    p_pms_pse_id => 20,
    p_pms_pml_name => 'GERMAN'); 
    
  pit_admin.merge_message(
    p_pms_name => 'NO_TEMPLATE',
    p_pms_text => q'^Es wurde kein Template übergeben^',
    p_pms_pse_id => 20,
    p_pms_pml_name => 'GERMAN');
<<<<<<< HEAD
  pit_admin.merge_message(
    p_pms_name => 'CODE_GEN_NO_TEMPLATE',
    p_pms_text => q'^Es wurde kein Template �bergeben.^',
    p_pms_pse_id => 20,
    p_pms_pml_name => 'GERMAN');
  pit_admin.merge_message(
    p_pms_name => 'CODE_GEN_NO_SUCH_TEMPLATE',
    p_pms_text => q'^Das Template #1# ist nicht vorhanden.^',
    p_pms_pse_id => 20,
    p_pms_pml_name => 'GERMAN');
  pit_admin.merge_message(
    p_pms_name => 'CODE_GEN_NO_ROWS_FOUND',
    p_pms_text => q'^Es wurde kein Zeilen gefunden^',
    p_pms_pse_id => 20,
    p_pms_pml_name => 'GERMAN');
  pit_admin.merge_message(
    p_pms_name => 'CODE_GEN_LOG_MESSAGE',
    p_pms_text => q'^#1#^',
    p_pms_pse_id => 20,
    p_pms_pml_name => 'GERMAN');

=======
    
    
  pit_admin.merge_message(
    p_pms_name => 'PASS_INFORMATION',
    p_pms_text => q'^Das Template #1# ist nicht vorhanden^',
    p_pms_pse_id => 70,
    p_pms_pml_name => 'GERMAN'); 
    
>>>>>>> 3366522f4f398efd6ca6128b70a2eb24eb219aca
  pit_admin.create_message_package;
end;
/
