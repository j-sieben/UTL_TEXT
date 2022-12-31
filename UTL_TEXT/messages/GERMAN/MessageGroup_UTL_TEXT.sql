begin

  pit_admin.merge_message_group(
    p_pmg_name => 'UTL_TEXT',
    p_pmg_description => q'^Messages for output module UTL_TEXT^');

  pit_admin.merge_message(
    p_pms_name => 'UTL_TEXT_INVALID_ANCHOR_NAMES',
    p_pms_pmg_name => 'UTL_TEXT',
    p_pms_text => q'^Bei Ausführung des CodeGenerators entsprachen folgende Ersetzungsanker nicht den Namenskonventionen: #1#^',
    p_pms_description => q'^Ersetzungsanker sind in zwei Namenskonventionen erlaubt: Rein numerisch (#1#, #2# etc.) oder gem. Oracle Namenskonventionen, etwa als Spaltenbezeichner. Stellen Sie sicher, dass alle Ersetzungsanker diesen Konventionen entsprechen.^',
    p_pms_pse_id => 30,
    p_pms_pml_name => 'GERMAN',
    p_error_number => -20000);

  pit_admin.merge_message(
    p_pms_name => 'UTL_TEXT_INVALID_PARAMETER_COMBI',
    p_pms_pmg_name => 'UTL_TEXT',
    p_pms_text => q'^Einrückungen sind nur erlaubt, wenn auch ein Trennzeichen definiert wurde.^',
    p_pms_description => q'^Einrückungen sind nur im Zusammenhang mit Trennzeichen sinnvoll. Im Ausnahmefall kann ein Leerzeichen als Trennzeichen vereinbart und von der Einrückung abgezogen werden.^',
    p_pms_pse_id => 30,
    p_pms_pml_name => 'GERMAN',
    p_error_number => -20000);

  pit_admin.merge_message(
    p_pms_name => 'UTL_TEXT_LOG_CONVERSION',
    p_pms_pmg_name => 'UTL_TEXT',
    p_pms_text => q'^#1#^',
    p_pms_description => q'^Platzhlater-Template für beliebige Informationen^',
    p_pms_pse_id => 70,
    p_pms_pml_name => 'GERMAN',
    p_error_number => null);

  pit_admin.merge_message(
    p_pms_name => 'UTL_TEXT_MISSING_ANCHORS',
    p_pms_pmg_name => 'UTL_TEXT',
    p_pms_text => q'^Bei Ausführung des CodeGenerators fehlten folgende Ersetzungsanker: #1#^',
    p_pms_description => q'^Falls der CodeGenerator so konfiguriert wurde, erwartet er, dass für alle Ersetzungsanke auch Ersetzungszeichenfolgen angeboten werden. Das ist hier nicht der Fall.^',
    p_pms_pse_id => 20,
    p_pms_pml_name => 'GERMAN',
    p_error_number => -20000);

  pit_admin.merge_message(
    p_pms_name => 'UTL_TEXT_NO_TEMPLATE',
    p_pms_pmg_name => 'UTL_TEXT',
    p_pms_text => q'^Keine Templates gefunden.^',
    p_pms_description => q'^Ein Template, das in der SQL-Abfrage angesprochen wurde, konnte nicht gefunden werden.^',
    p_pms_pse_id => 30,
    p_pms_pml_name => 'GERMAN',
    p_error_number => -20000);

  commit;
  pit_admin.create_message_package;
end;
/