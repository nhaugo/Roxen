// Config tablist look-a-like module. Copyright � 1999, Idonex AB.
//

constant cvs_version="$Id: configtablist.pike,v 1.3 1999/11/27 13:39:43 nilsson Exp $";

#include <module.h>
inherit "module";
inherit "roxenlib";

array register_module() {
  return ({ MODULE_PARSER, "Old tab list module", "Use the <i>Tab list</i> module instead", 0, 1});
}

void start() {
  object configuration = my_configuration();
  werror("\n ***** Config tab list outdated. Adding Tab list instead.\n");
  configuration->add_modules( ({"tablist"}), 0 );
}

string tag_ctablist(string t, mapping a, string c) {
  call_provider("oldRXMLwarning", old_rxml_warning, id, "config_tablist tag","tablist");
  return make_container("tablist",a,c);
}

mapping query_container_callers() {
  return ([ "config_tablist":tag_ctablist ]);
}
