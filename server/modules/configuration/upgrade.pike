/*
 * $Id: upgrade.pike,v 1.9 2000/02/11 18:33:40 js Exp $
 *
 * The Roxen Upgrade Client
 *
 * Johan Sch�n, Peter Bortas
 * January-February 2000
 */

inherit "module";
inherit "html";
inherit "roxenlib";
#include <roxen.h>
#include <module.h>
#include <stat.h>
#include <config_interface.h>

constant module_type = MODULE_PARSER|MODULE_CONFIG;
constant module_name = "Upgrade client";

object db;

object updater;

void start(int num, Configuration conf)
{
  conf->parse_html_compat=1;
  if(!num)
  {
    catch(db=Yabu.db(QUERY(yabudir),"wcS"));
    updater=UpdateInfoFiles();
  }
}

void stop()
{
  catch(db->close());
  catch(destruct(updater));
}

void create()
{
  query_tag_set()->prepare_context=set_entities;
  defvar("yabudir", "../upgrade_data", "Database directory",
	 TYPE_DIR, ""); /* Keep this in server and regenerate on upgrade */
  defvar("server", "community.roxen.com", "Server host",
	 TYPE_STRING, "");
  defvar("port", 80, "Server port",
	 TYPE_INT, "");
}

class Scope_upgrade
{
  inherit RXML.Scope;

  mixed `[]  (string var, void|RXML.Context c, void|string scope)
  {
    object id = c->id;
    return "foo";
  }

  string _sprintf() { return "RXML.Scope(upgrade)"; }
}

RXML.Scope upgrade_scope=Scope_upgrade();

void set_entities(RXML.Context c)
{
  c->extend_scope("upgrade", upgrade_scope);
}

array(mapping) menu = ({
  ([ "Main":"" ]),
  ([ "Security":"security.html" ]),
  ([ "Bugfixes":"bugfixes.html" ]),
  ([ "Idonex":"idonex.html" ]),
  ([ "3rd part":"3rdpart.html" ]),
});

string tag_upgrade_sidemenu(string t, mapping m, RequestID id)
{
  string ret =
    "<gbutton width=150 bgcolor=&usr.fade1;>Update List</gbutton><br><br>";
  
  foreach(menu, mapping entry)
  {
    ret += "<gbutton width=150 bgcolor=&usr.fade1; ";
    if(m->this && lower_case(m->this)==lower_case(indices(entry)[0]))
      ret += " icon_src=&usr.selected-indicator; ";
    ret += "icon_align=left preparse href='"
      + values(entry)[0] +"'>"+ indices(entry)[0] +"</gbutton><br>";
  }
 
  return ret;
}

string container_packet_list(string t, mapping m, string c, RequestID id)
{
  // limit
  for
  return "";
}

string encode_ranges(array(int) a)
{
  a=sort(a);
  string s="";
  int last;
  if(!sizeof(a))
    return "";
  for(int i=0;i<sizeof(a);i++)
  {
    if(i==0)
    {
      s+=(string)a[i];
      last=a[i];
      continue;
    }
    
    if(a[i]==last+1)
    {
      last=a[i];
      if(s[-1]!='-')
	s+="-";
      continue;
    }
    
    if(s[-1]=='-')
      s+=(string)last;

    s+=", "+(string)a[i];
    last=a[i];
  }
  if(s[-1]=='-')
    s+=(string)last;
  return s;
}

array(int) decode_ranges(string s)
{
  array a=({ });
  int start,stop;
  foreach( ((s-" ")/",")-({""}), string r)
    if(sscanf(r,"%d-%d",start,stop)==2 && stop>start && (stop-start)< 1<<16 )
      for(int i=start; i<=stop; i++)
	a+=({ i });
    else
      a+=({ (int)r });
  return sort(a);
}

mapping get_headers()
{
  return ([ "host":QUERY(server)+":"+QUERY(port),
	    "user-agent": "Roxen�WebServer/1.4.143", // FIXME
	    "authorization": "Basic "+MIME.encode_base64("js:klorgas"), // FIXME
  ]);
}



class GetInfoFile
{
  inherit Protocols.HTTP.Query;

  string get_containers(string t, mapping m, string c, mapping res)
  {
    werror("t: %O   c: %O\n",res,c);
    if(sizeof(t) && t[0]!='/')
      res[t]=c;
  }
  
  void request_ok(object httpquery, int num)
  {
    spider;
    mapping res=([]);
    
    if(httpquery->status!=200)
    {
      report_error("Upgrade: Wrong answer from server.\n");
      return;
    }

    parse_html_lines(httpquery->data(),
		     ([]),
		     (["id" : get_containers, 
		       "title": get_containers, 
		       "description": get_containers, 
		       "organization": get_containers, 
		       "license": get_containers, 
		       "author_email": get_containers, 
		       "author_name": get_containers, 
		       "package-type": get_containers, 
		       "issued-date": get_containers, 
		       "roxen-low": get_containers, 
		       "roxen-high": get_containers, 
		       "crypto": get_containers ]),		     
		     res);
    res->size=httpquery->headers->size;
    werror("%O\n",httpquery->data());
//     db["pkginfo"][(string)num]=res;
    db["pkginfo"]->sync();
    report_notice("Upgrade: Added information about package number "
		  +num+".\n");
  }

  void request_fail(object httpquery, int num)
  {
    report_error("Upgrade: Failed to connect to upgrade server to fetch "
		 "information about package number "+num+".\n");
  }

  void create(int pkgnum)
  {
    set_callbacks(request_ok, request_fail, pkgnum);
    async_request(QUERY(server),QUERY(port),
		  "GET /upgradeserver/packages/"+pkgnum+".info HTTP/1.0",
		  get_headers());
  }
}


class UpdateInfoFiles
{
  inherit Protocols.HTTP.Query;

  void request_ok(object httpquery)
  {
    string s=httpquery->data();
    
    array lines=s/"\n";
    if(httpquery->status!=200 || lines[0]!="upgrade" || sizeof(lines)<3)
    {
      report_error("Upgrade: Wrong answer from server.\n");
      return;
    }

    array(int) new_packages=decode_ranges(lines[1]);
    array(int) delete_packages=decode_ranges(lines[2]);

    if(sizeof(new_packages))
      report_notice("Upgrade: Found new packages: "+
		    ((array(string))new_packages)*", "+"\n");
    else
      report_notice("Upgrade: No new packages found.\n");

    if(sizeof(delete_packages))
      report_notice("Upgrade: Deleting packages: "+
		    ((array(string))delete_packages)*", "+
		    "\n");
    else
      report_notice("Upgrade: No packages to delete found.\n");

    foreach(new_packages, int i)
      GetInfoFile(i);

    foreach(delete_packages, int i)
      catch(db["pkginfo"]->delete((string)i));
      
  }

  void request_fail(object httpquery)
  {
    report_error("Upgrade: Failed to connect to upgrade server to fetch "
		 "information about new packages.\n");
  }

  void do_request()
  {
    werror("foo: %O\n",encode_ranges((array(int))indices(db["pkginfo"])));
    async_request(QUERY(server),QUERY(port),
		  "POST /upgradeserver/get_packages HTTP/1.0",
		  get_headers() |
		  (["content-type":"application/x-www-form-urlencoded"]),
		  "roxen_version=2.0001&"+
		  "have_packages="+
		  encode_ranges((array(int))indices(db["pkginfo"])));
    call_out(do_request, 12*3600);
  }

  void destroy()
  {
    remove_call_out(do_request);
  }
  
  void create()
  {
    set_callbacks(request_ok, request_fail);
    call_out(do_request,1);
  }
}
