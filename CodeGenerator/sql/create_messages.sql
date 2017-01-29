begin
  pit_admin.merge_message(
    p_pms_name => 'CODE_GEN_MISSING_ANCHORS',
    p_pms_text => q'^Bei Ausführung des CodeGenerators fehlten folgende Ersetzungsanker: #1#^',
    p_pms_pse_id => 20,
    p_pms_pml_name => 'GERMAN');

  pit_admin.create_message_package;
end;
/
