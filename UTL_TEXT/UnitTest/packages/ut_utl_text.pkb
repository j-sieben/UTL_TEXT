create or replace package body ut_utl_text 
as

  procedure init_test
  as
  begin
    utl_text.initialize;
  end init_test;


  procedure test_date_format
  as
  begin
    ut.expect(utl_text.get_default_date_format).to_equal(param.get_string('DEFAULT_DATE_FORMAT', 'CODE_GEN'));
  end test_date_format;


  procedure test_main_anchor
  as
  begin
    ut.expect(utl_text.get_main_anchor_char).to_equal(param.get_string('MAIN_ANCHOR_CHAR', 'CODE_GEN'));
  end test_main_anchor;


  procedure test_second_anchor
  as
  begin
    ut.expect(utl_text.get_secondary_anchor_char).to_equal(param.get_string('SECONDARY_ANCHOR_CHAR', 'CODE_GEN'));
  end test_second_anchor;


  procedure test_main_separator
  as
  begin
    ut.expect(utl_text.get_main_separator_char).to_equal(param.get_string('MAIN_SEPARATOR_CHAR', 'CODE_GEN'));
  end test_main_separator;


  procedure test_second_seaparator
  as
  begin
    ut.expect(utl_text.get_secondary_separator_char).to_equal(param.get_string('SECONDARY_SEPARATOR_CHAR', 'CODE_GEN'));
  end test_second_seaparator;


  procedure test_delimiter_char
  as
  begin
    ut.expect(utl_text.get_default_delimiter_char).to_equal(param.get_string('DEFAULT_DELIMITER_CHAR', 'CODE_GEN'));
  end test_delimiter_char;
  
  
  procedure set_date_format
  as
    l_date_format varchar2(20) := 'dd.mm.yyyy';
  begin
    utl_text.set_default_date_format(l_date_format);
    ut.expect(utl_text.get_default_date_format).to_equal(l_date_format);
  end set_date_format;


  procedure set_main_anchor
  as
    l_anchor char(1 char) := '|';
  begin
    utl_text.set_main_anchor_char(l_anchor);
    ut.expect(utl_text.get_main_anchor_char).to_equal(l_anchor);
  end set_main_anchor;


  procedure set_second_anchor
  as
    l_anchor char(1 char) := '|';
  begin
    utl_text.set_secondary_anchor_char(l_anchor);
    ut.expect(utl_text.get_secondary_anchor_char).to_equal(l_anchor);
  end set_second_anchor;


  procedure set_main_separator
  as
    l_anchor char(1 char) := '|';
  begin
    utl_text.set_main_separator_char(l_anchor);
    ut.expect(utl_text.get_main_separator_char).to_equal(l_anchor);
  end set_main_separator;


  procedure set_second_seaparator
  as
    l_anchor char(1 char) := '|';
  begin
    utl_text.set_secondary_separator_char(l_anchor);
    ut.expect(utl_text.get_secondary_separator_char).to_equal(l_anchor);
  end set_second_seaparator;


  procedure set_delimiter_char
  as
    l_anchor char(1 char) := '|';
  begin
    utl_text.set_default_delimiter_char(l_anchor);
    ut.expect(utl_text.get_default_delimiter_char).to_equal(l_anchor);
  end set_delimiter_char;
  
  
  procedure test_initialize
  as
  begin
    utl_text.set_default_delimiter_char('-');
    utl_text.initialize;
    ut.expect(utl_text.get_default_delimiter_char).to_equal(param.get_string('DEFAULT_DELIMITER_CHAR', 'CODE_GEN'));
  end test_initialize;

  procedure test_ignore_flag
  as
  begin
    ut.expect(utl_text.get_ignore_missing_anchors).to_equal(param.get_string('IGNORE_MISSING_ANCHORS', 'CODE_GEN'));
  end test_ignore_flag;


  procedure simple_bulk 
  as
  begin
    ut.expect(to_char(utl_text.bulk_replace('Das ist ein #TEST#', char_table('TEST', 'Test')))).to_equal('Das ist ein Test');
  end simple_bulk;


  procedure simple_bulk_proc 
  as
    l_template varchar2(32767);
  begin
    l_template := 'Das ist ein #TEST#';
    utl_text.bulk_replace(l_template, char_table('TEST', 'Test'));
    ut.expect(l_template).to_equal('Das ist ein Test');
  end simple_bulk_proc;


  procedure simple_bulk_number is
  begin
    ut.expect(
      to_char(utl_text.bulk_replace('Das ist ein #1#', char_table('1', 'Test')))
      ).to_equal('Das ist ein Test');
  end simple_bulk_number;


  procedure simple_bulk_two_anchors is
  begin
    ut.expect(
      to_char(utl_text.bulk_replace('Das ist ein #1# mit zwei #TWO#', char_table('1', 'Test', 'TWO', 'Ankern')))
      ).to_equal('Das ist ein Test mit zwei Ankern');
  end simple_bulk_two_anchors;


  procedure simple_bulk_missing_anchor 
  as
    l_result varchar2(32767);
  begin
    utl_text.set_ignore_missing_anchors(false);
    l_result := to_char(utl_text.bulk_replace('Das ist ein #1#', char_table('1', 'Test', 'TWO', 'Ankern')));
  end simple_bulk_missing_anchor;


  procedure simple_bulk_too_many_anchors 
  as
  begin
    utl_text.set_ignore_missing_anchors(false);
    ut.expect(
      to_char(utl_text.bulk_replace('Das ist ein #1# mit #2#', char_table('1', 'Test')))
      ).to_equal('Das ist ein Test mit #2#');
  end simple_bulk_too_many_anchors;


  procedure simple_bulk_invalid_anchor
  as
    l_result varchar2(32767);
  begin
    utl_text.set_ignore_missing_anchors(false);
    l_result := to_char(utl_text.bulk_replace('Das ist ein #1_COL#', char_table('1_COL', 'Test')));
  end simple_bulk_invalid_anchor;


  procedure simple_bulk_no_template
  as
    l_result varchar2(32767);
  begin
    l_result := utl_text.bulk_replace(null, char_table('1_COL', 'Test'));
  end simple_bulk_no_template;
  
  
  procedure complex_bulk_null_handling
  as
  begin
    ut.expect(
      to_char(
        utl_text.bulk_replace(
          'Das ist ein #1|Pre|Post|NULL# mit #2|Pre|Post|NULL#', 
          char_table('1', 'Test', '2', null)))
      ).to_equal('Das ist ein PreTestPost mit NULL');
  end complex_bulk_null_handling;
  
  
  procedure complex_bulk_recursive
  as
  begin
    ut.expect(
      to_char(
        utl_text.bulk_replace(
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
        utl_text.bulk_replace(
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
        utl_text.bulk_replace(
          l_replacement, 
          char_table('1', null, '2', 'Rekursion')))
      ).to_equal('Das ist eine Rekursion');
  end complex_bulk_recursive_and_null;
  
  
  procedure complex_bulk_switch_marker
  as
    l_replacement varchar2(100);
  begin
    utl_text.set_main_anchor_char('|');
    utl_text.set_main_separator_char('~');
    utl_text.set_secondary_anchor_char('°');
    utl_text.set_secondary_separator_char('*');
    utl_text.set_ignore_missing_anchors(false);
    l_replacement := 'Das ist |ONE~ein ~~|';
    ut.expect(
      to_char(
        utl_text.bulk_replace(
          l_replacement, 
          char_table('|ONE|', 'Test')))
      ).to_equal('Das ist ein Test');
  end complex_bulk_switch_marker;
  
  
  procedure complex_bulk_switch_marker_and_null
  as
    l_replacement varchar2(100);
  begin
    utl_text.set_main_anchor_char('|');
    utl_text.set_main_separator_char('~');
    utl_text.set_secondary_anchor_char('°');
    utl_text.set_secondary_separator_char('*');
    utl_text.set_ignore_missing_anchors(false);
    l_replacement := 'Das ist |ONE~ein ~~°TWO*eine **°|';
    ut.expect(
      to_char(
        utl_text.bulk_replace(
          l_replacement, 
          char_table('|ONE|', null, 'TWO', 'Rekursion')))
      ).to_equal('Das ist eine Rekursion');
  end complex_bulk_switch_marker_and_null;
  
  
  procedure simple_text
  as
    l_result varchar2(32767);
  begin
    select utl_text.generate_text(cursor(
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
    select utl_text.generate_text(cursor(
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
    utl_text.set_ignore_missing_anchors(false);
    select utl_text.generate_text(cursor(
             select 'Das ist ein #FOO# mit zwei #ANCHOR#' template,
                    'Test' foo
               from dual))
      into l_result
      from dual;
  end simple_text_missing_anchor;
  
  
  procedure simple_different_template_name
  as
    l_result varchar2(32767);
  begin
    utl_text.set_ignore_missing_anchors(false);
    select utl_text.generate_text(cursor(
             select to_clob(null) some_name,
                    'Test' foo
               from dual))
      into l_result
      from dual;
  end simple_different_template_name;
  
  
  procedure simple_text_no_template
  as
    l_result varchar2(32767);
  begin
    utl_text.set_ignore_missing_anchors(false);
    select utl_text.generate_text(cursor(
             select to_clob(null) template,
                    'Test' foo
               from dual))
      into l_result
      from dual;
  end simple_text_no_template;
  
  
  procedure simple_text_too_many_anchors
  as
    l_result varchar2(32767);
  begin
    select utl_text.generate_text(cursor(
             select 'Das ist ein #FOO#' template,
                    'Test' foo,
                    'Ankern' anchor
               from dual))
      into l_result
      from dual;
    ut.expect(l_result).to_equal('Das ist ein Test');
  end simple_text_too_many_anchors;
  
  
  procedure simple_text_date_column
  as
    l_result varchar2(32767);
    l_reference varchar2(50 char);
    l_now date;
  begin
    l_now := sysdate;
    select utl_text.generate_text(cursor(
             select '#DATE_COL#' template,
                    sysdate date_col
               from dual))
      into l_result
      from dual;
    l_reference := to_char(l_now, utl_text.get_default_date_format);
    ut.expect(l_result).to_equal(l_reference);
  end simple_text_date_column;
  
  
  procedure simple_text_formatted_date_column
  as
    l_result varchar2(32767);
    l_reference varchar2(50 char);
    l_now date;
  begin
    l_now := sysdate;
    utl_text.set_default_date_format('dd.mm.yyyy');
    select utl_text.generate_text(cursor(
             select '#DATE_COL#' template,
                    sysdate date_col
               from dual))
      into l_result
      from dual;
    l_reference := to_char(l_now, utl_text.get_default_date_format);
    ut.expect(l_result).to_equal(l_reference);
  end simple_text_formatted_date_column;
  
  
  procedure simple_text_with_indent
  as
    l_result varchar2(32767);
  begin
    select utl_text.generate_text(cursor(
             select 'Das ist ein #COL#' template, 'Test' col
               from dual), null, 5) result
      into l_result
      from dual;
    ut.expect(l_result).to_equal('Das ist ein Test');
  end simple_text_with_indent;
  
  
  procedure simple_text_invalid_params
  as
    l_result varchar2(32767);
  begin
    select utl_text.generate_text(cursor(
             select '#FOO#' template
               from dual), utl_text.c_no_delimiter, 5)
      into l_result
      from dual;
  end simple_text_invalid_params;
  
  
  procedure simple_text_overload
  as
    l_result varchar2(32767);
  begin
    l_result := to_char(utl_text.generate_text(
                  p_template => 'Text with #A#, #B#',
                  p_stmt => q'^select 'One' a, 'Two' b from dual^'));
    ut.expect(l_result).to_equal('Text with One, Two');
  end simple_text_overload;
  
  
  procedure complex_text_with_indent
  as
    l_result varchar2(32767);
  begin
    select utl_text.generate_text(cursor(
             select 'Das ist ein #COL#' template, 'Test' col from dual union all
             select 'Das ist ein #COL#' template, 'Test' col from dual
             ), '|', 5) result
      into l_result
      from dual;
    ut.expect(l_result).to_equal('Das ist ein Test|     Das ist ein Test');
  end complex_text_with_indent;
  
  
  procedure complex_text_with_default_indent
  as
    l_result varchar2(32767);
  begin
    select utl_text.generate_text(cursor(
             select 'Das ist ein #COL#' template, 'Test' col from dual union all
             select 'Das ist ein #COL#' template, 'Test' col from dual
             ), null, 5) result
      into l_result
      from dual;
    ut.expect(l_result).to_equal('Das ist ein Test' || utl_text.get_default_delimiter_char || '     Das ist ein Test');
  end complex_text_with_default_indent;
  
  
  procedure complex_text
  as
    l_result varchar2(32767);
  begin
    select utl_text.generate_text(cursor(
             select '<Result>#INNER_TEXT#</Result>' template,
                    utl_text.generate_text(cursor(
                      select '<A>#VAL#</A>' template, '1' val from dual union all
                      select '<B>#VAL#</B>' template, '2' val from dual union all
                      select '<C>#VAL#</C>' template, '3' val from dual
                    ), utl_text.c_no_delimiter) inner_text
               from dual))
      into l_result
      from dual;
    ut.expect(l_result).to_equal('<Result><A>1</A><B>2</B><C>3</C></Result>');
  end complex_text;
  
  
  procedure complex_text_with_indent_and_format
  as
    l_result varchar2(32767);
  begin
    select utl_text.generate_text(cursor(
             select '<Result>#CR#  #INNER_TEXT##CR#</Result>' template,
                    utl_text.get_default_delimiter_char cr,
                    utl_text.generate_text(cursor(
                      select '<A>#VAL#</A>' template, '1' val from dual union all
                      select '<B>#VAL#</B>' template, '2' val from dual union all
                      select '<C>#VAL#</C>' template, '3' val from dual
                    ), null, 2) inner_text
               from dual))
      into l_result
      from dual;
    ut.expect(l_result).to_equal(q'^<Result>
  <A>1</A>
  <B>2</B>
  <C>3</C>
</Result>^');
  end complex_text_with_indent_and_format;
  
  
  procedure complex_text_with_logging
  as
    l_result varchar2(32767);
  begin
    pit.set_context(70,10,false,'PIT_CONSOLE');
    select utl_text.generate_text(cursor(
             select '<Result>#CR#  #INNER_TEXT##CR#</Result>' template,
                    'XML created: <Result>#CR#  #INNER_TEXT##CR#</Result>' log_template,
                    utl_text.get_default_delimiter_char cr,
                    utl_text.generate_text(cursor(
                      select '<A>#VAL#</A>' template, '1' val from dual union all
                      select '<B>#VAL#</B>' template, '2' val from dual union all
                      select '<C>#VAL#</C>' template, '3' val from dual
                    ), null, 2) inner_text
               from dual))
      into l_result
      from dual;
    pit.reset_context;
    ut.expect(l_result).to_equal(q'^<Result>
  <A>1</A>
  <B>2</B>
  <C>3</C>
</Result>^');
  end complex_text_with_logging;
  
  
  procedure simple_text_table
  as
    l_result clob_table;
    l_cur sys_refcursor;
    l_cnt pls_integer;
  begin
    select count(*)
      into l_cnt
      from table(
             select utl_text.generate_text_table(cursor(
                      select '#VAL#' template, '1' val from dual union all
                      select '#VAL#' template, '2' val from dual union all
                      select '#VAL#' template, '3' val from dual))
               from dual);
               
    ut.expect(l_cnt).to_equal(3);
  end simple_text_table;
  
  
  procedure simple_text_table_with_logging
  as
    l_result clob_table;
    l_cur sys_refcursor;
    l_cnt pls_integer;
  begin
    pit.set_context(70,10,false,'PIT_CONSOLE');
    select count(*)
      into l_cnt
      from table(
             select utl_text.generate_text_table(cursor(
                        with p as(
                             select '#VAL#' template, 
                                    'Text #VAL# generated' log_template
                               from dual),
                             v as (
                             select level val
                               from dual
                            connect by level <=3)
                      select template, log_template, val 
                        from p cross join v))
               from dual);
    pit.reset_context;
               
    ut.expect(l_cnt).to_equal(3);
  end simple_text_table_with_logging;
  
  
  procedure read_anchors_from_template
  as
    l_anchor_list varchar2(300);
  begin
    insert into utl_text_templates(cgtm_name, cgtm_type, cgtm_text)
    values ('TEST', 'TEST', 'Template with replacement anchors #ONE|PRE|POST|NULL#, #TWO# and #THREE#');
    
    select listagg(column_value, ':') within group (order by column_value)
      into l_anchor_list
      from table(utl_text.get_anchors('TEST', 'TEST', 'DEFAULT'));
    
    delete from utl_text_templates
     where cgtm_name = 'TEST'
       and cgtm_type = 'TEST'
       and cgtm_mode = 'DEFAULT';
       
    ut.expect(l_anchor_list).to_equal('ONE:THREE:TWO');
  end read_anchors_from_template;
  
  
  procedure read_complete_anchors_from_template
  as
    l_anchor_list varchar2(300);
  begin
    insert into utl_text_templates(cgtm_name, cgtm_type, cgtm_text)
    values ('TEST', 'TEST', 'Template with replacement anchors #ONE|PRE|POST|NULL#, #TWO# and #THREE#');
    
    select listagg(column_value, ':') within group (order by column_value)
      into l_anchor_list
      from table(utl_text.get_anchors('TEST', 'TEST', 'DEFAULT', 1));
    
    delete from utl_text_templates
     where cgtm_name = 'TEST'
       and cgtm_type = 'TEST'
       and cgtm_mode = 'DEFAULT';
       
    ut.expect(l_anchor_list).to_equal('#ONE|PRE|POST|NULL#:#THREE#:#TWO#');
  end read_complete_anchors_from_template;

end ut_utl_text;
/
