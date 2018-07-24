create or replace package ut_code_generator 
  authid definer
as

  -- %suite(Code Generator package)
  
  -- %beforeeach
  procedure init_test;

  -- %context(INITIALIZATION tests)

  -- %test(Has correct date format)
  procedure test_date_format;

  -- %test(Has correct main anchor char)
  procedure test_main_anchor;

  -- %test(Has correct second anchor char)
  procedure test_second_anchor;

  -- %test(Has correct main replacement char)
  procedure test_main_separator;

  -- %test(Has correct second replacement char)
  procedure test_second_seaparator;

  -- %test(Date format is changeable)
  procedure set_date_format;

  -- %test(Main anchor char is changeable)
  procedure set_main_anchor;

  -- %test(Aecond anchor char is changeable)
  procedure set_second_anchor;

  -- %test(Main replacement char is changeable)
  procedure set_main_separator;

  -- %test(Second replacement char is changeable)
  procedure set_second_seaparator;

  -- %endcontext

  -- %context(BULK_REPLACE tests)

  -- %test(Converts simple BULK string)
  procedure simple_bulk;

  -- %test(Converts simple BULK string, replacement anchor is number (#1#))
  procedure simple_bulk_number;

  -- %test(Converts simple BULK string, two replacement anchors)
  procedure simple_bulk_two_anchors;

  -- %test(Converts simple BULK string, provides more replacements than requested)
  procedure simple_bulk_missing_anchor;

  -- %test(Converts simple BULK string, provides less replacements than requested)
  -- %throws(msg.MISSING_ANCHORS_ERR)
  procedure simple_bulk_too_many_anchors;
  
  -- %test(Converts complex BULK string with NULL replacement)
  procedure complex_bulk_null_handling;
  
  -- %test(Converts complex BULK string with recursive anchor)
  procedure complex_bulk_recursive;
  
  -- %test(Converts complex BULK string with recursion, if original value is NULL)
  procedure complex_bulk_recursive_if_null;
  
  -- %test(Converts complex BULK string with recursion, if original value is NULL and NULL handling)
  procedure complex_bulk_recursive_and_null;
  
  -- %test(Converts complex BULK string with recursion and changed marker signs)
  procedure complex_bulk_switch_marker;
  
  -- %test(Converts complex BULK string with recursion, changed marker signs abd NULL handling)
  procedure complex_bulk_switch_marker_and_null;

  -- %endcontext
  
  -- %context(GENERATE_TEXT tests)
  
  -- %test(Converts single line SQL)
  procedure simple_text;
  
  -- %test(Converts single line SQL with two anchors)
  procedure simple_text_two_anchors;
  
  -- %test(Converts single line SQL with a missing replacement)
  -- %throws(msg.MISSING_ANCHORS_ERR)
  procedure simple_text_missing_anchor;
  
  -- %test(Converts single line SQL with a missing replacement)
  procedure simple_text_too_many_anchors;
  
  -- %test(Converts multiple line SQLinto a surrounding template)
  procedure complex_text;
  
  -- %endcontext

end ut_code_generator;
/
