create or replace package body ut_code_generator 
as

  procedure init_test
  as
  begin
    code_generator.initialize;
  end init_test;


  procedure test_date_format
  as
  begin
    ut.expect(code_generator.get_default_date_format).to_equal(param.get_string('DEFAULT_DATE_FORMAT', 'CODE_GEN'));
  end test_date_format;


  procedure test_main_anchor
  as
  begin
    ut.expect(code_generator.get_main_anchor_char).to_equal(param.get_string('MAIN_ANCHOR_CHAR', 'CODE_GEN'));
  end test_main_anchor;


  procedure test_second_anchor
  as
  begin
    ut.expect(code_generator.get_secondary_anchor_char).to_equal(param.get_string('SECONDARY_ANCHOR_CHAR', 'CODE_GEN'));
  end test_second_anchor;


  procedure test_main_separator
  as
  begin
    ut.expect(code_generator.get_main_separator_char).to_equal(param.get_string('MAIN_SEPARATOR_CHAR', 'CODE_GEN'));
  end test_main_separator;


  procedure test_second_seaparator
  as
  begin
    ut.expect(code_generator.get_secondary_separator_char).to_equal(param.get_string('SECONDARY_SEPARATOR_CHAR', 'CODE_GEN'));
  end test_second_seaparator;
  
  
  procedure set_date_format
  as
    l_date_format varchar2(20) := 'dd.mm.yyyy';
  begin
    code_generator.set_default_date_format(l_date_format);
    ut.expect(code_generator.get_default_date_format).to_equal(l_date_format);
  end set_date_format;


  procedure set_main_anchor
  as
    l_anchor char(1 char) := '|';
  begin
    code_generator.set_main_anchor_char(l_anchor);
    ut.expect(code_generator.get_main_anchor_char).to_equal(l_anchor);
  end set_main_anchor;


  procedure set_second_anchor
  as
    l_anchor char(1 char) := '|';
  begin
    code_generator.set_secondary_anchor_char(l_anchor);
    ut.expect(code_generator.get_secondary_anchor_char).to_equal(l_anchor);
  end set_second_anchor;


  procedure set_main_separator
  as
    l_anchor char(1 char) := '|';
  begin
    code_generator.set_main_separator_char(l_anchor);
    ut.expect(code_generator.get_main_separator_char).to_equal(l_anchor);
  end set_main_separator;


  procedure set_second_seaparator
  as
    l_anchor char(1 char) := '|';
  begin
    code_generator.set_secondary_separator_char(l_anchor);
    ut.expect(code_generator.get_secondary_separator_char).to_equal(l_anchor);
  end set_second_seaparator;


  procedure test_ignore_flag
  as
  begin
    ut.expect(code_generator.get_ignore_missing_anchors).to_equal(param.get_string('IGNORE_MISSING_ANCHORS', 'CODE_GEN'));
  end test_ignore_flag;


  procedure simple_bulk is
  begin
    ut.expect(to_char(code_generator.bulk_replace('Das ist ein #TEST#', char_table('TEST', 'Test')))).to_equal('Das ist ein Test');
  end simple_bulk;


  procedure simple_bulk_number is
  begin
    ut.expect(
      to_char(code_generator.bulk_replace('Das ist ein #1#', char_table('1', 'Test')))
      ).to_equal('Das ist ein Test');
  end simple_bulk_number;


  procedure simple_bulk_two_anchors is
  begin
    ut.expect(
      to_char(code_generator.bulk_replace('Das ist ein #1# mit zwei #TWO#', char_table('1', 'Test', 'TWO', 'Ankern')))
      ).to_equal('Das ist ein Test mit zwei Ankern');
  end simple_bulk_two_anchors;


  procedure simple_bulk_missing_anchor 
  as
    l_result varchar2(32767);
  begin
    code_generator.set_ignore_missing_anchors(false);
    l_result := to_char(code_generator.bulk_replace('Das ist ein #1#', char_table('1', 'Test', 'TWO', 'Ankern')));
  end simple_bulk_missing_anchor;


  procedure simple_bulk_too_many_anchors 
  as
  begin
    code_generator.set_ignore_missing_anchors(false);
    ut.expect(
      to_char(code_generator.bulk_replace('Das ist ein #1# mit #2#', char_table('1', 'Test')))
      ).to_equal('Das ist ein Test mit #2#');
  end simple_bulk_too_many_anchors;
  
  
  procedure complex_bulk_null_handling
  as
  begin
    ut.expect(
      to_char(
        code_generator.bulk_replace(
          'Das ist ein #1|Pre|Post|NULL# mit #2|Pre|Post|NULL#', 
          char_table('1', 'Test', '2', null)))
      ).to_equal('Das ist ein PreTestPost mit NULL');
  end complex_bulk_null_handling;
  
  
  procedure complex_bulk_recursive
  as
  begin
    ut.expect(
      to_char(
        code_generator.bulk_replace(
          'Das ist ein #1#', 
          char_table('1', 'Test mit #2#', '2', 'Rekursion')))
      ).to_equal('Das ist ein Test mit Rekursion');
  end complex_bulk_recursive;
  
  
  procedure complex_bulk_recursive_if_null
  as
    l_replacement varchar2(100);
  begin
    l_replacement := 'Das ist ein #1|||^2^#';
    ut.expect(
      to_char(
        code_generator.bulk_replace(
          l_replacement, 
          char_table('1', null, '2', 'Rekursion')))
      ).to_equal('Das ist ein Rekursion');
  end complex_bulk_recursive_if_null;
  
  
  procedure complex_bulk_recursive_and_null
  as
    l_replacement varchar2(100);
  begin
    l_replacement := 'Das ist #1|ein ||^2~eine ~~^#';
    ut.expect(
      to_char(
        code_generator.bulk_replace(
          l_replacement, 
          char_table('1', null, '2', 'Rekursion')))
      ).to_equal('Das ist eine Rekursion');
  end complex_bulk_recursive_and_null;
  
  
  procedure complex_bulk_switch_marker
  as
    l_replacement varchar2(100);
  begin
    code_generator.set_main_anchor_char('|');
    code_generator.set_main_separator_char('~');
    code_generator.set_secondary_anchor_char('°');
    code_generator.set_secondary_separator_char('*');
    code_generator.set_ignore_missing_anchors(false);
    l_replacement := 'Das ist |ONE~ein ~~|';
    ut.expect(
      to_char(
        code_generator.bulk_replace(
          l_replacement, 
          char_table('|ONE|', 'Test')))
      ).to_equal('Das ist ein Test');
  end complex_bulk_switch_marker;
  
  
  procedure complex_bulk_switch_marker_and_null
  as
    l_replacement varchar2(100);
  begin
    code_generator.set_main_anchor_char('|');
    code_generator.set_main_separator_char('~');
    code_generator.set_secondary_anchor_char('°');
    code_generator.set_secondary_separator_char('*');
    code_generator.set_ignore_missing_anchors(false);
    l_replacement := 'Das ist |ONE~ein ~~°TWO*eine **°|';
    ut.expect(
      to_char(
        code_generator.bulk_replace(
          l_replacement, 
          char_table('|ONE|', null, 'TWO', 'Rekursion')))
      ).to_equal('Das ist eine Rekursion');
  end complex_bulk_switch_marker_and_null;
  
  
  procedure simple_text
  as
    l_result varchar2(32767);
  begin
    select code_generator.generate_text(cursor(
             select 'Das ist ein #FOO#' template,
                    'Test' foo
               from dual))
      into l_result
      from dual;
    ut.expect(l_result).to_equal('Das ist ein Test');
  end simple_text;
  
  
  procedure simple_text_two_anchors
  as
    l_result varchar2(32767);
  begin
    select code_generator.generate_text(cursor(
             select 'Das ist ein #FOO# mit zwei #ANCHOR#' template,
                    'Test' foo,
                    'Ankern' anchor
               from dual))
      into l_result
      from dual;
    ut.expect(l_result).to_equal('Das ist ein Test mit zwei Ankern');
  end simple_text_two_anchors;
  
  
  procedure simple_text_missing_anchor
  as
    l_result varchar2(32767);
  begin
    code_generator.set_ignore_missing_anchors(false);
    select code_generator.generate_text(cursor(
             select 'Das ist ein #FOO# mit zwei #ANCHOR#' template,
                    'Test' foo
               from dual))
      into l_result
      from dual;
  end simple_text_missing_anchor;
  
  
  procedure simple_text_too_many_anchors
  as
    l_result varchar2(32767);
  begin
    select code_generator.generate_text(cursor(
             select 'Das ist ein #FOO#' template,
                    'Test' foo,
                    'Ankern' anchor
               from dual))
      into l_result
      from dual;
    ut.expect(l_result).to_equal('Das ist ein Test');
  end simple_text_too_many_anchors;
  
  
  procedure complex_text
  as
    l_result varchar2(32767);
  begin
    select code_generator.generate_text(cursor(
             select '<Result>#INNER_TEXT#</Result>' template,
                    code_generator.generate_text(cursor(
                      select '<A>#VAL#</A>' template, '1' val from dual union all
                      select '<B>#VAL#</B>' template, '2' val from dual union all
                      select '<C>#VAL#</C>' template, '3' val from dual
                    )) inner_text
               from dual))
      into l_result
      from dual;
    ut.expect(l_result).to_equal('<Result><A>1</A><B>2</B><C>3</C></Result>');
  end complex_text;

end ut_code_generator;
/
