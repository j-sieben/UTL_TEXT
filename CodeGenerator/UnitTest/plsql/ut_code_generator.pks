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

  -- %test(Has correct default delimiter char)
  procedure test_delimiter_char;

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

  -- %test(Delimiter char is changeable)
  procedure set_delimiter_char;
  
  -- %test(Test whether reset of any changed information works)
  procedure test_initialize;

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
  -- %throws(msg.MISSING_ANCHORS_ERR, -20002)
  procedure simple_bulk_too_many_anchors;

  -- %test(Converts simple BULK string, anchor names do not comply to naming rules)
  -- %throws(msg.INVALID_ANCHOR_NAMES_ERR, -20001)
  procedure simple_bulk_invalid_anchor;

  -- %test(Converts simple BULK string but does not offer a template)
  -- %throws(msg.NO_TEMPLATE_ERR, -20000)
  procedure simple_bulk_no_template;
  
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
  -- %throws(msg.MISSING_ANCHORS_ERR, -20002)
  procedure simple_text_missing_anchor;
  
  -- %test(Converts single line SQL without providing a template)
  -- %throws(msg.NO_TEMPLATE_ERR, -20000)
  procedure simple_different_template_name;
  
  -- %test(Converts single line SQL without providing a template)
  -- %throws(msg.NO_TEMPLATE_ERR, -20000)
  procedure simple_text_no_template;
  
  -- %test(Converts single line SQL with a missing replacement)
  procedure simple_text_too_many_anchors;
  
  -- %test(Converts single line SQL with a date column)
  procedure simple_text_date_column;
  
  -- %test(Converts single line SQL with a date column and changed date format)
  procedure simple_text_formatted_date_column;

  -- %test(Converts single line SQL, indenting is used)
  procedure simple_text_with_indent;

  -- %test(Calls GENERATE_TEXT with an invalid combination of parameters)
  -- %throws(msg.INVALID_PARAMETER_COMBI_ERR, -20003)
  procedure simple_text_invalid_params;

  -- %test(Converts single line SQL, multiple rows, indenting is used)
  procedure complex_text_with_indent;

  -- %test(Converts template/SQL statment overload)
  procedure simple_text_overload;

  -- %test(Converts single line SQL, multiple rows, indenting is used, standard delimiter)
  procedure complex_text_with_default_indent;
  
  -- %test(Converts multiple line SQL into a surrounding template)
  procedure complex_text;
  
  -- %test(Converts multiple line SQL into a surrounding template)
  procedure complex_text_with_indent_and_format;
  
  -- %test(Converts multiple line SQL into a surrounding template and logs the surrounding step)
  procedure complex_text_with_logging;
  
  -- %endcontext
  
  -- %context(GENERATE_TEXT_TABLE tests)
  
  -- %test(Converts multi line SQL into a list of results)
  procedure simple_text_table;
  
  -- %test(Converts multi line SQL into a list of results with logging)
  procedure simple_text_table_with_logging;
  
  -- %endcontext
  
  -- %context(GET_ANCHORS tests)
  
  -- %test(Reads anchors from a predefined template)
  procedure read_anchors_from_template;
  
  -- %test(Reads anchors with replacement strings from a predefined template)
  procedure read_complete_anchors_from_template;
  
  -- %endcontext

end ut_code_generator;
/
