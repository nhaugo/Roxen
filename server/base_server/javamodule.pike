// This file is part of Roxen WebServer.
// Copyright � 1999 - 2004, Roxen IS.
// $Id: javamodule.pike,v 1.8 2009/01/11 14:41:35 mast Exp $

#include <module.h>
inherit "module";

#if constant(JavaModule.ModuleWrapper)
inherit JavaModule.ModuleWrapper;


protected string my_filename;
protected Configuration my_conf;


string file_name_and_stuff()
{
  return ("<b>Loaded from:</b> "+my_filename+"<br />");
}

void create(Configuration conf, string filename)
{
  load(my_filename = filename);
  if(!modobj)
    destruct(this_object());
  else {
    foreach(getdefvars(), array dv)
      defvar(@dv);
    init(my_conf = conf);
  }
}
#endif
