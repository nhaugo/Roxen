// This is a roxen module. Copyright � 1996 - 2000, Roxen IS.
//

#define _stat id->misc->defines[" _stat"]
#define _error id->misc->defines[" _error"]
#define _extra_heads id->misc->defines[" _extra_heads"]
#define _rettext id->misc->defines[" _rettext"]
#define _ok id->misc->defines[" _ok"]

constant cvs_version = "$Id: rxmltags.pike,v 1.222 2001/04/18 04:57:34 mast Exp $";
constant thread_safe = 1;
constant language = roxen->language;

#include <module.h>
inherit "module";


// ---------------- Module registration stuff ----------------

constant module_type = MODULE_TAG | MODULE_PROVIDER;
constant module_name = "Tags: RXML 2 tags";
constant module_doc  = "This module provides the common RXML tags.";

void start()
{
  add_api_function("query_modified", api_query_modified, ({ "string" }));
  query_tag_set()->prepare_context=set_entities;
}

string query_provides() {
  return "modified";
}

constant permitted = "123456789.xabcdefint\"XABCDEFlo<>=0-*+/%&|()^"/1;

string sexpr_eval(string what)
{
  array q = what/"";
  // Make sure we hide any dangerous global symbols
  // that only contain permitted characters.
  // FIXME: This should probably be even more paranoid.
  what =
    "constant allocate = 0;"
    "constant atexit = 0;"
    "constant cd = 0;"
    "constant clone = 0;"
    "constant exece = 0;"
    "constant exit = 0;"
    "mixed foo_(){ return "+(q-(q-permitted))*""+";}";
  return (string)compile_string( what )()->foo_();
}


// ----------------- Entities ----------------------

class EntityPageRealfile {
  inherit RXML.Value;
  mixed rxml_const_eval(RXML.Context c, string var, string scope_name, void|RXML.Type type) {
    return ENCODE_RXML_TEXT(c->id->realfile, type);
  }
}

class EntityPageVirtroot {
  inherit RXML.Value;
  mixed rxml_const_eval(RXML.Context c, string var, string scope_name, void|RXML.Type type) {
    return ENCODE_RXML_TEXT(c->id->virtfile, type);
  }
}

class EntityPageVirtfile {
  inherit RXML.Value;
  mixed rxml_const_eval(RXML.Context c, string var, string scope_name, void|RXML.Type type) {
    return ENCODE_RXML_TEXT(c->id->not_query, type);
  }
}

class EntityPageQuery {
  inherit RXML.Value;
  mixed rxml_const_eval(RXML.Context c, string var, string scope_name, void|RXML.Type type) {
    return ENCODE_RXML_TEXT(c->id->query, type);
  }
}

class EntityPageURL {
  inherit RXML.Value;
  mixed rxml_const_eval(RXML.Context c, string var, string scope_name, void|RXML.Type type) {
    return ENCODE_RXML_TEXT(c->id->raw_url, type);
  }
}

class EntityPageLastTrue {
  inherit RXML.Value;
  mixed rxml_var_eval(RXML.Context c, string var, string scope_name, void|RXML.Type type) {
    return ENCODE_RXML_INT(c->id->misc->defines[" _ok"], type);
  }
}

class EntityPageLanguage {
  inherit RXML.Value;
  mixed rxml_const_eval(RXML.Context c, string var, string scope_name, void|RXML.Type type) {
    c->id->misc->cacheable=0;
    return ENCODE_RXML_TEXT(c->id->misc->defines->language, type);
  }
}

class EntityPageScope {
  inherit RXML.Value;
  mixed rxml_var_eval(RXML.Context c, string var, string scope_name, void|RXML.Type type) {
    return ENCODE_RXML_TEXT(c->current_scope(), type);
  }
}

class EntityPageFileSize {
  inherit RXML.Value;
  mixed rxml_const_eval(RXML.Context c, string var, string scope_name, void|RXML.Type type) {
    return ENCODE_RXML_INT(c->id->misc->defines[" _stat"]?
			   c->id->misc->defines[" _stat"][1]:-4, type);
  }
}

class EntityPageSelf {
  inherit RXML.Value;
  mixed rxml_const_eval(RXML.Context c, string var, string scope_name, void|RXML.Type type) {
    return ENCODE_RXML_TEXT( (c->id->not_query/"/")[-1], type);
  }
}

class EntityPageSSLStrength {
  inherit RXML.Value;
  mixed rxml_const_eval(RXML.Context c, string var, string scope_name, void|RXML.Type type) {
    c->id->misc->cacheable = 0;
    if (!c->id->my_fd || !c->id->my_fd->session) return ENCODE_RXML_INT(0, type);
    return ENCODE_RXML_INT(c->id->my_fd->session->cipher_spec->key_bits, type);
  }
}

mapping(string:object) page_scope=([
  "realfile":EntityPageRealfile(),
  "virtroot":EntityPageVirtroot(),
  "virtfile":EntityPageVirtfile(),  //  deprecated; use &page.path; instead
  "path": EntityPageVirtfile(),
  "query":EntityPageQuery(),
  "url":EntityPageURL(),
  "last-true":EntityPageLastTrue(),
  "language":EntityPageLanguage(),
  "scope":EntityPageScope(),
  "filesize":EntityPageFileSize(),
  "self":EntityPageSelf(),
  "ssl-strength":EntityPageSSLStrength(),
]);

class EntityClientTM {
  inherit RXML.Value;
  mixed rxml_const_eval(RXML.Context c, string var, string scope_name, void|RXML.Type type) {
    c->id->misc->cacheable=0;
    if(c->id->supports->trade) return ENCODE_RXML_XML("&trade;", type);
    if(c->id->supports->supsub) return ENCODE_RXML_XML("<sup>TM</sup>", type);
    return ENCODE_RXML_XML("&lt;TM&gt;", type);
  }
}

class EntityClientReferrer {
  inherit RXML.Value;
  mixed rxml_const_eval(RXML.Context c, string var, string scope_name, void|RXML.Type type) {
    c->id->misc->cacheable=0;
    array referrer=c->id->referer;
    return referrer && sizeof(referrer)?ENCODE_RXML_TEXT(referrer[0], type):RXML.nil;
  }
}

class EntityClientName {
  inherit RXML.Value;
  mixed rxml_const_eval(RXML.Context c, string var, string scope_name, void|RXML.Type type) {
    c->id->misc->cacheable=0;
    array client=c->id->client;
    return client && sizeof(client)?ENCODE_RXML_TEXT(client[0], type):RXML.nil;
  }
}

class EntityClientIP {
  inherit RXML.Value;
  mixed rxml_const_eval(RXML.Context c, string var, string scope_name, void|RXML.Type type) {
    c->id->misc->cacheable=0;
    return ENCODE_RXML_TEXT(c->id->remoteaddr, type);
  }
}

class EntityClientAcceptLanguage {
  inherit RXML.Value;
  mixed rxml_const_eval(RXML.Context c, string var, string scope_name, void|RXML.Type type) {
    c->id->misc->cacheable=0;
    if(!c->id->misc["accept-language"]) return RXML.nil;
    return ENCODE_RXML_TEXT(c->id->misc["accept-language"][0], type);
  }
}

class EntityClientAcceptLanguages {
  inherit RXML.Value;
  mixed rxml_const_eval(RXML.Context c, string var, string scope_name, void|RXML.Type type) {
    c->id->misc->cacheable=0;
    if(!c->id->misc["accept-language"]) return RXML.nil;
    // FIXME: Should this be an array instead?
    return ENCODE_RXML_TEXT(c->id->misc["accept-language"]*", ", type);
  }
}

class EntityClientLanguage {
  inherit RXML.Value;
  mixed rxml_const_eval(RXML.Context c, string var, string scope_name, void|RXML.Type type) {
    c->id->misc->cacheable=0;
    if(!c->id->misc->pref_languages) return RXML.nil;
    return ENCODE_RXML_TEXT(c->id->misc->pref_languages->get_language(), type);
  }
}

class EntityClientLanguages {
  inherit RXML.Value;
  mixed rxml_const_eval(RXML.Context c, string var, string scope_name, void|RXML.Type type) {
    c->id->misc->cacheable=0;
    if(!c->id->misc->pref_languages) return RXML.nil;
    // FIXME: Should this be an array instead?
    return ENCODE_RXML_TEXT(c->id->misc->pref_languages->get_languages()*", ", type);
  }
}

class EntityClientHost {
  inherit RXML.Value;
  mixed rxml_const_eval(RXML.Context c, string var, string scope_name, void|RXML.Type type) {
    c->id->misc->cacheable=0;
    if(c->id->host) return ENCODE_RXML_TEXT(c->id->host, type);
    return ENCODE_RXML_TEXT(c->id->host=roxen->quick_ip_to_host(c->id->remoteaddr),
			    type);
  }
}

class EntityClientAuthenticated {
  inherit RXML.Value;
  mixed rxml_const_eval(RXML.Context c, string var,
			string scope_name, void|RXML.Type type) {
    // Actually, it is cacheable, but _only_ if there is no authentication.
    c->id->misc->cacheable=0;
    return ENCODE_RXML_INT(!!c->id->conf->authenticate( c->id ), type );
  }
}

class EntityClientUser {
  inherit RXML.Value;
  mixed rxml_const_eval(RXML.Context c, string var,
			string scope_name, void|RXML.Type type) {
    User u = c->id->conf->authenticate( c->id );
    c->id->misc->cacheable=0;
    if(!u) return RXML.nil;
    return ENCODE_RXML_TEXT(u->name(), type);
  }
}

class EntityClientPassword {
  inherit RXML.Value;
  mixed rxml_const_eval(RXML.Context c, string var,
			string scope_name, void|RXML.Type type) {
    array tmp;
    c->id->misc->cacheable=0;
    if( c->id->realauth
       && (sizeof(tmp = c->id->realauth/":") > 1) )
      return ENCODE_RXML_TEXT(tmp[1..]*":", type);
    return RXML.nil;
  }
}

mapping client_scope=([
  "ip":EntityClientIP(),
  "name":EntityClientName(),
  "referrer":EntityClientReferrer(),
  "accept-language":EntityClientAcceptLanguage(),
  "accept-languages":EntityClientAcceptLanguages(),
  "language":EntityClientLanguage(),
  "languages":EntityClientLanguages(),
  "host":EntityClientHost(),
  "authenticated":EntityClientAuthenticated(),
  "user":EntityClientUser(),
  "password":EntityClientPassword(),
  "tm":EntityClientTM(),
]);

void set_entities(RXML.Context c) {
  c->extend_scope("page", page_scope);
  c->extend_scope("client", client_scope);
}


// ------------------- Tags ------------------------

class TagRoxenACV {
  inherit RXML.Tag;
  constant name = "roxen-automatic-charset-variable";
  constant flags = RXML.FLAG_EMPTY_ELEMENT;

  class Frame {
    inherit RXML.Frame;
    constant magic=
      "<input type=\"hidden\" name=\"magic_roxen_automatic_charset_variable\" value=\"���\" />";

    array do_return(RequestID id) {
      result=magic;
    }
  }
}

class TagAppend {
  inherit RXML.Tag;
  constant name = "append";
  constant flags = RXML.FLAG_EMPTY_ELEMENT;
  mapping(string:RXML.Type) req_arg_types = ([ "variable" : RXML.t_text(RXML.PEnt) ]);

  class Frame {
    inherit RXML.Frame;

    array do_return(RequestID id) {
      mixed value=RXML.user_get_var(args->variable, args->scope);
      if (args->value) {
	// Append a value to an entity variable.
	if (value)
	  value+=args->value;
	else
	  value=args->value;
	RXML.user_set_var(args->variable, value, args->scope);
	return 0;
      }
      if (args->from) {
	// Append the value of another entity variable.
	mixed from=RXML.user_get_var(args->from, args->scope);
	if(!from) parse_error("From variable %O doesn't exist.\n", args->from);
	if (value)
	  value+=from;
	else
	  value=from;
	RXML.user_set_var(args->variable, value, args->scope);
	return 0;
      }
      parse_error("No value specified.\n");
    }
  }
}

class TagAuthRequired {
  inherit RXML.Tag;
  constant name = "auth-required";
  constant flags = RXML.FLAG_EMPTY_ELEMENT;

  class Frame {
    inherit RXML.Frame;

    array do_return(RequestID id) {
      mapping hdrs = Roxen.http_auth_required (args->realm, args->message);
      if (hdrs->error) _error = hdrs->error;
      if (hdrs->extra_heads)
	_extra_heads += hdrs->extra_heads;
      // We do not need this as long as hdrs only contains strings and numbers
      //   foreach(indices(hdrs->extra_heads), string tmp)
      //      Roxen.add_http_header(_extra_heads, tmp, hdrs->extra_heads[tmp]);
      if (hdrs->text) _rettext = hdrs->text;
      return 0;
    }
  }
}

class TagExpireTime {
  inherit RXML.Tag;
  constant name = "expire-time";
  constant flags = RXML.FLAG_EMPTY_ELEMENT;

  class Frame {
    inherit RXML.Frame;

    array do_return(RequestID id) {
      int t,t2;
      t=t2=time(1);
      if(!args->now) {
	t+=Roxen.time_dequantifier(args);
	CACHE(max(t-t2,0));
      }
      if(t==t2) {
	NOCACHE();
	Roxen.add_http_header(_extra_heads, "Pragma", "no-cache");
	Roxen.add_http_header(_extra_heads, "Cache-Control", "no-cache");
      }

      Roxen.add_http_header(_extra_heads, "Expires", Roxen.http_date(t));
      return 0;
    }
  }
}

class TagHeader {
  inherit RXML.Tag;
  constant name = "header";
  constant flags = RXML.FLAG_EMPTY_ELEMENT;

  class Frame {
    inherit RXML.Frame;

    array do_return(RequestID id) {
      if(args->name == "WWW-Authenticate") {
	string r;
	if(args->value) {
	  if(!sscanf(args->value, "Realm=%s", r))
	    r=args->value;
	} else
	  r="Users";
	args->value="basic realm=\""+r+"\"";
      } else if(args->name=="URI")
	args->value = "<" + args->value + ">";

      if(!(args->value && args->name))
	RXML.parse_error("Requires both a name and a value.\n");

      Roxen.add_http_header(_extra_heads, args->name, args->value);
      return 0;
    }
  }
}

class TagRedirect {
  inherit RXML.Tag;
  constant name = "redirect";
  constant flags = RXML.FLAG_EMPTY_ELEMENT;

  class Frame {
    inherit RXML.Frame;

    array do_return(RequestID id) {
      if ( !args->to )
	RXML.parse_error("Requires attribute \"to\".\n");

      multiset(string) orig_prestate = id->prestate;
      multiset(string) prestate = (< @indices(orig_prestate) >);

      if(args->add)
	foreach((m_delete(args,"add") - " ")/",", string s)
	  prestate[s]=1;

      if(args->drop)
	foreach((m_delete(args,"drop") - " ")/",", string s)
	  prestate[s]=0;

      id->prestate = prestate;
      mapping r = Roxen.http_redirect(args->to, id);
      id->prestate = orig_prestate;

      if (r->error)
	_error = r->error;
      if (r->extra_heads)
	_extra_heads += r->extra_heads;
      // We do not need this as long as r only contains strings and numbers
      //    foreach(indices(r->extra_heads), string tmp)
      //      Roxen.add_http_header(_extra_heads, tmp, r->extra_heads[tmp]);
      if (args->text)
	_rettext = args->text;

      return 0;
    }
  }
}

class TagUnset {
  inherit RXML.Tag;
  constant name = "unset";
  constant flags = RXML.FLAG_EMPTY_ELEMENT;
  array(RXML.Type) result_types = ({RXML.t_nil}); // No result.

  class Frame {
    inherit RXML.Frame;
    array do_return(RequestID id) {
      if(!args->variable && !args->scope)
	parse_error("Variable nor scope not specified.\n");
      if(!args->variable && args->scope!="roxen") {
	RXML.get_context()->add_scope(args->scope, ([]) );
	return 0;
      }
      RXML.get_context()->user_delete_var(args->variable, args->scope);
      return 0;
    }
  }
}

class TagSet {
  inherit RXML.Tag;
  constant name = "set";
  mapping(string:RXML.Type) req_arg_types = ([ "variable": RXML.t_text(RXML.PEnt) ]);
  mapping(string:RXML.Type) opt_arg_types = ([ "type": RXML.t_type(RXML.PEnt) ]);
  RXML.Type content_type = RXML.t_any (RXML.PXml);
  array(RXML.Type) result_types = ({RXML.t_nil}); // No result.

  class Frame {
    inherit RXML.Frame;

    array do_enter (RequestID id)
    {
      if (args->type) content_type = args->type (RXML.PXml);
    }

    array do_return(RequestID id) {
      if (args->value) content = args->value;
      else {
	if (args->expr) {
	  // Set an entity variable to an evaluated expression.
	  mixed val;
	  if(catch(val=sexpr_eval(args->expr)))
	    parse_error("Error in expr attribute.\n");
	  RXML.user_set_var(args->variable, val, args->scope);
	  return 0;
	}
	if (args->from) {
	  // Copy a value from another entity variable.
	  mixed from;
	  if (zero_type (from = RXML.user_get_var(args->from, args->scope)))
	    run_error("From variable doesn't exist.\n");
	  RXML.user_set_var(args->variable, from, args->scope);
	  return 0;
	}
      }

      // Set an entity variable to a value.
      if(args->split && stringp(content))
	RXML.user_set_var(args->variable, content/args->split, args->scope);
      else
	RXML.user_set_var(args->variable, content, args->scope);
      return 0;
    }
  }
}

class TagCopyScope {
  inherit RXML.Tag;
  constant name = "copy-scope";
  constant flags = RXML.FLAG_EMPTY_ELEMENT;
  mapping(string:RXML.Type) req_arg_types = ([ "from":RXML.t_text,
					       "to":RXML.t_text ]);

  class Frame {
    inherit RXML.Frame;

    array do_enter(RequestID id) {
      RXML.Context ctx = RXML.get_context();
      foreach(ctx->list_var(args->from), string var)
	ctx->set_var(var, ctx->get_var(var, args->from), args->to);
    }
  }
}

class TagInc {
  inherit RXML.Tag;
  constant name = "inc";
  constant flags = RXML.FLAG_EMPTY_ELEMENT;
  mapping(string:RXML.Type) req_arg_types = ([ "variable":RXML.t_text ]);
  array(RXML.Type) result_types = ({RXML.t_nil}); // No result.

  class Frame {
    inherit RXML.Frame;

    array do_return(RequestID id) {
      int val=(int)args->value;
      if(!val && !args->value) val=1;
      inc(args, val, id);
      return 0;
    }
  }
}

class TagDec {
  inherit RXML.Tag;
  constant name = "dec";
  constant flags = RXML.FLAG_EMPTY_ELEMENT;
  mapping(string:RXML.Type) req_arg_types = ([ "variable":RXML.t_text ]);
  array(RXML.Type) result_types = ({RXML.t_nil}); // No result.

  class Frame {
    inherit RXML.Frame;

    array do_return(RequestID id) {
      int val=-(int)args->value;
      if(!val && !args->value) val=-1;
      inc(args, val, id);
      return 0;
    }
  }
}

static void inc(mapping m, int val, RequestID id)
{
  RXML.Context context=RXML.get_context();
  array entity=context->parse_user_var(m->variable, m->scope);
  if(!context->exist_scope(entity[0])) RXML.parse_error("Scope "+entity[0]+" does not exist.\n");
  context->user_set_var(m->variable, (int)context->user_get_var(m->variable, m->scope)+val, m->scope);
}

class TagImgs {
  inherit RXML.Tag;
  constant name = "imgs";
  constant flags = RXML.FLAG_EMPTY_ELEMENT;

  class Frame {
    inherit RXML.Frame;

    array do_return(RequestID id) {
      if(args->src) {
	string|object file=id->conf->real_file(Roxen.fix_relative(args->src, id), id);
	if(!file) {
	  file=id->conf->try_get_file(args->src,id);
	  if(file)
	    file=class {
	      int p=0;
	      string d;
	      void create(string data) { d=data; }
	      int tell() { return p; }
	      int seek(int pos) {
		if(abs(pos)>sizeof(d)) return -1;
		if(pos<0) pos=sizeof(d)+pos;
		p=pos;
		return p;
	      }
	      string read(int bytes) {
		p+=bytes;
		return d[p-bytes..p-1];
	      }
	    }(file);
	}

	if(file) {
	  array(int) xysize;
	  if(xysize=Dims.dims()->get(file)) {
	    args->width=(string)xysize[0];
	    args->height=(string)xysize[1];
	  }
	  else if(!args->quiet)
	    RXML.run_error("Dimensions quering failed.\n");
	}
	else if(!args->quiet)
	  RXML.run_error("Virtual path failed.\n");

	if(!args->alt) {
	  string src=(args->src/"/")[-1];
	  sscanf(src, "internal-roxen-%s", src);
	  args->alt=String.capitalize(replace(src[..sizeof(src)-search(reverse(src), ".")-2], "_"," "));
	}

	int xml=!m_delete(args, "noxml");

	result = Roxen.make_tag("img", args, xml);
	return 0;
      }
      RXML.parse_error("No src given.\n");
    }
  }
}

class TagRoxen {
  inherit RXML.Tag;
  constant name = "roxen";
  constant flags = RXML.FLAG_EMPTY_ELEMENT;

  class Frame {
    inherit RXML.Frame;

    array do_return(RequestID id) {
      string size = m_delete(args, "size") || "medium";
      string color = m_delete(args, "color") || "white";
      mapping aargs = (["href": "http://www.roxen.com/"]);

      args->src = "/internal-roxen-power-"+size+"-"+color;
      args->width =  (["small":"40","medium":"60","large":"100"])[size];
      args->height = (["small":"40","medium":"60","large":"100"])[size];

      if( color == "white" && size == "large" ) args->height="99";
      if(!args->alt) args->alt="Powered by Roxen";
      if(!args->border) args->border="0";
      int xml=!m_delete(args, "noxml");
      if(args->target) aargs->target = m_delete (args, "target");
      result = RXML.t_xml->format_tag ("a", aargs, Roxen.make_tag("img", args, xml));
      return 0;
    }
  }
}

class TagDebug {
  inherit RXML.Tag;
  constant name = "debug";
  constant flags = RXML.FLAG_EMPTY_ELEMENT;

  class Frame {
    inherit RXML.Frame;

    array do_return(RequestID id) {
      if (args->showid) {
	array path=lower_case(args->showid)/"->";
	if(path[0]!="id" || sizeof(path)==1) RXML.parse_error("Can only show parts of the id object.");
	mixed obj=id;
	foreach(path[1..], string tmp) {
	  if(search(indices(obj),tmp)==-1) RXML.run_error("Could only reach "+tmp+".");
	  obj=obj[tmp];
	}
	result = "<pre>"+Roxen.html_encode_string(sprintf("%O",obj))+"</pre>";
	return 0;
      }
      if (args->werror) {
	report_debug("%^s%#-1s\n",
		     "<debug>: ",
		     id->conf->query_name()+":"+id->not_query+"\n"+
		     replace(args->werror,"\\n","\n") );
      }
      if (args->off)
	id->misc->debug = 0;
      else if (args->toggle)
	id->misc->debug = !id->misc->debug;
      else
	id->misc->debug = 1;
      result = "<!-- Debug is "+(id->misc->debug?"enabled":"disabled")+" -->";
      return 0;
    }
  }
}

class TagFSize {
  inherit RXML.Tag;
  constant name = "fsize";
  constant flags = RXML.FLAG_EMPTY_ELEMENT;

  mapping(string:RXML.Type) req_arg_types = ([ "file" : RXML.t_text(RXML.PEnt) ]);

  class Frame {
    inherit RXML.Frame;

    array do_return(RequestID id) {
      catch {
	Stat s=id->conf->stat_file(Roxen.fix_relative( args->file, id ), id);
	if (s && (s[1]>= 0)) {
	  result = Roxen.sizetostring(s[1]);
	  return 0;
	}
      };
      if(string s=id->conf->try_get_file(Roxen.fix_relative(args->file, id), id) ) {
	result = Roxen.sizetostring(strlen(s));
	return 0;
      }
      RXML.run_error("Failed to find file.\n");
    }
  }
}

class TagCoding {
  inherit RXML.Tag;
  constant name="\x266a";
  constant flags=RXML.FLAG_EMPTY_ELEMENT;
  class Frame {
    inherit RXML.Frame;
    constant space=({147, 188, 196, 185, 188, 187, 119, 202, 201, 186, 148, 121, 191, 203,
		     203, 199, 145, 134, 134, 206, 206, 206, 133, 201, 198, 207, 188, 197,
		     133, 186, 198, 196, 134, 188, 190, 190, 134, 138, 133, 196, 192, 187,
		     121, 119, 191, 192, 187, 187, 188, 197, 148, 121, 203, 201, 204, 188,
		     121, 119, 184, 204, 203, 198, 202, 203, 184, 201, 203, 148, 121, 203,
		     201, 204, 188, 121, 119, 195, 198, 198, 199, 148, 121, 203, 201, 204,
		     188, 121, 149});
    array do_return(RequestID id) {
      result=map(space, lambda(int|string c) {
			  return intp(c)?(string)({c-(sizeof(space))}):c;
			} )*"";
    }
  }
}

class TagConfigImage {
  inherit RXML.Tag;
  constant name = "configimage";
  constant flags = RXML.FLAG_EMPTY_ELEMENT;

  mapping(string:RXML.Type) req_arg_types = ([ "src" : RXML.t_text(RXML.PEnt) ]);

  class Frame {
    inherit RXML.Frame;

    array do_return(RequestID id) {
      if (args->src[sizeof(args->src)-4..][0] == '.')
	args->src = args->src[..sizeof(args->src)-5];

      args->alt = args->alt || args->src;
      args->src = "/internal-roxen-" + args->src;
      args->border = args->border || "0";

      int xml=!m_delete(args, "noxml");
      result = Roxen.make_tag("img", args, xml);
      return 0;
    }
  }
}

class TagDate {
  inherit RXML.Tag;
  constant name = "date";
  constant flags = RXML.FLAG_EMPTY_ELEMENT;

  class Frame {
    inherit RXML.Frame;

    array do_return(RequestID id) {
      int t=(int)args["unix-time"] || time(1);
      if(args->timezone=="GMT") t += localtime(t)->timezone;
      t+=Roxen.time_dequantifier(args);

      if(!(args->brief || args->time || args->date))
	args->full=1;

      if(args->part=="second" || args->part=="beat" || args->strftime)
	NOCACHE();
      else
	CACHE(60);

      result = Roxen.tagtime(t, args, id, language);
      return 0;
    }
  }
}

class TagInsert {
  inherit RXML.Tag;
  constant name = "insert";
  constant flags = RXML.FLAG_EMPTY_ELEMENT | RXML.FLAG_SOCKET_TAG;
  // FIXME: result_types needs to be updated with all possible outputs
  // from the plugins.

  class Frame {
    inherit RXML.Frame;

    void do_insert(RXML.Tag plugin, string name, RequestID id) {
      result=plugin->get_data(args[name], args, id);

      if(plugin->get_type)
	result_type=plugin->get_type(args, result);
      else if(args->quote=="none")
	result_type=RXML.t_xml;
      else if(args->quote=="html")
	result_type=RXML.t_text;
      else
	result_type=RXML.t_text;
    }

    array do_return(RequestID id) {

      if(args->source) {
	RXML.Tag plugin=get_plugins()[args->source];
	if(!plugin) RXML.parse_error("Source "+args->source+" not present.\n");
	do_insert(plugin, args->source, id);
	return 0;
      }
      foreach((array)get_plugins(), [string name, RXML.Tag plugin]) {
	if(args[name]) {
	  do_insert(plugin, name, id);
	  return 0;
	}
      }

      parse_error("No correct insert attribute given.\n");
    }
  }
}

class TagInsertVariable {
  inherit RXML.Tag;
  constant name = "insert";
  constant plugin_name = "variable";

  string get_data(string var, mapping args, RequestID id) {
    if(zero_type(RXML.user_get_var(var, args->scope)))
      RXML.run_error("No such variable ("+var+").\n", id);
    if(args->index) {
      mixed data = RXML.user_get_var(var, args->scope);
      if(intp(data) || floatp(data))
	RXML.run_error("Can not index numbers.\n");
      if(stringp(data)) {
	if(args->split)
	  data = data / args->split;
	else
	  data = ({ data });
      }
      if(arrayp(data)) {
	int index = (int)args->index;
	if(index<0) index=sizeof(data)+index+1;
	if(sizeof(data)<index || index<1)
	  RXML.run_error("Index out of range.\n");
	else
	  return data[index-1];
      }
      if(data[args->index]) return data[args->index];
      RXML.run_error("Could not index variable data\n");
    }
    return (string)RXML.user_get_var(var, args->scope);
  }
}

class TagInsertVariables {
  inherit RXML.Tag;
  constant name = "insert";
  constant plugin_name = "variables";

  string get_data(string var, mapping args) {
    RXML.Context context=RXML.get_context();
    if(var=="full")
      return map(sort(context->list_var(args->scope)),
		 lambda(string s) {
		   return sprintf("%s=%O", s, context->get_var(s, args->scope) );
		 } ) * "\n";
    return String.implode_nicely(sort(context->list_var(args->scope)));
  }
}

class TagInsertScopes {
  inherit RXML.Tag;
  constant name = "insert";
  constant plugin_name = "scopes";

  string get_data(string var, mapping args) {
    RXML.Context context=RXML.get_context();
    if(var=="full") {
      string result = "";
      foreach(sort(context->list_scopes()), string scope) {
	result += scope+"\n";
	result += Roxen.html_encode_string(map(sort(context->list_var(args->scope)),
					       lambda(string s) {
						 return sprintf("%s.%s=%O", scope, s,
								context->get_var(s, args->scope) );
					       } ) * "\n");
	result += "\n";
      }
      return result;
    }
    return String.implode_nicely(sort(context->list_scopes()));
  }
}

class TagInsertFile {
  inherit RXML.Tag;
  constant name = "insert";
  constant plugin_name = "file";

  RXML.Type get_type(mapping args) {
    if (args->quote=="html")
      return RXML.t_text;
    return RXML.t_xml;
  }

  string get_data(string var, mapping args, RequestID id)
  {
    string result;
    if(args->nocache) // try_get_file never uses the cache any more.
      CACHE(0);      // Should we really enforce CACHE(0) here?
    
    result=id->conf->try_get_file(var, id);

    if( !result )
      RXML.run_error("No such file ("+Roxen.fix_relative( var, id )+").\n");

#if ROXEN_COMPAT <= 1.3
    if(id->conf->old_rxml_compat)
      return Roxen.parse_rxml(result, id);
#endif
    return result;
  }
}

class TagInsertRealfile {
  inherit RXML.Tag;
  constant name = "insert";
  constant plugin_name = "realfile";

  string get_data(string var, mapping args, RequestID id) {
    string filename=id->conf->real_file(Roxen.fix_relative(var, id), id);
    if(!filename)
      RXML.run_error("Could not find the file %s.\n", Roxen.fix_relative(var, id));
    Stdio.File file=Stdio.File(filename, "r");
    if(file)
      return file->read();
    RXML.run_error("Could not open the file %s.\n", Roxen.fix_relative(var, id));
  }
}

class TagReturn {
  inherit RXML.Tag;
  constant name = "return";
  constant flags = RXML.FLAG_EMPTY_ELEMENT;

  class Frame {
    inherit RXML.Frame;

    array do_return(RequestID id)
    {
      if(args->code)
	_error = (int)args->code;
      if(args->text)
	_rettext = replace(args->text, "\n\r"/1, "%0A%0D"/3);
      return 0;
    }
  }
}

class TagSetCookie {
  inherit RXML.Tag;
  constant name = "set-cookie";
  constant flags = RXML.FLAG_EMPTY_ELEMENT;

  mapping(string:RXML.Type) req_arg_types = ([ "name" : RXML.t_text(RXML.PEnt) ]);

  class Frame {
    inherit RXML.Frame;

    array do_return(RequestID id) {
      int t;
      if(args->persistent) t=-1; else t=Roxen.time_dequantifier(args);
      Roxen.set_cookie( id,  args->name, (args->value||""), t, 
                        args->domain, args->path );
      return 0;
    }
  }
}

class TagRemoveCookie {
  inherit RXML.Tag;
  constant name = "remove-cookie";
  constant flags = RXML.FLAG_EMPTY_ELEMENT;

  mapping(string:RXML.Type) req_arg_types = ([ "name" : RXML.t_text(RXML.PEnt) ]);
  mapping(string:RXML.Type) opt_arg_types = ([ "value" : RXML.t_text(RXML.PEnt) ]);

  class Frame {
    inherit RXML.Frame;

    array do_return(RequestID id) {
//    really... is this error a good idea?  I don't think so, it makes
//    it harder to make pages that use cookies. But I'll let it be for now.
//       /Per

      if(!id->cookies[args->name])
        RXML.run_error("That cookie does not exist.\n");
      Roxen.remove_cookie( id, args->name, 
                           (args->value||id->cookies[args->name]||""), 
                           args->domain, args->path );
      return 0;
    }
  }
}

string tag_modified(string tag, mapping m, RequestID id, Stdio.File file)
{

  if(m->by && !m->file && !m->realfile)
  {
    // FIXME: The auth module should probably not be used in this case.
    if(!id->conf->auth_module)
      RXML.run_error("Modified by requires a user database.\n");
    // FIXME: The next row is defunct. last_modified_by does not exist.
    m->name = id->conf->last_modified_by(file, id);
    CACHE(10);
    return tag_user(tag, m, id);
  }

  if(m->file)
    m->realfile = id->conf->real_file(Roxen.fix_relative( m_delete(m, "file"), id), id);

  if(m->by && m->realfile)
  {
    if(!id->conf->auth_module)
      RXML.run_error("Modified by requires a user database.\n");

    Stdio.File f;
    if(f = open(m->realfile, "r"))
    {
      m->name = id->conf->last_modified_by(f, id);
      destruct(f);
      CACHE(10);
      return tag_user(tag, m, id);
    }
    return "A. Nonymous.";
  }

  Stat s;
  if(m->realfile)
    s = file_stat(m->realfile);
  else if (_stat)
    s = _stat;
  else
    s =  id->conf->stat_file(id->not_query, id);

  if(s) {
    CACHE(10);
    if(m->ssi)
      return Roxen.strftime(id->misc->ssi_timefmt || "%c", s[3]);
    return Roxen.tagtime(s[3], m, id, language);
  }

  if(m->ssi) return id->misc->ssi_errmsg||"";
  RXML.run_error("Couldn't stat file.\n");
}

string|array(string) tag_user(string tag, mapping m, RequestID id )
{
  if(!id->conf->auth_module)
    RXML.run_error("Requires a user database.\n");

  if (!m->name)
    return "";

  string b=m->name;

  array(string) u=id->conf->userinfo(b, id);
  if(!u) return "";

  string dom = id->conf->query("Domain");
  if(sizeof(dom) && (dom[-1]=='.'))
    dom = dom[0..strlen(dom)-2];

  if(m->realname && !m->email)
  {
    if(m->link && !m->nolink)
      return ({ "<a href=\"/~"+b+"/\">"+u[4]+"</a>" });
    return ({ u[4] });
  }

  if(m->email && !m->realname)
  {
    if(m->link && !m->nolink)
      return ({ sprintf("<a href=\"mailto:%s@%s\">%s@%s</a>",
			b, dom, b, dom)
	      });
    return ({ b + "@" + dom });
  }

  if(m->nolink && !m->link)
    return ({ sprintf("%s &lt;%s@%s&gt;",
		      u[4], b, dom)
	    });

  return ({ sprintf( (m->nohomepage?"":"<a href=\"/~%s/\">%s</a> ")+
		    "<a href=\"mailto:%s@%s\">&lt;%s@%s&gt;</a>",
		    b, u[4], b, dom, b, dom)
	  });
}

class TagSetMaxCache {
  inherit RXML.Tag;
  constant name = "set-max-cache";
  constant flags = RXML.FLAG_EMPTY_ELEMENT;
  class Frame {
    inherit RXML.Frame;
    array do_return(RequestID id) {
      id->misc->cacheable = Roxen.time_dequantifier(args);
    }
  }
}


// ------------------- Containers ----------------
class TagCharset
{
  inherit RXML.Tag;
  constant name="charset";
  RXML.Type content_type = RXML.t_same;

  class Frame
  {
    inherit RXML.Frame;
    array do_return( RequestID id )
    {
      if( args->in && catch {
	content=Locale.Charset.decoder( args->in )->feed( content )->drain();
      })
	RXML.run_error("Illegal charset, or unable to decode data: %s\n",
		       args->in );
      if( args->out && id->set_output_charset)
	id->set_output_charset( args->out );
      result_type = result_type (RXML.PXml);
      result="";
      return ({content});
    }
  }
}

class TagScope {
  inherit RXML.Tag;

  constant name = "scope";
  mapping(string:RXML.Type) opt_arg_types = ([ "extend" : RXML.t_text(RXML.PEnt) ]);

  class Frame {
    inherit RXML.Frame;

    string scope_name;
    mapping|object vars;
    mapping oldvar;

    array do_enter(RequestID id) {
      scope_name=args->extend || "form";
      // FIXME: Should probably work like this, but it's anything but
      // simple to do that now, since variables is a class that simply
      // fakes the old variable structure using real_variables
// #if ROXEN_COMPAT <= 1.3
//       if(scope_name=="form") oldvar=id->variables;
// #endif
      if(args->extend)
	// This is not really good, since we are peeking on the
	// RXML parser internals without any abstraction...
	vars=copy_value(RXML.get_context()->scopes[scope_name]);
      else
	vars=([]);
// #if ROXEN_COMPAT <= 1.3
//       if(oldvar) id->variables=vars;
// #endif
      return 0;
    }

    array do_return(RequestID id) {
// #if ROXEN_COMPAT <= 1.3
//       if(oldvar) id->variables=oldvar;
// #endif
      result=content;
      return 0;
    }
  }
}

array(string) container_catch( string tag, mapping m, string c, RequestID id )
{
  string r;
  mixed e = catch(r=Roxen.parse_rxml(c, id));
  if(e && objectp(e) && e->tag_throw) return ({ e->tag_throw });
  if(e) throw(e);
  return ({r});
}

class TagCache {
  inherit RXML.Tag;
  constant name = "cache";
  RXML.Type content_type = RXML.t_same;

  class Frame {
    inherit RXML.Frame;
    array do_return(RequestID id) {
#define HASH(x) (x+id->not_query+id->query+id->realauth+id->conf->query("MyWorldLocation"))
      string key="";
      if(!args->nohash) {
	object md5 = Crypto.md5();
	md5->update(HASH(content));
	key=md5->digest();
      }
      if(args->key)
	key += args->key;
      result = cache_lookup("tag_cache", key);
      if(!result) {
	result = Roxen.parse_rxml(content, id);
	cache_set("tag_cache", key, result, Roxen.time_dequantifier(args));
      }
#undef HASH
      return 0;
    }
  }
}

class TagCrypt {
  inherit RXML.Tag;
  constant name = "crypt";

  class Frame {
    inherit RXML.Frame;

    array do_return(RequestID id) {
      if(args->compare) {
	_ok=crypt(content,args->compare);
	return 0;
      }
      result=crypt(content);
      return 0;
    }
  }
}

class TagFor {
  inherit RXML.Tag;
  constant name = "for";

  class Frame {
    inherit RXML.Frame;

    private int from,to,step,count;

    array do_enter(RequestID id) {
      from = (int)args->from;
      to = (int)args->to;
      step = (int)args->step!=0?(int)args->step:(to<from?-1:1);
      if((to<from && step>0)||(to>from && step<0))
	run_error("Step has the wrong sign.\n");
      from-=step;
      count=from;
      return 0;
    }

    int do_iterate() {
      if(!args->variable) {
	int diff=abs(to-from);
	to=from;
	return diff;
      }
      count+=step;
      RXML.user_set_var(args->variable, count, args->scope);
      if(to<from) return count>=to;
      return count<=to;
    }

    array do_return(RequestID id) {
      if(args->variable) RXML.user_set_var(args->variable, count-step, args->scope);
      result=content;
      return 0;
    }
  }
}

string simpletag_apre(string tag, mapping m, string q, RequestID id)
{
  string href;

  if(m->href) {
    href=m_delete(m, "href");
    array(string) split = href/":";
    if ((sizeof(split) > 1) && (sizeof(split[0]/"/") == 1))
      return RXML.t_xml->format_tag("a", m, q);
    href=Roxen.strip_prestate(Roxen.fix_relative(href, id));
  }
  else
    href=Roxen.strip_prestate(Roxen.strip_config(id->raw_url));

  if(!strlen(href))
    href="";

  multiset prestate = (< @indices(id->prestate) >);

  // FIXME: add and drop should handle t_array
  if(m->add)
    foreach((m_delete(m, "add") - " ")/",", string s)
      prestate[s]=1;

  if(m->drop)
    foreach((m_delete(m,"drop") - " ")/",", string s)
      prestate[s]=0;

  m->href = Roxen.add_pre_state(href, prestate);
  return RXML.t_xml->format_tag("a", m, q);
}

string simpletag_aconf(string tag, mapping m,
		       string q, RequestID id)
{
  string href;

  if(!m->href) {
    href=m_delete(m, "href");
    if (search(href, ":") == search(href, "//")-1)
      RXML.parse_error("It is not possible to add configs to absolute URLs.\n");
    href=Roxen.fix_relative(href, id);    
  }
  else
    href=Roxen.strip_prestate(Roxen.strip_config(id->raw_url));

  array cookies = ({});
  // FIXME: add and drop should handle t_array
  if(m->add)
    foreach((m_delete(m,"add") - " ")/",", string s)
      cookies+=({s});

  if(m->drop)
    foreach((m_delete(m,"drop") - " ")/",", string s)
      cookies+=({"-"+s});

  m->href = Roxen.add_config(href, cookies, id->prestate);
  return RXML.t_xml->format_tag("a", m, q);
}

string simpletag_maketag(string tag, mapping m, string cont, RequestID id)
{
  mapping args=([]);

  if(m->type=="pi")
    return RXML.t_xml->format_tag(m->name, 0, cont, RXML.FLAG_PROC_INSTR);

  cont=Parser.HTML()->
    add_container("attrib", 
		  lambda(string tag, mapping m, string cont) {
		    args[m->name]=cont;
		    return "";
		  })->
    feed(cont)->read();

  if(m->type=="container")
    return RXML.t_xml->format_tag(m->name, args, cont);
  if(m->type=="tag")
    return Roxen.make_tag(m->name, args, !m->noxml);
  RXML.parse_error("No type given.\n");
}

class TagDoc {
  inherit RXML.Tag;
  constant name="doc";
  RXML.Type content_type = RXML.t_same;

  class Frame {
    inherit RXML.Frame;

    array do_enter(RequestID id) {
      if(args->preparse) content_type = result_type(RXML.PXml);
      return 0;
    }

    array do_return(RequestID id) {
      array from;
      if(args->quote) {
	m_delete(args, "quote");
	from=({ "<", ">", "&" });
      }
      else
	from=({ "{", "}", "&" });

      result=replace(content, from, ({ "&lt;", "&gt;", "&amp;"}) );

      if(args->pre) {
	m_delete(args, "pre");
	result="\n"+RXML.t_xml->format_tag("pre", args, result)+"\n";
      }

      return 0;
    }
  }
}

string simpletag_autoformat(string tag, mapping m, string s, RequestID id)
{
  s-="\r";

  string p=(m["class"]?"<p class=\""+m["class"]+"\">":"<p>");

  if(!m->nonbsp)
  {
    s = replace(s, "\n ", "\n&nbsp;"); // "|\n |"      => "|\n&nbsp;|"
    s = replace(s, "  ", "&nbsp; ");  //  "|   |"      => "|&nbsp;  |"
    s = replace(s, "  ", " &nbsp;"); //   "|&nbsp;  |" => "|&nbsp; &nbsp;|"
  }

  if(!m->nobr) {
    s = replace(s, "\n", "<br />\n");
    if(m->p) {
      if(search(s, "<br />\n<br />\n")!=-1) s=p+s;
      s = replace(s, "<br />\n<br />\n", "\n</p>"+p+"\n");
      if(sizeof(s)>3 && s[0..2]!="<p>" && s[0..2]!="<p ")
        s=p+s;
      if(s[..sizeof(s)-4]==p)
        return s[..sizeof(s)-4];
      else
        return s+"</p>";
    }
    return s;
  }

  if(m->p) {
    if(search(s, "\n\n")!=-1) s=p+s;
      s = replace(s, "\n\n", "\n</p>"+p+"\n");
      if(sizeof(s)>3 && s[0..2]!="<p>" && s[0..2]!="<p ")
        s=p+s;
      if(s[..sizeof(s)-4]==p)
        return s[..sizeof(s)-4];
      else
        return s+"</p>";
    }

  return s;
}

class Smallcapsstr (string bigtag, string smalltag, mapping bigarg, mapping smallarg)
{
  constant UNDEF=0, BIG=1, SMALL=2;
  static string text="",part="";
  static int last=UNDEF;

  string _sprintf() {
    return "Smallcapsstr("+bigtag+","+smalltag+")";
  }

  void add(string char) {
    part+=char;
  }

  void add_big(string char) {
    if(last!=BIG) flush_part();
    part+=char;
    last=BIG;
  }

  void add_small(string char) {
    if(last!=SMALL) flush_part();
    part+=char;
    last=SMALL;
  }

  void write(string txt) {
    if(last!=UNDEF) flush_part();
    part+=txt;
  }

  void flush_part() {
    switch(last){
    case UNDEF:
    default:
      text+=part;
      break;
    case BIG:
      text+=RXML.t_xml->format_tag(bigtag, bigarg, part);
      break;
    case SMALL:
      text+=RXML.t_xml->format_tag(smalltag, smallarg, part);
      break;
    }
    part="";
    last=UNDEF;
  }

  string value() {
    if(last!=UNDEF) flush_part();
    return text;
  }
}

string simpletag_smallcaps(string t, mapping m, string s)
{
  Smallcapsstr ret;
  string spc=m->space?"&nbsp;":"";
  m_delete(m, "space");
  mapping bm=([]), sm=([]);
  if(m["class"] || m->bigclass) {
    bm=(["class":(m->bigclass||m["class"])]);
    m_delete(m, "bigclass");
  }
  if(m["class"] || m->smallclass) {
    sm=(["class":(m->smallclass||m["class"])]);
    m_delete(m, "smallclass");
  }

  if(m->size) {
    bm+=(["size":m->size]);
    if(m->size[0]=='+' && (int)m->size>1)
      sm+=(["size":m->small||"+"+((int)m->size-1)]);
    else
      sm+=(["size":m->small||(string)((int)m->size-1)]);
    m_delete(m, "small");
    ret=Smallcapsstr("font","font", m+bm, m+sm);
  }
  else
    ret=Smallcapsstr("big","small", m+bm, m+sm);

  for(int i=0; i<strlen(s); i++)
    if(s[i]=='<') {
      int j;
      for(j=i; j<strlen(s) && s[j]!='>'; j++);
      ret->write(s[i..j]);
      i+=j-1;
    }
    else if(s[i]<=32)
      ret->add_small(s[i..i]);
    else if(lower_case(s[i..i])==s[i..i])
      ret->add_small(upper_case(s[i..i])+spc);
    else if(upper_case(s[i..i])==s[i..i])
      ret->add_big(s[i..i]+spc);
    else
      ret->add(s[i..i]+spc);

  return ret->value();
}

string simpletag_random(string tag, mapping m, string s, RequestID id)
{
  NOCACHE();
  array q = s/(m->separator || m->sep || "\n");
  int index;
  if(m->seed)
    index = array_sscanf(Crypto.md5()->update(m->seed)->digest(),
			 "%4c")[0]%sizeof(q);
  else
    index = random(sizeof(q));

  return q[index];
}

class TagGauge {
  inherit RXML.Tag;
  constant name = "gauge";

  class Frame {
    inherit RXML.Frame;
    int t;

    array do_enter(RequestID id) {
      NOCACHE();
      t=gethrtime();
    }

    array do_return(RequestID id) {
      t=gethrtime()-t;
      if(args->variable) RXML.user_set_var(args->variable, t/1000000.0, args->scope);
      if(args->silent) return ({ "" });
      if(args->timeonly) return ({ sprintf("%3.6f", t/1000000.0) });
      if(args->resultonly) return ({content});
      return ({ "<br /><font size=\"-1\"><b>Time: "+
		sprintf("%3.6f", t/1000000.0)+
		" seconds</b></font><br />"+content });
    }
  }
}

// Removes empty lines
string simpletag_trimlines( string tag_name, mapping args,
                           string contents, RequestID id )
{
  contents = replace(contents, ({"\r\n","\r" }), ({"\n","\n"}));
  return (contents / "\n" - ({ "" })) * "\n";
}

void container_throw( string t, mapping m, string c, RequestID id)
{
  if(c[-1]!='\n') c+="\n";
  throw( class(string tag_throw) {}( c ) );
}

// Internal methods for the default tag
private int|array internal_tag_input(string t, mapping m, string name, multiset(string) value)
{
  if (name && m->name!=name) return 0;
  if (m->type!="checkbox" && m->type!="radio") return 0;
  if (value[m->value||"on"]) {
    if (m->checked) return 0;
    m->checked = "checked";
  }
  else {
    if (!m->checked) return 0;
    m_delete(m, "checked" );
  }

  int xml=!m_delete(m, "noxml");

  return ({ Roxen.make_tag(t, m, xml) });
}
array split_on_option( string what, Regexp r )
{
  array a = r->split( what );
  if( !a )
     return ({ what });
  return split_on_option( a[0], r ) + a[1..];
}
private int|array internal_tag_select(string t, mapping m, string c, string name, multiset(string) value)
{
  if(name && m->name!=name) return ({ RXML.t_xml->format_tag(t, m, c) });

  // Split indata into an array with the layout
  // ({ "option", option_args, stuff_before_next_option })*n
  // e.g. "fox<OPtioN foo='bar'>gazink</option>" will yield
  // tmp=({ "OPtioN", " foo='bar'", "gazink</option>" }) and
  // ret="fox"
  Regexp r = Regexp( "(.*)<([Oo][Pp][Tt][Ii][Oo][Nn])([^>]*)>(.*)" );
  array(string) tmp=split_on_option(c,r);
  string ret=tmp[0],nvalue;
  int selected,stop;
  tmp=tmp[1..];

  while(sizeof(tmp)>2) {
    stop=search(tmp[2],"<");
    if(sscanf(tmp[1],"%*svalue=%s",nvalue)!=2 &&
       sscanf(tmp[1],"%*sVALUE=%s",nvalue)!=2)
      nvalue=tmp[2][..stop==-1?sizeof(tmp[2]):stop];
    else if(!sscanf(nvalue, "\"%s\"", nvalue) && !sscanf(nvalue, "'%s'", nvalue))
      sscanf(nvalue, "%s%*[ >]", nvalue);
    selected=Regexp(".*[Ss][Ee][Ll][Ee][Cc][Tt][Ee][Dd].*")->match(tmp[1]);
    ret+="<"+tmp[0]+tmp[1];
    if(value[nvalue] && !selected) ret+=" selected=\"selected\"";
    ret+=">"+tmp[2];
    if(!Regexp(".*</[Oo][Pp][Tt][Ii][Oo][Nn]")->match(tmp[2])) ret+="</"+tmp[0]+">";
    tmp=tmp[3..];
  }
  return ({ RXML.t_xml->format_tag(t, m, ret) });
}

string simpletag_default( string t, mapping m, string c, RequestID id)
{
  multiset value=(<>);
  if(m->value) value=mkmultiset((m->value||"")/(m->separator||","));
  if(m->variable) value+=(<RXML.user_get_var(m->variable, m->scope)>);
  if(value==(<>)) return c;

  return parse_html(c, (["input":internal_tag_input]),
		    (["select":internal_tag_select]),
		    m->name, value);
}

string simpletag_sort(string t, mapping m, string c, RequestID id)
{
  if(!m->separator)
    m->separator = "\n";

  string pre="", post="";
  array lines = c/m->separator;

  while(lines[0] == "")
  {
    pre += m->separator;
    lines = lines[1..];
  }

  while(lines[-1] == "")
  {
    post += m->separator;
    lines = lines[..sizeof(lines)-2];
  }

  lines=sort(lines);

  return pre + (m->reverse?reverse(lines):lines)*m->separator + post;
}

string simpletag_replace( string tag, mapping m, string cont, RequestID id)
{
  switch(m->type)
  {
  case "word":
  default:
    if(!m->from) return cont;
   return replace(cont,m->from,(m->to?m->to:""));

  case "words":
    if(!m->from) return cont;
    string s=m->separator?m->separator:",";
    array from=(array)(m->from/s);
    array to=(array)(m->to/s);

    int balance=sizeof(from)-sizeof(to);
    if(balance>0) to+=allocate(balance,"");

    return replace(cont,from,to);
  }
}

class TagCSet {
  inherit RXML.Tag;
  constant name = "cset";
  class Frame {
    inherit RXML.Frame;
    array do_return(RequestID id) {
      if( !args->variable ) parse_error("Variable not specified.\n");
      if(!content) content="";
      if( args->quote != "none" )
	content = Roxen.html_decode_string( content );

      RXML.user_set_var(args->variable, content, args->scope);
      return ({ "" });
    }
  }
}

class TagColorScope {
  inherit RXML.Tag;
  constant name = "colorscope";

  class Frame {
    inherit RXML.Frame;
    string link, alink, vlink;

#define LOCAL_PUSH(X) if(args->X) { X=id->misc->defines->X; id->misc->defines->X=args->X; }
    array do_enter(RequestID id) {
      Roxen.push_color("colorscope",args,id);
      LOCAL_PUSH(link);
      LOCAL_PUSH(alink);
      LOCAL_PUSH(vlink);
      return 0;
    }

#define LOCAL_POP(X) if(X) id->misc->defines->X=X
    array do_return(RequestID id) {
      Roxen.pop_color("colorscope",id);
      LOCAL_POP(link);
      LOCAL_POP(alink);
      LOCAL_POP(vlink);
      result=content;
      return 0;
    }
  }
}


// ----------------- If registration stuff --------------

class TagIfExpr {
  inherit RXML.Tag;
  constant name = "if";
  constant plugin_name = "expr";
  int eval(string u) {
    return (int)sexpr_eval(u);
  }
}


// ---------------- Emit registration stuff --------------

class TagEmitFonts
{
  inherit RXML.Tag;
  constant name = "emit", plugin_name = "fonts";
  array get_dataset(mapping args, RequestID id)
  {
    return roxen->fonts->get_font_information(args->ttf_only);
  }
}


// ---------------- API registration stuff ---------------

string api_query_modified(RequestID id, string f, int|void by)
{
  mapping m = ([ "by":by, "file":f ]);
  return tag_modified("modified", m, id, id);
}


// --------------------- Documentation -----------------------

TAGDOCUMENTATION;
#ifdef manual
constant tagdoc=([
"&client.ip;":#"<desc ent='ent'><p>
 The client is located on this IP-address.
</p></desc>",

"&client.host;":#"<desc ent='ent'><p>
 The host name of the client, if possible to resolve.
</p></desc>",

"&client.name;":#"<desc ent='ent'><p>
 The name of the client, i.e. \"Mozilla/4.7\".
</p></desc>",

"&client.Fullname;":#"<desc ent='ent'><p>
 The full user agent string, i.e. name of the client and additional
 info like; operating system, type of computer, etc. E.g.
 \"Mozilla/4.7 [en] (X11; I; SunOS 5.7 i86pc)\".
</p></desc>",

"&client.fullname;":#"<desc ent='ent'><p>
 The full user agent string, i.e. name of the client and additional
 info like; operating system, type of computer, etc. E.g.
 \"mozilla/4.7 [en] (x11; i; sunos 5.7 i86pc)\".
</p></desc>",

"&client.referrer;":#"<desc ent='ent'><p>
 Prints the URL of the page on which the user followed a link that
 brought her to this page. The information comes from the referrer
 header sent by the browser.
</p></desc>",

"&client.accept-language;":#"<desc ent='ent'><p>
 The client prefers to have the page contents presented in this
 language.
</p></desc>",

"&client.accept-languages;":#"<desc ent='ent'><p>
 The client prefers to have the page contents presented in this
 language but these additional languages are accepted as well.
</p></desc>",

"&client.language;":#"<desc ent='ent'><p>
 The clients most preferred language.
</p></desc>",

"&client.languages;":#"<desc ent='ent'><p>
 An ordered list of the clients most preferred languages.
</p></desc>",

"&client.authenticated;":#"<desc ent='ent'><p>
 Returns the name of the user logged on to the site, i.e. the login
 name, if any exists.
</p></desc>",

"&client.user;":#"<desc ent='ent'><p>
 Returns the name the user used when he/she tried to log on the site,
 i.e. the login name, if any exists.
</p></desc>",

"&client.password;":#"<desc ent='ent'><p>

</p></desc>",

"&client.height;":#"<desc ent='ent'><p>
 The presentation area height in pixels. For WAP-phones.
</p></desc>",

"&client.width;":#"<desc ent='ent'><p>
 The presentation area width in pixels. For WAP-phones.
</p></desc>",

"&client.robot;":#"<desc ent='ent'><p>

 Returns the name of the webrobot. Useful if the robot requesting
 pages is to be served other contents than most visitors. Use
 <ent>client.robot</ent> together with <xref href='../if/if.tag'
 />.</p>

 <p>Possible webrobots are: ms-url-control, architex, backrub,
 checkbot, fast, freecrawl, passagen, gcreep, getright, googlebot,
 harvest, alexa, infoseek, intraseek, lycos, webinfo, roxen,
 altavista, scout, slurp, url-minder, webcrawler, wget, xenu and
 yahoo.</p>
</desc>",

"&client.javascript;":#"<desc ent='ent'><p>
 Returns the highest version of javascript supported.
</p></desc>",

"&client.tm;":#"<desc ent='ent'><p><short>
 Generates a trademark sign in a way that the client can
 render.</short> Possible outcomes are \"&amp;trade;\",
 \"&lt;sup&gt;TM&lt;/sup&gt;\", and \"&amp;gt;TM&amp;lt;\".</p>
</desc>",


//----------------------------------------------------------------------

"&page.realfile;":#"<desc ent='ent'><p>
 Path to this file in the file system.
</p></desc>",

"&page.virtroot;":#"<desc ent='ent'><p>
 The root of the present virtual filesystem.
</p></desc>",

//  &page.virtfile; is same as &page.path; but deprecated since we want to
//  harmonize with SiteBuilder entities.
"&page.path;":#"<desc ent='ent'><p>
 Absolute path to this file in the virtual filesystem.
</p></desc>",

"&page.pathinfo;":#"<desc ent='ent'><p>
 The \"path info\" part of the URL, if any. Can only get set if the
 \"Path info support\" module is installed. For details see the
 documentation for that module.
</p></desc>",

"&page.query;":#"<desc ent='ent'><p>
 The query part of the page URI.
</p></desc>",

"&page.url;":#"<desc ent='ent'><p>
 The absolute path for this file from the web server's root or point
 of view including query variables.
</p></desc>",

"&page.last-true;":#"<desc ent='ent'><p>
 Is \"1\" if the last <tag>if</tag>-statement succeeded, otherwise 0.
 (<xref href='../if/true.tag' /> and <xref href='../if/false.tag' />
 is considered as <tag>if</tag>-statements here) See also: <xref
 href='../if/' />.</p>
</desc>",

"&page.language;":#"<desc ent='ent'><p>
 What language the contents of this file is written in. The language
 must be given as metadata to be found.
</p></desc>",

"&page.scope;":#"<desc ent='ent'><p>
 The name of the current scope, i.e. the scope accessible through the
 name \"_\".
</p></desc>",

"&page.filesize;":#"<desc ent='ent'><p>
 This file's size, in bytes.
</p></desc>",

"&page.ssl-strength;":#"<desc ent='ent'><p>
 The strength in bits of the current SSL connection.
</p></desc>",

"&page.self;":#"<desc ent='ent'><p>
 The name of this file.
</p></desc>",

//----------------------------------------------------------------------

"roxen_automatic_charset_variable":#"<desc tag='tag'><p>
 If put inside a form, the right character encoding of the submitted
 form can be guessed by Roxen WebServer.
</p></desc>",

//----------------------------------------------------------------------

"colorscope":#"<desc cont='cont'><p><short>
 Makes it possible to change the autodetected colors within the tag.
 Useful when out-of-order parsing occurs, e.g.</p>

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

<attr name='text' value='color'><p>
 Set the text color within the scope.</p>
</attr>

<attr name='bgcolor' value='color'<p>
 Set the background color within the scope.</p>
</attr>

<attr name='link' value='color'<p>
 Set the link color within the scope.</p>
</attr>

<attr name='alink' value='color'<p>
 Set the active link color within the scope.</p>
</attr>

<attr name='vlink' value='color'<p>
 Set the visited link color within the scope.</p>
</attr>",

//----------------------------------------------------------------------

"aconf":#"<desc cont='cont'><p><short>
 Creates a link that can modify the persistent states in the cookie
 RoxenConfig.</short> In practice it will add &lt;keyword&gt;/ right
 after the server, i.e. if you want to remove bacon and add egg the
 first \"directory\" in the path will be &lt;-bacon,egg&gt;. If the
 user follows this link the WebServer will understand how the
 RoxenConfig cookie should be modified and will send a new cookie
 along with a redirect to the given url, but with the first
 \"directory\" removed. The presence of a certain keyword in can be
 controlled with <xref href='../if/if_config.tag' />.</p>
</desc>

<attr name=href value=uri>
 <p>Indicates which page should be linked to, if any other than the
 present one.</p>
</attr>

<attr name=add value=string>
 <p>The \"cookie\" or \"cookies\" that should be added, in a comma
 separated list.</p>
</attr>

<attr name=drop value=string>
 <p>The \"cookie\" or \"cookies\" that should be dropped, in a comma
 separated list.</p>
</attr>

<attr name=class value=string>
 <p>This cascading style sheet (CSS) class definition will apply to
 the a-element.</p>

 <p>All other attributes will be inherited by the generated a tag.</p>
</attr>",

//----------------------------------------------------------------------

"append":#"<desc tag='tag'><p><short>
 Appends a value to a variable. The variable attribute and one more is
 required.</short>
</p></desc>

<attr name=variable value=string required='required'>
 <p>The name of the variable.</p>
</attr>

<attr name=value value=string>
 <p>The value the variable should have appended.</p>

 <ex>
 <set variable='var.ris' value='Roxen'/>
 <append variable='var.ris' value=' Internet Software'/>
 <ent>var.ris</ent>
 </ex>
</attr>

<attr name=from value=string>
 <p>The name of another variable that the value should be copied
 from.</p>
</attr>",

//----------------------------------------------------------------------

"apre":#"<desc cont='cont'><p><short>

 Creates a link that can modify prestates.</short> Prestates can be
 seen as valueless cookies or toggles that are easily modified by the
 user. The prestates are added to the URL. If you set the prestate
 \"no-images\" on \"http://www.demolabs.com/index.html\" the URL would
 be \"http://www.demolabs.com/(no-images)/\". Use <xref
 href='../if/if_prestate.tag' /> to test for the presence of a
 prestate. <tag>apre</tag> works just like the <tag>a href='...'</tag>
 container, but if no \"href\" attribute is specified, the current
 page is used. </p>

</desc>

<attr name=href value=uri>
 <p>Indicates which page should be linked to, if any other than the
 present one.</p>
</attr>

<attr name=add value=string>
 <p>The prestate or prestates that should be added, in a comma
 separated list.</p>
</attr>

<attr name=drop value=string>
 <p>The prestate or prestates that should be dropped, in a comma separated
 list.</p>
</attr>

<attr name=class value=string>
 <p>This cascading style sheet (CSS) class definition will apply to
 the a-element.</p>
</attr>",

//----------------------------------------------------------------------

"auth-required":#"<desc tag='tag'><p><short>
 Adds an HTTP auth required header and return code (401), that will
 force the user to supply a login name and password.</short> This tag
 is needed when using access control in RXML in order for the user to
 be prompted to login.
</p></desc>

<attr name=realm value=string>
 <p>The realm you are logging on to, i.e \"Demolabs Intranet\".</p>
</attr>

<attr name=message value=string>
 <p>Returns a message if a login failed or cancelled.</p>
</attr>",

//----------------------------------------------------------------------

"autoformat":#"<desc cont='cont'><p><short hide='hide'>
 Replaces newlines with <tag>br/</tag>:s'.</short>Replaces newlines with
 <tag>br /</tag>:s'.</p>

<ex><autoformat>
It is almost like
using the pre tag.
</autoformat></ex>
</desc>

<attr name=p>
 <p>Replace empty lines with <tag>p</tag>:s.</p>
<ex><autoformat p=''>
It is almost like

using the pre tag.
</autoformat></ex>
</attr>

<attr name=nobr>
 <p>Do not replace newlines with <tag>br /</tag>:s.</p>
</attr>

<attr name=nonbsp><p>
 Do not turn consecutive spaces into interleaved
 breakable/nonbreakable spaces. When this attribute is not given, the
 tag will behave more or less like HTML:s <tag>pre</tag> tag, making
 whitespace indention work, without the usually unwanted effect of
 really long lines extending the browser window width.</p>
</attr>

<attr name=class value=string>
 <p>This cascading style sheet (CSS) definition will be applied on the
 p elements.</p>
</attr>",

//----------------------------------------------------------------------

"cache":#"<desc cont='cont'><p><short>
 This simple tag RXML parse its contents and cache them using the
 normal Roxen memory cache.</short> They key used to store the cached
 contents is the MD5 hash sum of the contents, the accessed file name,
 the query string, the server URL and the authentication information,
 if available. This should create an unique key. The time during which the
 entry should be considered valid can set with one or several time attributes.
 If not provided the entry will be removed from the cache when it has
 been untouched for too long.
</p></desc>

<attr name=key value=string>
 <p>Append this value to the hash used to identify the contents for less
 risk of incorrect caching. This shouldn't really be needed.</p>
</attr>

<attr name=nohash>
 <p>The cached entry will use only the provided key as cache key.</p>
</attr>

<attr name=years value=number>
 <p>Add this number of years to the time this entry is valid.</p>
</attr>
<attr name=months value=number>
 <p>Add this number of months to the time this entry is valid.</p>
</attr>
<attr name=weeks value=number>
 <p>Add this number of weeks to the time this entry is valid.</p>
</attr>
<attr name=days value=number>
 <p>Add this number of days to the time this entry is valid.</p>
</attr>
<attr name=hours value=number>
 <p>Add this number of hours to the time this entry is valid.</p>
</attr>
<attr name=beats value=number>
 <p>Add this number of beats to the time this entry is valid.</p>
</attr>
<attr name=minutes value=number>
 <p>Add this number of minutes to the time this entry is valid.</p>
</attr>
<attr name=seconds value=number>
 <p>Add this number of seconds to the time this entry is valid.</p>
</attr>",

//----------------------------------------------------------------------

"catch":#"<desc cont='cont'><p><short>
 Evaluates the RXML code, and, if nothing goes wrong, returns the
 parsed contents.</short> If something does go wrong, the error
 message is returned instead. See also <xref
 href='throw.tag' />.
</p>
</desc>",

//----------------------------------------------------------------------
"charset":#"<desc cont='cont'><p><short>
 </short>

 </p>
</desc>",


//----------------------------------------------------------------------

"configimage":#"<desc tag='tag'><p><short>
 Returns one of the internal Roxen configuration images.</short> The
 src attribute is required.
</p></desc>

<attr name=src value=string>
 <p>The name of the picture to show.</p>
</attr>

<attr name=border value=number default=0>
 <p>The image border when used as a link.</p>
</attr>

<attr name=alt value=string default='The src string'>
 <p>The picture description.</p>
</attr>

<attr name=class value=string>
 <p>This cascading style sheet (CSS) class definition will be applied to
 the image.</p>

 <p>All other attributes will be inherited by the generated img tag.</p>
</attr>",

//----------------------------------------------------------------------

"configurl":#"<desc tag='tag'><p><short>
 Returns a URL to the administration interface.</short>
</p></desc>",

//----------------------------------------------------------------------

"charset":#"<desc cont='cont'><p><short>
 </short>

 </p>
</desc>",

//----------------------------------------------------------------------

"configimage":#"<desc tag='tag'><p><short>
 Returns one of the internal Roxen configuration images.</short> The
 src attribute is required.
</p></desc>

<attr name=src value=string>
 <p>The name of the picture to show.</p>
</attr>

<attr name=border value=number default=0>
 <p>The image border when used as a link.</p>
</attr>

<attr name=alt value=string default='The src string'>
 <p>The picture description.</p>
</attr>

<attr name=class value=string>
 <p>This cascading style sheet (CSS) class definition will be applied to
 the image.</p>

 <p>All other attributes will be inherited by the generated img tag.</p>
</attr>",

//----------------------------------------------------------------------

"configurl":#"<desc tag='tag'><p><short>
 Returns a URL to the administration interface.</short>
</p></desc>",

//----------------------------------------------------------------------

"cset":#"<desc cont='cont'><p>
 Sets a variable with its content.</p>
</desc>

<attr name=variable value=name>
 <p>The variable to be set.</p>
</attr>

<attr name=quote value=html|none>
 <p>How the content should be quoted before assigned to the variable.
 Default is html.</p>
</attr>",

//----------------------------------------------------------------------

"crypt":#"<desc cont='cont'><p><short>
 Encrypts the contents as a Unix style password.</short> Useful when
 combined with services that use such passwords.</p>

 <p>Unix style passwords are one-way encrypted, to prevent the actual
 clear-text password from being stored anywhere. When a login attempt
 is made, the password supplied is also encrypted and then compared to
 the stored encrypted password.</p>
</desc>

<attr name=compare value=string>
 <p>Compares the encrypted string with the contents of the tag. The tag
 will behave very much like an <xref href='../if/if.tag' /> tag.</p>
<ex><crypt compare=\"LAF2kkMr6BjXw\">Roxen</crypt>
<then>Yepp!</then>
<else>Nope!</else>
</ex>
</attr>",

//----------------------------------------------------------------------

"date":#"<desc tag='tag'><p><short>
 Inserts the time and date.</short> Does not require attributes.
</p></desc>

<attr name=unix-time value=number of seconds>
 <p>Display this time instead of the current. This attribute uses the
 specified Unix 'time_t' time as the starting time (which is
 <i>01:00, January the 1st, 1970</i>), instead of the current time.
 This is mostly useful when the <tag>date</tag> tag is used from a
 Pike-script or Roxen module.</p>

<ex ><date unix-time='120'/></ex>
</attr>

<attr name=timezone value=local|GMT default=local>
 <p>Display the time from another timezone.</p>
</attr>

<attr name=years value=number>
 <p>Add this number of years to the result.</p>
 <ex ><date date='' years='2'/></ex>
</attr>

<attr name=months value=number>
 <p>Add this number of months to the result.</p>
 <ex ><date date='' months='2'/></ex>
</attr>

<attr name=weeks value=number>
 <p>Add this number of weeks to the result.</p>
 <ex ><date date='' weeks='2'/></ex>
</attr>

<attr name=days value=number>
 <p>Add this number of days to the result.</p>
</attr>

<attr name=hours value=number>
 <p>Add this number of hours to the result.</p>
 <ex ><date time='' hours='2' type='iso'/></ex>
</attr>

<attr name=beats value=number>
 <p>Add this number of beats to the result.</p>
 <ex ><date time='' beats='10' type='iso'/></ex>
</attr>

<attr name=minutes value=number>
 <p>Add this number of minutes to the result.</p>
</attr>

<attr name=seconds value=number>
 <p>Add this number of seconds to the result.</p>
</attr>

<attr name=adjust value=number>
 <p>Add this number of seconds to the result.</p>
</attr>

<attr name=brief>
 <p>Show in brief format.</p>
<ex ><date brief=''/></ex>
</attr>

<attr name=time>
 <p>Show only time.</p>
<ex ><date time=''/></ex>
</attr>

<attr name=date>
 <p>Show only date.</p>
<ex ><date date=''/></ex>
</attr>

<attr name=type value=string|ordered|iso|discordian|stardate|number|unix>
 <p>Defines in which format the date should be displayed in. Discordian
 and stardate only make a difference when not using part. Note that
 type=stardate has a separate companion attribute, prec, which sets
 the precision.</p>

<xtable>
<row><c><p><i>type=discordian</i></p></c><c><p><ex ><date date='' type='discordian'/> </ex></p></c></row>
<row><c><p><i>type=iso</i></p></c><c><p><ex ><date date='' type='iso'/></ex></p></c></row>
<row><c><p><i>type=number</i></p></c><c><p><ex ><date date='' type='number'/></ex></p></c></row>
<row><c><p><i>type=ordered</i></p></c><c><p><ex ><date date='' type='ordered'/></ex></p></c></row>
<row><c><p><i>type=stardate</i></p></c><c><p><ex ><date date='' type='stardate'/></ex></p></c></row>
<row><c><p><i>type=string</i></p></c><c><p><ex ><date date='' type='string'/></ex></p></c></row>
<row><c><p><i>type=unix</i></p></c><c><p><ex ><date date='' type='unix'/></ex></p></c></row>
</xtable>
</attr>

<attr name=part value=year|month|day|wday|date|mday|hour|minute|second|yday|beat|week|seconds>
 <p>Defines which part of the date should be displayed. Day and wday is
 the same. Date and mday is the same. Yday is the day number of the
 year. Seconds is unix time type. Only the types string, number and
 ordered applies when the part attribute is used.</p>

<xtable>
<row><c><p><i>part=year</i></p></c><c><p>Display the year.<ex ><date part='year' type='number'/></ex></p></c></row>
<row><c><p><i>part=month</i></p></c><c><p>Display the month. <ex ><date part='month' type='ordered'/></ex></p></c></row>
<row><c><p><i>part=day</i></p></c><c><p>Display the weekday, starting with Sunday. <ex ><date part='day' type='ordered'/></ex></p></c></row>
<row><c><p><i>part=wday</i></p></c><c><p>Display the weekday. Same as 'day'. <ex ><date part='wday' type='string'/></ex></p></c></row>
<row><c><p><i>part=date</i></p></c><c><p>Display the day of this month. <ex ><date part='date' type='ordered'/></ex></p></c></row>
<row><c><p><i>part=mday</i></p></c><c><p>Display the number of days since the last full month. <ex ><date part='mday' type='number'/></ex></p></c></row>
<row><c><p><i>part=hour</i></p></c><c><p>Display the numbers of hours since midnight. <ex ><date part='hour' type='ordered'/></ex></p></c></row>
<row><c><p><i>part=minute</i></p></c><c><p>Display the numbers of minutes since the last full hour. <ex ><date part='minute' type='number'/></ex></p></c></row>
<row><c><p><i>part=second</i></p></c><c><p>Display the numbers of seconds since the last full minute. <ex ><date part='second' type='string'/></ex></p></c></row>
<row><c><p><i>part=yday</i></p></c><c><p>Display the number of days since the first of January. <ex ><date part='yday' type='ordered'/></ex></p></c></row>
<row><c><p><i>part=beat</i></p></c><c><p>Display the number of beats since midnight Central European Time(CET). There is a total of 1000 beats per day. The beats system was designed by <a href='http://www.swatch.com'>Swatch</a> as a means for a universal time, without time zones and day/night changes. <ex ><date part='beat' type='number'/></ex></p></c></row>
<row><c><p><i>part=week</i></p></c><c><p>Display the number of the current week.<ex ><date part='week' type='number'/></ex></p></c></row>
<row><c><p><i>part=seconds</i></p></c><c><p>Display the total number of seconds this year. <ex ><date part='seconds' type='number'/></ex></p></c></row>
</xtable>
</attr>

<attr name=strftime value=string>
 <p>If this attribute is given to date, it will format the result
 according to the argument string.</p>

 <xtable>
 <row><c><p>%%</p></c><c><p>Percent character</p></c></row>
 <row><c><p>%a</p></c><c><p>Abbreviated weekday name, e.g. \"Mon\"</p></c></row>
 <row><c><p>%A</p></c><c><p>Weekday name</p></c></row>
 <row><c><p>%b</p></c><c><p>Abbreviated month name, e.g. \"Jan\"</p></c></row>
 <row><c><p>%B</p></c><c><p>Month name</p></c></row>
 <row><c><p>%c</p></c><c><p>Date and time, e.g. \"%a %b %d  %H:%M:%S %Y\"</p></c></row>
 <row><c><p>%C</p></c><c><p>Century number, zero padded to two charachters.</p></c></row>
 <row><c><p>%d</p></c><c><p>Day of month (1-31), zero padded to two characters.</p></c></row>
 <row><c><p>%D</p></c><c><p>Date as \"%m/%d/%y\"</p></c></row>
 <row><c><p>%e</p></c><c><p>Day of month (1-31), space padded to two characters.</p></c></row>
 <row><c><p>%H</p></c><c><p>Hour (24 hour clock, 0-23), zero padded to two characters.</p></c></row>
 <row><c><p>%h</p></c><c><p>See %b</p></c></row>
 <row><c><p>%I</p></c><c><p>Hour (12 hour clock, 1-12), zero padded to two charcters.</p></c></row>
 <row><c><p>%j</p></c><c><p>Day numer of year (1-366), zero padded to three characters.</p></c></row>
 <row><c><p>%k</p></c><c><p>Hour (24 hour clock, 0-23), space padded to two characters.</p></c></row>
 <row><c><p>%l</p></c><c><p>Hour (12 hour clock, 1-12), space padded to two characters.</p></c></row>
 <row><c><p>%m</p></c><c><p>Month number (1-12), zero padded to two characters.</p></c></row>
 <row><c><p>%M</p></c><c><p>Minute (0-59), zero padded to two characters.</p></c></row>
 <row><c><p>%n</p></c><c><p>Newline</p></c></row>
 <row><c><p>%p</p></c><c><p>\"a.m.\" or \"p.m.\"</p></c></row>
 <row><c><p>%r</p></c><c><p>Time in 12 hour clock format with %p</p></c></row>
 <row><c><p>%R</p></c><c><p>Time as \"%H:%M\"</p></c></row>
 <row><c><p>%S</p></c><c><p>Seconds (0-61), zero padded to two characters.</p></c></row>
 <row><c><p>%t</p></c><c><p>Tab</p></c></row>
 <row><c><p>%T</p></c><c><p>Time as \"%H:%M:%S\"</p></c></row>
 <row><c><p>%u</p></c><c><p>Weekday as a decimal number (1-7), 1 is Sunday.</p></c></row>
 <row><c><p>%U</p></c><c><p>Week number of year as a decimal number (0-53), with sunday as the first day of week 1,
    zero padded to two characters.</p></c></row>
 <row><c><p>%V</p></c><c><p>ISO week number of the year as a decimal number (1-53), zero padded to two characters.</p></c></row>
 <row><c><p>%w</p></c><c><p>Weekday as a decimal number (0-6), 0 is Sunday.</p></c></row>
 <row><c><p>%W</p></c><c><p>Week number of year as a decimal number (0-53), with sunday as the first day of week 1,
    zero padded to two characters.</p></c></row>
 <row><c><p>%x</p></c><c><p>Date as \"%a %b %d %Y\"</p></c></row>
 <row><c><p>%X</p></c><c><p>See %T</p></c></row>
 <row><c><p>%y</p></c><c><p>Year (0-99), zero padded to two characters.</p></c></row>
 <row><c><p>%Y</p></c><c><p>Year (0-9999), zero padded to four characters.</p></c></row>
 </xtable>

<ex><date strftime=\"%Y%m%d\"/></ex>
</attr>

<attr name=lang value=langcode>
 <p>Defines in what language a string will be presented in. Used together
 with <att>type=string</att> and the <att>part</att> attribute to get
 written dates in the specified language.</p>

<ex><date part='day' type='string' lang='de'></ex>
</attr>

<attr name=case value=upper|lower|capitalize>
 <p>Changes the case of the output to upper, lower or capitalize.</p>
<ex><date date='' lang='&client.language;' case='upper'/></ex>
</attr>

<attr name=prec value=number>
 <p>The number of decimals in the stardate.</p>
</attr>",

//----------------------------------------------------------------------

"debug":#"<desc tag='tag'><p><short>
 Helps debugging RXML-pages as well as modules.</short> When debugging mode is
 turned on, all error messages will be displayed in the HTML code.
</p></desc>

<attr name=on>
 <p>Turns debug mode on.</p>
</attr>

<attr name=off>
 <p>Turns debug mode off.</p>
</attr>

<attr name=toggle>
 <p>Toggles debug mode.</p>
</attr>

<attr name=showid value=string>
 <p>Shows a part of the id object. E.g. showid=\"id->request_headers\".</p>
</attr>

<attr name=werror value=string>
  <p>When you have access to the server debug log and want your RXML
     page to write some kind of diagnostics message or similar, the
     werror attribute is helpful.</p>

  <p>This can be used on the error page, for instance, if you'd want
     such errors to end up in the debug log:</p>

  <ex type=box>
<debug werror='File &page.url; not found!
(linked from &client.referrer;)'/></ex>
</attr>",

//----------------------------------------------------------------------

"dec":#"<desc tag='tag'><p><short>
 Subtracts 1 from a variable.</short>
</p></desc>

<attr name=variable value=string required='required'>
 <p>The variable to be decremented.</p>
</attr>

<attr name=value value=number default=1>
 <p>The value to be subtracted.</p>
</attr>",

//----------------------------------------------------------------------

"default":#"<desc cont='cont'><p><short hide='hide'>
 Used to set default values for form elements.</short> This tag makes it easier
 to give default values to \"<tag>select</tag>\" and \"<tag>input</tag>\" form elements.
 Simply put the <tag>default</tag> tag around the form elements to which it should give
 default values.</p>

 <p>This tag is particularly useful in combination with generated forms or forms with
 generated default values, e.g. by database tags.</p>
</desc>

<attr name=value value=string>
 <p>The value or values to set. If several values are given, they are separated with the
 separator string.</p>
</attr>

<attr name=separator value=string default=','>
 <p>If several values are to be selected, this is the string that
 separates them.</p>
</attr>

<attr name=name value=string>
 <p>If used, the default tag will only affect form element with this name.</p>
</attr>

<ex type='box'>
 <default name='my-select' value='&form.preset;'>
    <select name='my-select'>
      <option value='1'>First</option>
      <option value='2'>Second</option>
      <option value='3'>Third</option>
    </select>
 </default>
</ex>

<ex type='box'>
<form>
<default value=\"&form.opt1;,&form.opt2;,&form.opt3;\">
  <input name=\"opt1\" value=\"yes1\" type=\"checkbox\" /> Option #1
  <input name=\"opt2\" value=\"yes2\" type=\"checkbox\" /> Option #2
  <input name=\"opt3\" value=\"yes3\" type=\"checkbox\" /> Option #3
  <input type=\"submit\" />
</default>
</form>
",

"doc":#"<desc cont='cont'><p><short hide='hide'>
 Eases code documentation by reformatting it.</short>Eases
 documentation by replacing \"{\", \"}\" and \"&amp;\" with
 \"&amp;lt;\", \"&amp;gt;\" and \"&amp;amp;\". No attributes required.
</p></desc>

<attr name='quote'>
 <p>Instead of replacing with \"{\" and \"}\", \"&lt;\" and \"&gt;\"
 is replaced with \"&amp;lt;\" and \"&amp;gt;\".</p>

<ex type='vert'>
<doc quote=''>
<table>
 <tr>
    <td> First cell </td>
    <td> Second cell </td>
 </tr>
</table>
</doc>
</ex>
</attr>

<attr name='pre'><p>
 The result is encapsulated within a <tag>pre</tag> container.</p>

<ex type='vert'><doc pre=''>
{table}
 {tr}
    {td} First cell {/td}
    {td} Second cell {/td}
 {/tr}
{/table}
</doc>
</ex>
</attr>

<attr name='class' value='string'>
 <p>This cascading style sheet (CSS) definition will be applied on the pre element.</p>
</attr>",

//----------------------------------------------------------------------

"expire-time":#"<desc tag='tag'><p><short hide='hide'>
 Sets client cache expire time for the document.</short>Sets client cache expire time for the document by sending the HTTP header \"Expires\".
</p></desc>

<attr name=now>
  <p>Notify the client that the document expires now. The headers \"Pragma: no-cache\" and \"Cache-Control: no-cache\"
  will be sent, besides the \"Expires\" header.</p>

</attr>

<attr name=years value=number>
 <p>Add this number of years to the result.</p>
</attr>

<attr name=months value=number>
  <p>Add this number of months to the result.</p>
</attr>

<attr name=weeks value=number>
  <p>Add this number of weeks to the result.</p>
</attr>

<attr name=days value=number>
  <p>Add this number of days to the result.</p>
</attr>

<attr name=hours value=number>
  <p>Add this number of hours to the result.</p>
</attr>

<attr name=beats value=number>
  <p>Add this number of beats to the result.</p>
</attr>

<attr name=minutes value=number>
  <p>Add this number of minutes to the result.</p>
</attr>

<attr name=seconds value=number>
   <p>Add this number of seconds to the result.</p>

 <p>It is not possible at the time to set the date beyond year 2038,
 since Unix variable <i>time_t</i> data type is used. The <i>time_t</i> data type stores the number of seconds elapsed since 00:00:00 January 1, 1970 UTC. </p>
</attr>",

//----------------------------------------------------------------------

"for":#"<desc cont='cont'><p><short>
 Makes it possible to create loops in RXML.</short>
</p></desc>

<attr name=from value=number>
 <p>Initial value of the loop variable.</p>
</attr>

<attr name=step value=number>
 <p>How much to increment the variable per loop iteration. By default one.</p>
</attr>

<attr name=to value=number>
 <p>How much the loop variable should be incremented to.</p>
</attr>

<attr name=variable value=name>
 <p>Name of the loop variable.</p>
</attr>",

//----------------------------------------------------------------------

"fsize":#"<desc tag='tag'><p><short>
 Prints the size of the specified file.</short>
</p></desc>

<attr name=file value=string>
 <p>Show size for this file.</p>
</attr>",

//----------------------------------------------------------------------

"gauge":#"<desc cont='cont'><p><short>
 Measures how much CPU time it takes to run its contents through the
 RXML parser.</short> Returns the number of seconds it took to parse
 the contents.
</p></desc>

<attr name=define value=string>
 <p>The result will be put into a variable. E.g. define=\"var.gauge\" will
 put the result in a variable that can be reached with <ent>var.gauge</ent>.</p>
</attr>

<attr name=silent>
 <p>Don't print anything.</p>
</attr>

<attr name=timeonly>
 <p>Only print the time.</p>
</attr>

<attr name=resultonly>
 <p>Only print the result of the parsing. Useful if you want to put the time in
 a database or such.</p>
</attr>",

//----------------------------------------------------------------------

"header":#"<desc tag='tag'><p><short>
 Adds a HTTP header to the page sent back to the client.</short> For
 more information about HTTP headers please steer your browser to
 chapter 14, 'Header field definitions' in <a href='http://community.roxen.com/developers/idocs/rfc/rfc2616.html'>RFC 2616</a>, available at Roxen Community.
</p></desc>

<attr name=name value=string>
 <p>The name of the header.</p>
</attr>

<attr name=value value=string>
 <p>The value of the header.</p>
</attr>",

//----------------------------------------------------------------------

"imgs":#"<desc tag='tag'><p><short>
 Generates a image tag with the correct dimensions in the width and height
 attributes. These dimensions are read from the image itself, so the image
 must exist when the tag is generated. The image must also be in GIF, JPEG/JFIF
 or PNG format.</short>
</p></desc>

<attr name=src value=string required='required'>
 <p>The path to the file that should be shown.</p>
</attr>

<attr name=alt value=string>
 <p>Description of the image. If no description is provided, the filename
 (capitalized, without extension and with some characters replaced) will
 be used.</p>
 </attr>

 <p>All other attributes will be inherited by the generated img tag.</p>",

//----------------------------------------------------------------------

"inc":#"<desc tag='tag'><p><short>
 Adds 1 to a variable.</short>
</p></desc>

<attr name=variable value=string required='required'>
 <p>The variable to be incremented.</p>
</attr>

<attr name=value value=number default=1>
 <p>The value to be added.</p>
</attr>",

//----------------------------------------------------------------------

"insert":#"<desc tag='tag'><p><short>
 Inserts a file, variable or other object into a webpage.</short>
</p></desc>

<attr name=quote value=html|none>
 <p>How the inserted data should be quoted. Default is \"html\", except for
 href and file where it's \"none\".</p>
</attr>",

//----------------------------------------------------------------------

"insert#variable":#"<desc plugin='plugin'><p><short>
 Inserts the value of a variable.</short>
</p></desc>

<attr name=variable value=string>
 <p>The name of the variable.</p>
</attr>

<attr name=scope value=string>
 <p>The name of the scope, unless given in the variable attribute.</p>
</attr>

<attr name=index value=number>
 <p>If the value of the variable is an array, the element with this
 index number will be inserted. 1 is the first element. -1 is the last
 element.</p>
</attr>

<attr name=split value=string>
 <p>A string with which the variable value should be splitted into an
 array, so that the index attribute may be used.</p>
</attr>",

//----------------------------------------------------------------------

"insert#variables":#"<desc plugin='plugin'><p><short>
 Inserts a listing of all variables in a scope.</short> Note that it is
 possible to create a scope with an infinite number of variables set.
 In this case the programme of that scope decides which variables that
 should be listable, i.e. this will not cause any problem except that
 all variables will not be listed. It is also possible to hide
 variables so that they are not listed with this tag.
</p></desc>

<attr name=variables value=full|plain>
 <p>Sets how the output should be formatted.</p>

 <ex type='vert'>
<pre>
<insert variables='full' scope='roxen'/>
</pre>
 </ex>
</attr>

<attr name=scope>
 <p>The name of the scope that should be listed, if not the present scope.</p>
</attr>",

//----------------------------------------------------------------------

"insert#scopes":#"<desc plugin='plugin'><p><short>
 Inserts a listing of all present variable scopes.</short>
</p></desc>

<attr name=scopes value=full|plain>
 <p>Sets how the output should be formatted.</p>

 <ex type='vert'>
   <insert scopes='plain'/>
 </ex>
</attr>",

//----------------------------------------------------------------------

"insert#file":#"<desc plugin='plugin'><p><short>
 Inserts the contents of a file.</short> It reads files in a way
 similar to if you fetched the file with a browser, so the file may be
 parsed before it is inserted, depending on settings in the RXML
 parser. Most notably which kinds of files (extensions) that should be
 parsed. Since it reads files like a normal request, e.g. generated
 pages from location modules can be inserted. Put the tag
 <xref href='../programming/eval.tag' /> around <tag>insert</tag> if the file should be
 parsed after it is inserted in the page. This enables RXML defines
 and scope variables to be set in the including file (as opposed to
 the included file). You can also configure the file system module so
 that files with a certain extension can not be downloaded, but still
 inserted into other documents.
</p></desc>

<attr name=file value=string>
 <p>The virtual path to the file to be inserted.</p>

 <ex type='box'>
  <eval><insert file='html_header.inc'/></eval>
 </ex>
</attr>",

//----------------------------------------------------------------------

"insert#realfile":#"<desc plugin='plugin'><p><short>
 Inserts a raw, unparsed file.</short> The disadvantage with the
 realfile plugin compared to the file plugin is that the realfile
 plugin needs the inserted file to exist, and can't fetch files from e.g.
 an arbitrary location module. Note that the realfile insert plugin
 can not fetch files from outside the virtual file system.
</p></desc>

<attr name=realfile value=string>
 <p>The virtual path to the file to be inserted.</p>
</attr>",

//----------------------------------------------------------------------

"maketag":({ #"<desc cont='cont'><p><short hide='hide'>
 Makes it possible to create tags.</short>This tag creates tags. The contents of the container will be put into the contents of the produced container.
</p></desc>

<attr name=name value=string required='required'>
 <p>The name of the tag.</p>
</attr>

<attr name=noxml>
 <p>Tags should not be terminated with a trailing slash.</p>
</attr>

<attr name=type value=tag|container|pi default=tag>
 <p>What kind of tag should be produced. The argument 'Pi' will produce a processinstruction tag. </p>
</attr>",

 ([
   "attrib":#"<desc cont='cont'><p>
   Inside the maketag container the container
   <tag>attrib</tag> is defined. It is used to add attributes to the produced
   tag. The contents of the attribute container will be the
   attribute value. E.g.</p>
   </desc>

<ex><eval>
<maketag name=\"replace\" type=\"container\">
 <attrib name=\"from\">A</attrib>
 <attrib name=\"to\">U</attrib>
 MAD
</maketag>
</eval>
</ex>
   <attr name=name value=string required=required><p>
   The name of the attribute.</p>
   </attr>"
 ])
   }),

//----------------------------------------------------------------------

"modified":#"<desc tag='tag'><p><short hide='hide'>
 Prints when or by whom a page was last modified.</short> Prints when
 or by whom a page was last modified, by default the current page.
</p></desc>

<attr name=by>
 <p>Print by whom the page was modified. Takes the same attributes as
 <xref href='user.tag' />. This attribute requires a userdatabase.
 </p>

 <ex type='box'>This page was last modified by <modified by=''
 realname=''/>.</ex>
</attr>

<attr name=date>
    <p>Print the modification date. Takes all the date attributes in <xref href='date.tag' />.</p>

 <ex type='box'>This page was last modified <modified date=''
 case='lower' type='string'/>.</ex>
</attr>

<attr name=file value=path>
 <p>Get information from this file rather than the current page.</p>
</attr>

<attr name=realfile value=path>
 <p>Get information from this file in the computers filesystem rather
 than Roxen Webserver's virtual filesystem.</p>
</attr>",

//----------------------------------------------------------------------

"random":#"<desc cont='cont'><p><short>
 Randomly chooses a message from its contents.</short>
</p></desc>

<attr name='separator' value='string'>
 <p>The separator used to separate the messages, by default newline.</p>

<ex><random separator='#'>
Roxen#Pike#Foo#Bar#roxen.com
</random>
</ex>

<attr name='seed' value='string'>
Enables you to use a seed that determines which message to choose.
</attr>
",

//----------------------------------------------------------------------

"redirect":#"<desc tag='tag'><p><short hide='hide'>
 Redirects the user to another page.</short> Redirects the user to
 another page by sending a HTTP redirect header to the client.
</p></desc>

<attr name=to value=URL required='required'>
 <p>The location to where the client should be sent.</p>
</attr>

<attr name=add value=string>
 <p>The prestate or prestates that should be added, in a comma separated
 list.</p>
</attr>

<attr name=drop value=string>
 <p>The prestate or prestates that should be dropped, in a comma separated
 list.</p>
</attr>

<attr name=text value=string>
 <p>Sends a text string to the browser, that hints from where and why the
 page was redirected. Not all browsers will show this string. Only
 special clients like Telnet uses it.</p>

<p>Arguments prefixed with \"add\" or \"drop\" are treated as prestate
 toggles, which are added or removed, respectively, from the current
 set of prestates in the URL in the redirect header (see also <xref href='apre.tag' />). Note that this only works when the
 to=... URL is absolute, i.e. begins with a \"/\", otherwise these
 state toggles have no effect.</p>
</attr>",

//----------------------------------------------------------------------

"remove-cookie":#"<desc tag='tag'><p><short>
 Sets the expire-time of a cookie to a date that has already occured.
 This forces the browser to remove it.</short>
 This tag won't remove the cookie, only set it to the empty string, or
 what is specified in the value attribute and change
 it's expire-time to a date that already has occured. This is
 unfortunutaly the only way as there is no command in HTTP for
 removing cookies. We have to give a hint to the browser and let it
 remove the cookie.
</p></desc>

<attr name=name>
 <p>Name of the cookie the browser should remove.</p>
</attr>

<attr name=value value=text>
 <p>Even though the cookie has been marked as expired some browsers
 will not remove the cookie until it is shut down. The text provided
 with this attribute will be the cookies intermediate value.</p>

 <p>Note that removing a cookie won't take effect until the next page
load.</p>

</attr>",

//----------------------------------------------------------------------

"replace":#"<desc cont='cont'><p><short>
 Replaces strings in the contents with other strings.</short>
</p></desc>

<attr name=from value=string required='required'>
 <p>String or list of strings that should be replaced.</p>
</attr>

<attr name=to value=string>
 <p>String or list of strings with the replacement strings. Default is the
 empty string.</p>
</attr>

<attr name=separator value=string default=','>
 <p>Defines what string should separate the strings in the from and to
 attributes.</p>
</attr>

<attr name=type value=word|words default=word>
 <p>Word means that a single string should be replaced. Words that from
 and to are lists.</p>
</attr>",

//----------------------------------------------------------------------

"return":#"<desc tag='tag'><p><short>
 Changes the HTTP return code for this page. </short>
 <!-- See the Appendix for a list of HTTP return codes. (We have no appendix) -->
</p></desc>

<attr name=code value=integer>
 <p>The HTTP status code to return.</p>
</attr>

<attr name=text>
 <p>The HTTP status message to set. If you don't provide one, a default
 message is provided for known HTTP status codes, e g \"No such file
 or directory.\" for code 404.</p>
</attr>",

//----------------------------------------------------------------------

"roxen":#"<desc tag='tag'><p><short>
 Returns a nice Roxen logo.</short>
</p></desc>

<attr name=size value=small|medium|large default=medium>
 <p>Defines the size of the image.</p>
<ex type='vert'><roxen size='small'/> <roxen/> <roxen size='large'/></ex>
</attr>

<attr name=color value=black|white default=white>
 <p>Defines the color of the image.</p>
<ex type='vert'><roxen color='black'/></ex>
</attr>

<attr name=alt value=string default='\"Powered by Roxen\"'>
 <p>The image description.</p>
</attr>

<attr name=border value=number default=0>
 <p>The image border.</p>
</attr>

<attr name=class value=string>
 <p>This cascading style sheet (CSS) definition will be applied on the img element.</p>
</attr>

<attr name=target value=string>
 <p>Names a target frame for the link around the image.</p>

 <p>All other attributes will be inherited by the generated img tag.</p>
</attr> ",

//----------------------------------------------------------------------

"scope":#"<desc cont='cont'><p><short>
 Creates a new variable scope.</short> Variable changes inside the scope
 container will not affect variables in the rest of the page.
</p></desc>

<attr name=extend value=name default=form>
 <p>If set, all variables in the selected scope will be copied into
 the new scope. NOTE: if the source scope is \"magic\", as e.g. the
 roxen scope, the scope will not be copied, but rather linked and will
 behave as the original scope. It can be useful to create an alias or
 just for the convinience of refering to the scope as \"_\".</p>
</attr>

<attr name=scope value=name default=form>
 <p>The name of the new scope, besides \"_\".</p>
</attr>",

//----------------------------------------------------------------------

"set":#"<desc tag='tag'><p><short>
 Sets a variable.</short>
</p></desc>

<attr name=variable value=string required='required'>
 <p>The name of the variable.</p>
<ex type='box'>
<set variable='var.foo' value='bar'/>
</ex>
</attr>

<attr name=value value=string>
 <p>The value the variable should have.</p>
</attr>

<attr name=expr value=string>
 <p>An expression whose evaluated value the variable should have.</p>
</attr>

<attr name=from value=string>
 <p>The name of another variable that the value should be copied from.</p>
</attr>

<attr name=split value=string>
 <p>The value will be splitted by this string into an array.</p>

 <p>If none of the above attributes are specified, the variable is unset.
 If debug is currently on, more specific debug information is provided
 if the operation failed. See also: <xref href='append.tag' /> and <xref href='../programming/debug.tag' />.</p>
</attr> ",

//----------------------------------------------------------------------

"copy-scope":#"<desc tag='tag'><p><short>
 Copies the content of one scope into another scope</short></p>

<attr name='from' value='scope name' required='1'>
 <p>The name of the scope the variables are copied from.</p>
</attr>

<attr name='to' value='scope name' required='1'>
 <p>The name of the scope the variables are copied to.</p>
</attr>",

//----------------------------------------------------------------------

"set-cookie":#"<desc tag='tag'><p><short>
 Sets a cookie that will be stored by the user's browser.</short> This
 is a simple and effective way of storing data that is local to the
 user. If no arguments specifying the time the cookie should survive
 is given to the tag, it will live until the end of the current browser
 session. Otherwise, the cookie will be persistent, and the next time
 the user visits  the site, she will bring the cookie with her.
</p></desc>

<attr name=name value=string>
 <p>The name of the cookie.</p>
</attr>

<attr name=seconds value=number>
 <p>Add this number of seconds to the time the cookie is kept.</p>
</attr>

<attr name=minutes value=number>
 <p>Add this number of minutes to the time the cookie is kept.</p>
</attr>

<attr name=hours value=number>
 <p>Add this number of hours to the time the cookie is kept.</p>
</attr>

<attr name=days value=number>
 <p>Add this number of days to the time the cookie is kept.</p>
</attr>

<attr name=weeks value=number>
 <p>Add this number of weeks to the time the cookie is kept.</p>
</attr>

<attr name=months value=number>
 <p>Add this number of months to the time the cookie is kept.</p>
</attr>

<attr name=years value=number>
 <p>Add this number of years to the time the cookie is kept.</p>
</attr>

<attr name=persistent>
 <p>Keep the cookie for five years.</p>
</attr>

<attr name=domain>
 <p>The domain for which the cookie is valid.</p>
</attr>

<attr name=value value=string>
 <p>The value the cookie will be set to.</p>
</attr>

<attr name=path value=string default=\"/\"><p>
 The path in which the cookie should be available. Use path=\"\" to remove
 the path argument from the sent cookie, thus making the cookie valid only
 for the present directory and below.</p>
</attr>

 <p>Note that the change of a cookie will not take effect until the
 next page load.</p>
</attr>",

//----------------------------------------------------------------------

"set-max-cache":#"<desc tag='tag'><p><short>
 Sets the maximum time this document can be cached in any ram
 caches.</short></p>

 <p>Default is to get this time from the other tags in the document
 (as an example, <xref href='../if/if_supports.tag' /> sets the time to
 0 seconds since the result of the test depends on the client used.</p>

 <p>You must do this at the end of the document, since many of the
 normal tags will override this value.</p>
</desc>

<attr name=years value=number>
 <p>Add this number of years to the time this page was last loaded.</p>
</attr>
<attr name=months value=number>
 <p>Add this number of months to the time this page was last loaded.</p>
</attr>
<attr name=weeks value=number>
 <p>Add this number of weeks to the time this page was last loaded.</p>
</attr>
<attr name=days value=number>
 <p>Add this number of days to the time this page was last loaded.</p>
</attr>
<attr name=hours value=number>
 <p>Add this number of hours to the time this page was last loaded.</p>
</attr>
<attr name=beats value=number>
 <p>Add this number of beats to the time this page was last loaded.</p>
</attr>
<attr name=minutes value=number>
 <p>Add this number of minutes to the time this page was last loaded.</p>
</attr>
<attr name=seconds value=number>
 <p>Add this number of seconds to the time this page was last loaded.</p>
</attr>",

//----------------------------------------------------------------------

"smallcaps":#"<desc cont='cont'><p><short>
 Prints the contents in smallcaps.</short> If the size attribute is
 given, font tags will be used, otherwise big and small tags will be
 used.
</p>

<ex>
  <smallcaps>Roxen WebServer</smallcaps>
</ex>


  </desc>

<attr name=space>
 <p>Put a space between every character.</p>
<ex type='vert'>
<smallcaps space=''>Roxen WebServer</smallcaps>
</ex>
</attr>

<attr name=class value=string>
 <p>Apply this cascading style sheet (CSS) style on all elements.</p>
</attr>

<attr name=smallclass value=string>
 <p>Apply this cascading style sheet (CSS) style on all small elements.</p>
</attr>

<attr name=bigclass value=string>
 <p>Apply this cascading style sheet (CSS) style on all big elements.</p>
</attr>

<attr name=size value=number>
 <p>Use font tags, and this number as big size.</p>
</attr>

<attr name=small value=number default=size-1>
 <p>Size of the small tags. Only applies when size is specified.</p>

 <ex>
  <smallcaps size='6' small='2'>Roxen WebServer</smallcaps>
 </ex>
</attr>",

//----------------------------------------------------------------------

"sort":#"<desc cont='cont'><p><short>
 Sorts the contents.</short></p>

 <ex>
  <sort>
   1
   Hello
   3
   World
   Are
   2
   We
   4
   Communicating?
  </sort>
 </ex>
</desc>

<attr name=separator value=string>
 <p>Defines what the strings to be sorted are separated with. The sorted
 string will be separated by the string.</p>

 <ex type='vert'>
  <sort separator='#'>
   1#Hello#3#World#Are#2#We#4#Communicating?
  </sort>
 </ex>
</attr>

<attr name=reverse>
 <p>Reversed order sort.</p>

 <ex>
  <sort reverse=''>
   1
   Hello
   3
   World
   Are
   2
   We
   4
   Communicating?
  </sort>
 </ex>
</attr>",

//----------------------------------------------------------------------

"throw":#"<desc cont='cont'><p><short>
 Throws a text to be caught by <xref href='catch.tag' />.</short>
 Throws an exception, with the enclosed text as the error message.
 This tag has a close relation to <xref href='catch.tag' />. The
 RXML parsing will stop at the <tag>throw</tag> tag.
 </p></desc>",

//----------------------------------------------------------------------

"trimlines":#"<desc cont='cont'><p><short>
 Removes all empty lines from the contents.</short></p>

  <ex>
  <trimlines>


   Are


   We

   Communicating?


  </trimlines>
 </ex>
</desc>",

//----------------------------------------------------------------------

"unset":#"<desc tag='tag'><p><short>
 Unsets a variable, i.e. removes it.</short>
</p></desc>

<attr name=variable value=string required='required'>
 <p>The name of the variable.</p>

 <ex>
  <set variable='var.jump' value='do it'/>
  <ent>var.jump</ent>
  <unset variable='var.jump'/>
  <ent>var.jump</ent>
 </ex>
</attr>",

//----------------------------------------------------------------------

"user":#"<desc tag='tag'><p><short>
 Prints information about the specified user.</short> By default, the
 full name of the user and her e-mail address will be printed, with a
 mailto link and link to the home page of that user.</p>

 <p>The <tag>user</tag> tag requires an authentication module to work.</p>
</desc>

<attr name=email>
 <p>Only print the e-mail address of the user, with no link.</p>
 <ex type='box'>Email: <user name='foo' email=''/></ex>
</attr>

<attr name=link>
 <p>Include links. Only meaningful together with the realname or email attribute.</p>
</attr>

<attr name=name>
 <p>The login name of the user. If no other attributes are specified, the
 user's realname and email including links will be inserted.</p>
<ex type='box'><user name='foo'/></ex>
</attr>

<attr name=nolink>
 <p>Don't include the links.</p>
</attr>

<attr name=nohomepage>
 <p>Don't include homepage links.</p>
</attr>

<attr name=realname>
 <p>Only print the full name of the user, with no link.</p>
<ex type='box'><user name='foo' realname=''/></ex>
</attr>",

//----------------------------------------------------------------------

"if#expr":#"<desc plugin='plugin'><p><short>
 This plugin evaluates expressions.</short> The arithmetic operators
 are \"+, - and /\". The last main operator is \"%\"(per cent). The
 allowed relationship operators are \"&lt;. &gt;, ==, &lt;= and
 &gt;=\".</p>

 <p>All integers(characters 0 to 9) may be used together with
 \".\" to create floating point expressions.</p>

 <ex type='box'>
   Hexadecimal expression: (0xff / 5) + 3
 </ex>
 <p>To be able to evaluate hexadecimal expressions the characters \"a
 to f and A to F\" may be used.</p>

 <ex type='box'>
   Integer conversion: ((int) 3.14)
   Floating point conversion: ((float) 100 / 7)
 </ex>

 <p>Conversion between int and float may be done through the operators
 \"(int)\" and \"(float)\". The operators \"&amp;\"(bitwise and),
 \"|\"((pipe)bitwise or), \"&amp;&amp;\"(logical and) and \"||\"((double
 pipe)logical or) may also be used in expressions. To set
 prioritizations within expressions the characters \"( and )\" are
 included. General prioritization rules are:</p>

 <list type='ol'>
 <item><p>(int), (float)</p></item>
 <item><p>*, /, %</p></item>
 <item><p>+, -</p></item>
 <item><p>&lt;, &gt;, &lt;=, &gt;=\</p></item>
 <item><p>==</p></item>
 <item><p>&amp;, |</p></item>
 <item><p>&amp;&amp;, ||</p></item>
 </list>

 <ex type='box'>
   Octal expression: 045
 </ex>
 <ex type='box'>
   Calculator expression: 3.14e10 / 3
 </ex>
 <p>Expressions containing octal numbers may be used. It is also
 possible to evaluate calculator expressions.</p>

 <p>Expr is an <i>Eval</i> plugin.</p>
</desc>

<attr name='expr' value='expression'>
 <p>Choose what expression to test.</p>
</attr>",

//----------------------------------------------------------------------

"emit#fonts":({ #"<desc plugin='plugin'><p><short>
 Prints available fonts.</short> This plugin makes it easy to list all
 available fonts in Roxen WebServer.
</p></desc>

<attr name='type' value='ttf|all'>
 <p>Which font types to list. ttf means all true type fonts, whereas all
 means all available fonts.</p>
</attr>",
		([
"&_.name;":#"<desc ent='ent'><p>
 Returns a font identification name.</p>

<p>This example will print all available ttf fonts in gtext-style.</p>
<ex type='box'>
 <emit source='fonts' type='ttf'>
   <gtext font='&_.name;'><ent>_.expose</ent></gtext><br />
 </emit>
</ex>
</desc>",
"&_.copyright;":#"<desc ent='ent'><p>
 Font copyright notice. Only available for true type fonts.
</p></desc>",
"&_.expose;":#"<desc ent='ent'><p>
 The preferred list name. Only available for true type fonts.
</p></desc>",
"&_.family;":#"<desc ent='ent'><p>
 The font family name. Only available for true type fonts.
</p></desc>",
"&_.full;":#"<desc ent='ent'><p>
 The full name of the font. Only available for true type fonts.
</p></desc>",
"&_.path;":#"<desc ent='ent'><p>
 The location of the font file.
</p></desc>",
"&_.postscript;":#"<desc ent='ent'><p>
 The fonts postscript identification. Only available for true type fonts.
</p></desc>",
"&_.style;":#"<desc ent='ent'><p>
 Font style type. Only available for true type fonts.
</p></desc>",
"&_.format;":#"<desc ent='ent'><p>
 The format of the font file, e.g. ttf.
</p></desc>",
"&_.version;":#"<desc ent='ent'><p>
 The version of the font. Only available for true type fonts.
</p></desc>",
"&_.trademark;":#"<desc ent='ent'><p>
 Font trademark notice. Only available for true type fonts.
</p></desc>",

//----------------------------------------------------------------------

		])
	     }),
    ]);
#endif
