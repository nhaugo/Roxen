// The outlined box module
//
// Fredrik Noring et al
//
// Several modifications by Francesco Chemolli.


constant cvs_version = "$Id: obox.pike,v 1.10 1999/05/25 00:40:33 neotron Exp $";
constant thread_safe=1;

#include <module.h>
inherit "module";
inherit "roxenlib";

constant unit_gif = "/internal-roxen-unit";

static private int loaded;

static private string doc()
{
  return !loaded?"":replace(Stdio.read_bytes("modules/tags/doc/obox")||"",
			    ({ "{", "}" }), ({ "&lt;", "&gt;" }));
}

static string img_placeholder (mapping args)
{
  int width=((int)args->outlinewidth)||1;

  return sprintf("<img src=\"%s\" alt=\"\" width=%d height=%d>",
		 unit_gif, width, width);
}

static string handle_title(string name, mapping junk_args,
			   string contents, mapping args)
{
  args->title=contents;
  return "";
}

static string horiz_line(mapping args)
{
  return sprintf("<tr><td colspan=5 bgcolor=\"%s\">\n"
		 "%s</td></tr>\n",
		 args->outlinecolor,
		 img_placeholder(args));
}

static string title(mapping args)
{
  if (!args->title)
    return horiz_line(args);
  string empty=img_placeholder(args);
  if (!args->left && !args->fixedleft)
    if (args->width && !args->fixedright)
      args->fixedleft = "7";
    else
      args->left = "20";
  if (!args->right && !args->fixedright)
    args->right = args->width || "20";
  switch (args->style) {
   case "groupbox":
    return sprintf("<tr><td colspan=2><font size=-3>&nbsp;</font></td>\n"
		   "<td rowspan=3%s nowrap>&nbsp;<b>"		/* bgcolor */
		   "%s%s%s"                 /* titlecolor, title, titlecolor */
		   "</b>&nbsp;</td>\n"
		   "<td colspan=2><font size=-3>&nbsp;</font></td></tr>\n"
		   "<tr%s>"				/* bgcolor */
		   "<td bgcolor=\"%s\" colspan=2>\n"	/* outlinecolor */
		   "%s</td>\n"				/* empty */
		   "<td bgcolor=\"%s\" colspan=2>\n"
		   "%s</td></tr>\n"			/* empty */

		   "<tr%s><td bgcolor=\"%s\">"      /* bgcolor, outlinecolor */
		   "%s</td>\n"				/* empty */
		   "<td%s><font size=-3>%s</font></td>" /* left, fixedleft */
		   "<td%s><font size=-3>%s</font></td>\n" /* right, fixedright */
		   "<td bgcolor=\"%s\">"		/* outlinecolor */
		   "%s</td></tr>\n"			/* empty */
		   ,
		   args->bgcolor ? " bgcolor=\""+args->bgcolor+"\"" : "",
		   args->titlecolor ? "<FONT color=\""+args->titlecolor+"\">" : "",
		   args->title,
		   args->titlecolor ? "</FONT>" : "",
		   args->bgcolor ? " bgcolor=\""+args->bgcolor+"\"" : "",
		   args->outlinecolor,
		   empty,
		   args->outlinecolor,
		   empty,
		   args->bgcolor ? " bgcolor=\""+args->bgcolor+"\"" : "",
		   args->outlinecolor,
		   empty,
		   (args->left ? " width="+args->left : ""),
		   (args->fixedleft ?
		    String.strmult ("&nbsp;", (int) args->fixedleft) : "&nbsp;"),
		   (args->right ? " width="+args->right : ""),
		   (args->fixedright ?
		    String.strmult ("&nbsp;", (int) args->fixedright) : "&nbsp;"),
		   args->outlinecolor,
		   empty);
   case "caption":
    return sprintf("<tr%s><td colspan=2><font size=-3>&nbsp;</font></td>\n"
		   "<td rowspan=3 nowrap>&nbsp;<b>"		/* bgcolor */
		   "%s%s%s"                 /* titlecolor, title, titlecolor */
		   "</b>&nbsp;</td>\n"
		   "<td colspan=2><font size=-3>&nbsp;</font></td></tr>\n"
		   "<tr bgcolor=\"%s\">"		/* outlinecolor */
		   "<td colspan=2>\n"	
		   "%s</td>\n"				/* empty */
		   "<td colspan=2>\n"
		   "%s</td></tr>\n"			/* empty */

		   "<tr bgcolor=\"%s\"><td>"      /*  outlinecolor */
		   "%s</td>\n"				/* empty */
		   "<td%s><font size=-3>%s</font></td>" /* left, fixedleft */
		   "<td%s><font size=-3>%s</font></td>\n" /* right, fixedright */
		   "<td bgcolor=\"%s\">"		/* outlinecolor */
		   "%s</td></tr>\n"			/* empty */
		   ,
		   args->outlinecolor ? " bgcolor=\""+args->outlinecolor+"\"" : "",
		   args->titlecolor ? "<FONT color=\""+args->titlecolor+"\">" : "",
		   args->title,
		   args->titlecolor ? "</FONT>" : "",
		   args->outlinecolor,
		   empty,
		   empty,
		   args->outlinecolor,
		   empty,
		   (args->left ? " width="+args->left : ""),
		   (args->fixedleft ?
		    String.strmult ("&nbsp;", (int) args->fixedleft) : "&nbsp;"),
		   (args->right ? " width="+args->right : ""),
		   (args->fixedright ?
		    String.strmult ("&nbsp;", (int) args->fixedright) : "&nbsp;"),
		   args->outlinecolor,
		   empty);
  }
}

string container_obox(string name, mapping args,
		      string contents, object request_id)
{
  string s;
  
  if (args->help) {
    args->right = 250;
    args->title = "The Outlined Box container tag";
    contents = doc();
  }

  // Set the defaults...
  args->outlinecolor = args->outlinecolor || "#000000";
  args->style = args->style || "groupbox";
  if (!args->title) {
    contents=parse_html(contents,([]),(["title":handle_title,]),args);
  }

  switch (name) {
  case "obox":
    s = "<table border=0 cellpadding=0 cellspacing=0" +
      (args->align?" align="+args->align:"") +
      (args->width?" width="+args->width:"") + ">\n" +
      title(args) +
      "<tr" +
      (args->bgcolor?" bgcolor=\""+args->bgcolor+"\"":"") +
      "><td bgcolor=\"" + args->outlinecolor + "\">" +
      img_placeholder(args) + "</td>\n"
      "<td colspan=3>\n"
      "<table border=0 cellspacing=5 "+
      (args->spacing?"width="+(string)args->spacing+" ":"")+">"
      "<tr><td>\n";

      if (args->textcolor) {
	s += "<font color=\""+args->textcolor+"\">" + contents + "</font>";
      } else {
	s += contents;
      }
      
      s += "</td></tr></table>\n"
	"</td><td bgcolor=\"" + args->outlinecolor + "\">" +
	img_placeholder(args) + "</td></tr>\n" +
	horiz_line(args) + "</table>\n";

    break;
  }
  
  return s;
}

array register_module()
{
  return ({
    MODULE_PARSER,
      "Outlined box",
      "This is a container tag making outlined boxes.<p>"
      "<tt>&lt;obox help&gt;&lt;/obox&gt;</tt> gives help.\n\n<p>"+doc(),
      0, 1 });
}

void start(int num, object configuration)
{
  loaded = 1;
}

mapping query_container_callers()
{
  return ([ "obox":container_obox, ]);
}
