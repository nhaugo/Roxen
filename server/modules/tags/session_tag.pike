// This is a ChiliMoon module. Copyright � 2001, Roxen IS.
//

#define _error id->misc->defines[" _error"]
//#define _extra_heads id->misc->defines[" _extra_heads"]

#include <module.h>
inherit "module";

constant cvs_version = "$Id: session_tag.pike,v 1.21 2004/05/31 23:01:57 _cvs_stephen Exp $";
constant thread_safe = 1;
constant module_type = MODULE_TAG;
constant module_name = "Tags: Session tag module";
constant module_doc  = #"\
This module provides the session tag which provides a variable scope
where user session data can be stored.";


// --- &client.session; ----------------------------------------

class EntityClientSession {
  inherit RXML.Value;
  mixed rxml_const_eval(RXML.Context c, string var, string scope_name, void|RXML.Type type) {
    c->id->misc->cacheable = 0;
    multiset prestates = filter(c->id->prestate,
				lambda(string in) {
				  return has_prefix(in, "ChiliMoonUserID="); } );

    // If there is both a cookie and a prestate, then we're in the process of
    // deciding session variable vehicle, and should thus return nothing.
    if(c->id->cookies->ChiliMoonUserID && sizeof(prestates))
      return RXML.nil;

    // If there is a UserID cookie, use that as our session identifier.
    if(c->id->cookies->ChiliMoonUserID)
      return ENCODE_RXML_TEXT(c->id->cookies->ChiliMoonUserID, type);

    // If there is a ChiliMoonUserID-prefixed prestate, use the first such
    // prestate as session identifier.
    if(sizeof(prestates)) {
      string session = indices(prestates)[0][12..];
      if(sizeof(session))
	return ENCODE_RXML_TEXT(session, type);
    }

    // Otherwise return nothing.
    return RXML.nil;
  }
}

mapping session_entity = ([ "session":EntityClientSession() ]);

void set_entities(RXML.Context c) {
  c->extend_scope("client", session_entity);
}

void start() {
  query_tag_set()->prepare_context=set_entities;
}


// --- RXML Tags -----------------------------------------------

class TagSession {
  inherit RXML.Tag;
  constant name = "session";
  mapping(string:RXML.Type) req_arg_types = ([ "id" : RXML.t_text(RXML.PEnt) ]);

  class Frame {
    inherit RXML.Frame;
    mapping vars;
    string scope_name;

    array do_enter(RequestID id) {
      NOCACHE();
      vars = cache.get_session_data(args->id) || ([]);
      scope_name = args->scope || "session";
    }

    array do_return(RequestID id) {
      result = content;
      if(!sizeof(vars)) return 0;
      cache.set_session_data(vars, args->id, args->life?(int)args->life+time(1):0,
			     !!args["force-db"] );
    }
  }
}

class TagClearSession {
  inherit RXML.Tag;
  constant name = "clear-session";
  constant flags = RXML.FLAG_EMPTY_ELEMENT;
  mapping(string:RXML.Type) req_arg_types = ([ "id" : RXML.t_text(RXML.PEnt) ]);

  class Frame {
    inherit RXML.Frame;

    array do_enter(RequestID id) {
      NOCACHE();
      cache.clear_session(args->id);
    }
  }
}

class TagForceSessionID {
  inherit RXML.Tag;
  constant name = "force-session-id";
  constant flags = RXML.FLAG_EMPTY_ELEMENT;

  class Frame {
    inherit RXML.Frame;

    array do_enter(RequestID id) {
      int prestate = sizeof(filter(id->prestate,
				   lambda(string in) {
				     return has_prefix(in, "ChiliMoonUserID");
				   } ));

      string path_info = id->misc->path_info || "";

      // If there is no ID cooke nor prestate, redirect to the same page
      // but with a session id prestate set.
      if(!id->cookies->ChiliMoonUserID && !prestate) {
	multiset orig_prestate = id->prestate;
	id->prestate += (< "ChiliMoonUserID=" + core.create_unique_id() >);

	mapping r = Roxen.http_redirect(id->not_query + path_info, id, 0,
					id->real_variables);
	if (r->error)
	  RXML_CONTEXT->set_misc (" _error", r->error);
	if (r->extra_heads)
	  RXML_CONTEXT->extend_scope ("header", r->extra_heads);

	// Don't trust that the user cookie setting is turned on. The effect
	// might be that the ChiliMoonUserID cookie is set twice, but that is
	// not a problem for us.
	id->add_response_header( "Set-Cookie", Roxen.http_roxen_id_cookie() );
	id->prestate = orig_prestate;
	return 0;
      }

      // If there is both an ID cookie and a session prestate, then the
      // user do accept cookies, and there is no need for the session
      // prestate. Redirect back to the page, but without the session
      // prestate. 
      if(id->cookies->ChiliMoonUserID && prestate) {
	multiset orig_prestate = id->prestate;
	id->prestate = filter(id->prestate,
			      lambda(string in) {
				return !has_prefix(in, "ChiliMoonUserID");
			      } );
	mapping r = Roxen.http_redirect(id->not_query + path_info, id, 0,
					id->real_variables);
	id->prestate = orig_prestate;
	if (r->error)
	  RXML_CONTEXT->set_misc (" _error", r->error);
	if (r->extra_heads)
	  RXML_CONTEXT->extend_scope ("header", r->extra_heads);
	return 0;
      }
    }
  }
}


// --- Documentation  ------------------------------------------

TAGDOCUMENTATION;
#ifdef manual
constant tagdoc = ([
  "session":#"<desc type='cont'><p>Creates a session bound scope. The session is
identified by a session key, given as an argument to the session tag.
The session key could be e.g. a value generated by
<ent>core.unique-id</ent> which is then transported by form
variables. An alternative which often is more convenient is to use the
variable client.session (provided by this module) together with the
<tag>force-session-id</tag> tag and the feature to set unique browser
id cookies in the http protocol module (located under the server ports
tab).</p></desc>

<attr name='id' value='string' required='1'><p>The key that identifies
the session. Could e.g. be a name, an IP adress, a cookie or the value
of the special variable client.session provided by this module (see
above).</p></attr>

<attr name='life' value='number' default='900'><p>Determines how many seconds the session is guaranteed to
persist on the server side. Values over 900 means that the session variables will be stored in a
disk based database when they have not been used within 900 seconds.</p></attr>

<attr name='force-db'><p>If used, the session variables will be immediatly written to the database.
Normally, e.g. when not defined, session variables are only moved to the database when they have
not been used for a while (given that they still have \"time to live\", as determined by the life
attribute). This will increase the integrity of the session, since the variables will survive a
server reboot, but it will also decrease performance somewhat.</p></attr>

<attr name='scope' value='name' default='session'><p>The name of the scope that is created inside
the session tag.</p></attr>
",

  // ------------------------------------------------------------


  "clear-session":#"<desc tag='tag'><p>Clear a session from all its content.</p></desc>

<attr name='id' value='string' required='required'>
<p>The key that identifies the session.</p></attr>",

  // ------------------------------------------------------------

  "&client.session;":#"<desc type='entity'>
<p><short>Contains a session key for the user or nothing.</short>
The session key is primary taken from the ChiliMoonUserID cookie. If there is no such cookie it
will return the value in the prestate that begins with \"ChiliMoonUserID=\". However, if both
the cookie and such a prestate exists the client.session variable will be empty. This allows
the client.session variable to be used together with <tag>force-session-id</tag>. Note that
the Session tag module must be loaded for this entity to exist.</p></desc>",

  // ------------------------------------------------------------

  "force-session-id":#"<desc tag='tag'><p>Forces a session id to be set in the variable
client.session. The heuristics is as follows: If the ChiliMoonUserID
cookie is set, use its value. Otherwise redirect to the same page but
with a prestate containing a newly generated session key. If now both
the ChiliMoonUserID cookie and the session prestate is set, redirect back
to the same page without any session prestate set. The ChiliMoonUserID
cookie should be set automatically by the HTTP protocol module. Look
at the option to enable unique browser id cookies under the server
ports tab.</p>

<ex-box><force-session-id/>
<if variable='client.session'>
  <!-- RXML code that uses &client.session;, e.g. as follows: -->
  <session id='&client.session;'>
    ...
  </session>
</if>
</ex-box></desc>",

]);
#endif
