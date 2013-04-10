themeFunc = (require, exports, module) ->

  exports.isDark = true
  exports.cssClass = "ace-netlogo-classic"

  exports.cssText = ".ace-netlogo-classic .ace_gutter {\
    background: #F0F0F0;\
    color: #333333;\
  }\
  .ace-netlogo-classic .ace_print-margin {\
    width: 1px;\
    background: #E8E8E8;\
  }\
  .ace-netlogo-classic .ace_fold {\
    background-color: #6B72E6;\
  }\
  .ace-netlogo-classic .ace_scroller {\
    background-color: #FFFFFF;\
  }\
  .ace-netlogo-classic .ace_cursor {\
    border-left: 2px solid black;\
  }\
  .ace-netlogo-classic .ace_overwrite-cursors .ace_cursor {\
    border-left: 0px;\
    border-bottom: 1px solid black;\
  }\
  .ace-netlogo-classic .ace_marker-layer .ace_selection {\
    background: #B5D5FF;\
  }\
  .ace-netlogo-classic.ace_multiselect .ace_selection.ace_start {\
    box-shadow: 0 0 3px 0px white;\
    border-radius: 2px;\
  }\
  .ace-netlogo-classic .ace_marker-layer .ace_step {\
    background: #FCFF00;\
  }\
  .ace-netlogo-classic .ace_gutter-active-line {\
    background-color: #DCDCDC;\
  }\
  .ace-netlogo-classic .ace_marker-layer .ace_selected-word {\
    background: #FAFAFF;\
    border: 1px solid #C8C8FA;\
  }\
  .ace-netlogo-classic .ace_invisible {\
    color: #BFBFBF;\
  }\
  .ace-netlogo-classic .ace_entity.ace_name.ace_tag {\
    color: #809FBF;\
  }\
  .ace-netlogo-classic .ace_storage {\
    color: blue;\
  }\
  .ace-netlogo-classic .ace_meta.ace_tag {\
    color: #00168E;\
  }\
  .ace-netlogo-classic .ace_storage.ace_type,\
  .ace-netlogo-classic .ace_support.ace_constant,\
  .ace-netlogo-classic .ace_support.ace_function,\
  .ace-netlogo-classic .ace_support.ace_class,\
  .ace-netlogo-classic .ace_support.ace_type {\
    font-style: italic;\
    color: #66D9EF;\
  }\
  .ace-netlogo-classic .ace_entity.ace_name.ace_function,\
  .ace-netlogo-classic .ace_entity.ace_other,\
  .ace-netlogo-classic .ace_literal,\
  .ace-netlogo-classic .ace_comma,\
  .ace-netlogo-classic .ace_ident,\
  .ace-netlogo-classic .ace_brace,\
  .ace-netlogo-classic .ace_bracket,\
  .ace-netlogo-classic .ace_paren,\
  .ace-netlogo-classic .ace_eof {\
    color: #000000;\
  }\
  .ace-netlogo-classic .ace_variable,\
  .ace-netlogo-classic .ace_reporter {\
    color: #660096;\
  }
  .ace-netlogo-classic .ace_string,\
  .ace-netlogo-classic .ace_constant.ace_library,\
  .ace-netlogo-classic .ace_constant.ace_character,\
  .ace-netlogo-classic .ace_constant.ace_language,\
  .ace-netlogo-classic .ace_constant.ace_numeric,\
  .ace-netlogo-classic .ace_constant.ace_other,\
  .ace-netlogo-classic .ace_constant {\
    color: #963700;\
  }\
  .ace-netlogo-classic .ace_command {\
    color: #0000AA;\
  }\
  .ace-netlogo-classic .ace_keyword {\
    color: #007F69;\
  }\
  .ace-netlogo-classic .ace_comment {\
    color: #5A5A5A;\
  }
  .ace-netlogo-classic .ace_invalid,\
  .ace-netlogo-classic .ace_bad {\
    color: #FF0000;\
  }\
  .ace-netlogo-classic .ace_markup.ace_underline {\
    text-decoration: underline;\
  }\
  .ace-netlogo-classic .ace_indent-guide {\
    background: url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAACCAYAAACZgbYnAAAAE0lEQVQImWP4////f4bLly//BwAmVgd1/w11/gAAAABJRU5ErkJggg==') right repeat-y;\
  }";

  dom = require("../lib/dom")
  dom.importCssString(exports.cssText, exports.cssClass)

define('ace/theme/netlogo-classic', ['require', 'exports', 'module' , 'ace/lib/dom'], themeFunc)

