// This is a roxen module. Copyright � 2000, Roxen IS.
//

constant cvs_version="$Id: wiretap.pike,v 1.14 2000/04/06 07:34:42 wing Exp $";

#include <module.h>
inherit "module";
inherit "roxenlib";


//---------------------- Module Registration --------------------------------

constant module_type   = MODULE_PARSER;
constant module_name   = "HTML color wiretap";
constant module_doc    = 
#"Parses HTML tags and tries to determine the text and background colors 
all over the page. This information can be used to let graphical modules
generate images that automatically blend into the page.";
constant thread_safe   = 1;

void create()
{
  defvar("colorparsing", ({"body", "td", "layer", "ilayer", "table"}),
	 "Tags to parse for color",
	 TYPE_STRING_LIST|VAR_INITIAL,
	 "Which tags should be parsed for document colors? "
	 "This will affect documents without gtext as well as documents "
	 "with it, the parsing time is relative to the number of parsed "
	 "tags in a document. You have to reload this module or restart "
	 "roxen for changes of this variable to take effect.");

  defvar("colormode", 1, "Normalize colors in parsed tags",
         TYPE_FLAG|VAR_INITIAL,
	 "If set, replace 'roxen' colors (@c,m,y,k etc) with "
	 "'netscape' colors (#rrggbb). Setting this to off will lessen the "
	 "performance impact of the 'Tags to parse for color' option quite"
	 " dramatically. You can try this out with the &lt;gauge&gt; tag." );
}


// -------------------- The actual wiretap code  --------------------------

inline string ns_color(array (int) col)
{
  if(!arrayp(col)||sizeof(col)!=3)
    return "#000000";
  return sprintf("#%02x%02x%02x", col[0],col[1],col[2]);
}

array(int|string) tag_body(string t, mapping args, RequestID id)
{
  int changed=0;
  int cols=(args->bgcolor||args->text||args->link||args->alink||args->vlink);

#define FIX(Y,Z,X) do{ \
  if(!args->Y || args->Y==""){ \
    id->misc->defines[X]=Z; \
    if(cols){ \
      args->Y=Z; \
      changed=1; \
    } \
  } \
  else{ \
    id->misc->defines[X]=args->Y; \
    if(QUERY(colormode)&&args->Y[0]!='#'){ \
      args->Y=ns_color(parse_color(args->Y)); \
      changed=1; \
    } \
  } \
}while(0)

  //FIXME: These values are not up to date

  FIX(text,   "#000000","fgcolor");
  FIX(link,   "#0000ee","link");
  FIX(alink,  "#ff0000","alink");
  FIX(vlink,  "#551a8b","vlink");

  if(has_value(id->client_var->fullname||"","windows"))
  {
    FIX(bgcolor,"#c0c0c0","bgcolor");
  } else {
    FIX(bgcolor,"#ffffff","bgcolor");
  }

  id->misc->wiretap_stack = ({});

  if(changed && QUERY(colormode))
    return ({1, "body", args });
  return ({1});
}

array(int|string) push_color(string tagname, mapping args, RequestID id)
{
  int changed;
  if(!id->misc->wiretap_stack)
    tag_body("body", ([]), id);

  id->misc->wiretap_stack += ({ ({ tagname, id->misc->defines->fgcolor, id->misc->defines->bgcolor }) });

#undef FIX
#define FIX(X,Y) if(args->X && args->X!=""){ \
  id->misc->defines->Y=args->X; \
  if(QUERY(colormode) && args->X[0]!='#'){ \
    args->X=ns_color(parse_color(args->X)); \
    changed = 1; \
  } \
}

  FIX(bgcolor,bgcolor);
  FIX(color,fgcolor);
  FIX(text,fgcolor);
#undef FIX

  if(changed && QUERY(colormode))
    return ({1, tagname, args });
  return ({1});
}

array(int) pop_color(string tagname, mapping args, RequestID id)
{
  array c = id->misc->wiretap_stack;
  if(c && sizeof(c)) {
    int i;
    tagname = tagname[1..];

    for(i=0; i<sizeof(c); i++)
      if(c[-i-1][0]==tagname)
      {
	id->misc->defines->fgcolor = c[-i-1][1];
	id->misc->defines->bgcolor = c[-i-1][2];
	break;
      }

    id->misc->wiretap_stack = c[..sizeof(c)-i-2];
  }
  return ({1});
}


// --------------- Tag and container registration ----------------------

mapping query_tag_callers()
{
  mapping tags=([]);
  foreach(query("colorparsing"), string t)
  {
    switch(t)
    {
    case "body":
      tags[t] = tag_body;
      break;
    default:
      tags[t] = push_color;
      tags["/"+t]=pop_color;
    }
  }
  return tags;
}


// --------------------- Wiretap countermeasure --------------------

class TagColorScope {
  inherit RXML.Tag;
  constant name = "colorscope";

  class Frame {
    inherit RXML.Frame;
    string link, alink, vlink;

#define LOCAL_PUSH(X) if(args->X) { X=id->misc->defines->X; id->misc->defines->X=args->X; }
    array do_enter(RequestID id) {
      push_color("colorscope",args,id);
      LOCAL_PUSH(link);
      LOCAL_PUSH(alink);
      LOCAL_PUSH(vlink);
      return 0;
    }

#define LOCAL_POP(X) if(X) id->misc->defines->X=X
    array do_return(RequestID id) {
      pop_color("/colorscope",0,id);
      LOCAL_POP(link);
      LOCAL_POP(alink);
      LOCAL_POP(vlink);
      result=content;
      return 0;
    }
  }
}

TAGDOCUMENTATION;
#ifdef manual
constant tagdoc=([
  "colorscope":#"<desc cont>Makes it possible to change the autodetected
colors within the tag. Useful when out-of-order parsing occurs, e.g.
<ex type=box>
<define tag=\"hello\">
  <colorscope bgcolor=\"red\">
    <gtext>Hello</gtext>
  </colorscope>
</define>

<table><tr>
  <td bgcolor=\"red\">
    <hello/>
  </td>
</tr></table>
</ex>
</desc>

<attr name=text value=color>
 Set the text color within the scope.
</attr>

<attr name=bgcolor value=color>
 Set the background color within the scope.
</attr>

<attr name=link value=color>
 Set the link color within the scope.
</attr>

<attr name=alink value=color>
 Set the active link color within the scope.
</attr>

<attr name=vlink value=color>
 Set the visited link color within the scope.
</attr>"
]);
#endif
