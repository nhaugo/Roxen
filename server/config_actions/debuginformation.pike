/*
 * $Id: debuginformation.pike,v 1.17 1999/12/27 12:38:20 mast Exp $
 */

inherit "wizard";
inherit "configlocale";

constant name_svenska = "Utveckling//Avlusningsinformation f�r utvecklare";
constant name = "Development//Development information for developers";

constant doc_svenska = (#"Visa lite information om roxens interna
 strukturer, kan vara anv�ndbart f�r folk som utvecklar roxenmoduler");
constant doc = ("Show some internals of Roxen, useful for debugging "
		"code.");

constant more=1;

mapping last_usage;

constant colors = ({ "#f0f0ff", "white" });

constant ok_label = " Refresh ";
constant cancel_label = " Done ";

constant ok_label_svenska = " Uppdatera ";
constant cancel_label_svenska = " Klar ";

#if efun(get_profiling_info)
string remove_cwd(string from)
{
  return from-(getcwd()+"/");
}

array (program) all_modules()
{
  return values(master()->programs) | indices(roxen->my_loaded);
}

string program_name(program|object what)
{
  string p;
  if(roxen->filename(what)) return remove_cwd(roxen->filename(what));
}

mapping get_prof(string|void foo)
{
  mapping res = ([]);
  foreach(all_modules(), program prog)
    res[program_name(prog)] = get_profiling_info( prog );
  return res;
}

array get_prof_info(string|void foo)
{
  array res = ({});
  // result: "object.function\ttotal_time\tcalled_times\n..."
  mapping as_functions = ([]);
  mapping tmp = get_prof();
  foreach(indices(tmp), string c)
  {
    mapping g = tmp[c][1];
    foreach(indices(g), string f) 
      if(!foo || !sizeof(foo) || glob(foo,c+"->"+f))
	as_functions[c+"->"+f] = ({ g[f][1],g[f][0] });
  }
  array q = indices(as_functions);
  sort(values(as_functions), q);
  foreach(reverse(q), string i) if(as_functions[i][0])
    res += ({({i,sprintf("%1.2f",
			 as_functions[i][0]/1000000.0),
	       sprintf("%d",as_functions[i][1]),
	       sprintf("%1.6f",
		       (as_functions[i][0]/1000000.0)/as_functions[i][1])})});
  return res;
}

#if !constant(ADT.Table)
string mktable(array titles, array data)
{
  string fmt = "";
  array head = ({});
  foreach(titles, mixed w)
    if(intp(w)) 
      fmt += "%"+w+"s ";
    else
      head += ({ w });
  data = copy_value(data);
  for(int i=0;i<sizeof(data);i++) data[i] = sprintf(fmt, @data[i]);
  return "<pre><b>"+sprintf(fmt, @head)+"</b>\n"+
    (data*"\n")+"</pre>";
}
#endif

mixed page_1(object id, object mc)
{
  string res = ("<font size=+1>Profiling information</font><br>"
		"All times are in seconds, and real-time. Times incude"
		" time of child functions. No callgraph is available yet.<br>"
		"Function glob: <var type=string name=subnode><br>");

#if constant(ADT.Table)
  object t = ADT.Table->table(get_prof_info("*"+(id->variables->subnode||"")+"*"),
			      ({ "Function", "Time", "Calls",
				 "Time/Call"}));
  return res + "\n\n<pre>"+ADT.Table.ASCII.encode( t )+"</pre>";
#else
  return res+mktable(({"Function",-70,"Time",7,"Calls",6,"Time/Call",10}),
		     get_prof_info(id->variables->subnode));
#endif
}
#endif


int wizard_done()
{ 
  return -1;
}

mixed page_0(object id, object mc)
{

  if(!last_usage) last_usage = roxen->query_var("__memory_usage");
  if(!last_usage) last_usage = ([]); 

  string res="";
  string first="";
  mixed foo = _memory_usage();
  foo->total_usage = 0;
  foo->num_total = 0;
  array ind = sort(indices(foo));
  string f;
  res+=("<table cellpadding=0 cellspacing=0 border=0>"
	"<tr valign=top><td valign=top>");
  res+=("<table border=0 cellspacing=0 cellpadding=2>"
	"<tr bgcolor=lightblue><td>&nbsp;</td>"
	"<th colspan=2><b>number of</b></th></tr>"
	"<tr bgcolor=lightblue><th align=left>Entry</th><th align"
	"=right>Current</th><th align=right>Change</th></tr>");
  foreach(ind, f)
    if(!search(f, "num_"))
    {
      string bg="white";
      if(f!="num_total")
	foo->num_total += foo[f];
      else
	bg="lightblue";
      string col="darkred";
      if((foo[f]-last_usage[f]) < foo[f]/60)
	col="brown";
      if((foo[f]-last_usage[f]) == 0)
	col="black";
      if((foo[f]-last_usage[f]) < 0)
	col="darkgreen";
      
      res += "<tr bgcolor="+bg+"><td><b><font color="+col+">"+f[4..]+"</font></b></td><td align=right><b><font color="+col+">"+
	(foo[f])+"</font></b></td><td align=right><b><font color="+col+">"+
	((foo[f]-last_usage[f]))+"</font></b><br></td>";
    }
  res+="</table></td><td>";

  res+=("<table border=0 cellspacing=0 cellpadding=2>"
	"<tr bgcolor=lightblue><th colspan=2><b>memory usage</b></th></tr>"
	"<tr bgcolor=lightblue><th align=right>Current (KB)</th><th align=right>"
	"Change (KB)</th></tr>");

  foreach(ind, f)
    if(search(f, "num_"))
    {
      string bg="white";
      if((f!="total_usage"))
	foo->total_usage += foo[f];
      else
	bg="lightblue";
      string col="darkred";
      if((foo[f]-last_usage[f]) < foo[f]/60)
	col="brown";
      if((foo[f]-last_usage[f]) == 0)
	col="black";
      if((foo[f]-last_usage[f]) < 0)
	col="darkgreen";
      res += sprintf("<tr bgcolor="+bg+"><td align=right><b><font "
		     "color="+col+">%.1f</font></b></td><td align=right>"
		     "<b><font color="+col+">%.1f</font></b><br></td>",
		     (foo[f]/1024.0),((foo[f]-last_usage[f])/1024.0));
    }
  last_usage=foo;
  roxen->set_var("__memory_usage", last_usage);
  res+="</table></td></tr></table>";
  first = html_border( res, 0, 5 );
  res = "";

#if efun(_dump_obj_table)
  first += "<p><br><p>";
  res += ("<table  border=0 cellspacing=0 ceellpadding=2 width=50%>"
	  "<tr align=left bgcolor=lightblue><th  colspan=2>List of all "
	  "programs with more than two clones:</th></tr>"
	  "<tr align=left bgcolor=lightblue>"
	  "<th>Program name</th><th align=right>Clones</th></tr>");
  foo = _dump_obj_table();
  mapping allobj = ([]);
  string a = getcwd(), s;
  if(a[-1] != '/')
    a += "/";
  int i;
  for(i = 0; i < sizeof(foo); i++) {
    string s = foo[i][0];
    if(!stringp(s))
      continue;
    if(search(s,"base_server/mainconfig.pike")!=-1) s="ConfigNode";
    if(search(s,"base_server/configuration.pike")!=-1) s="Bignum";
    if(sscanf(s,"/precompiled/%s",s)) s=capitalize(s);
    allobj[s]++;
  }
  foreach(Array.sort_array(indices(allobj),lambda(string a, string b, mapping allobj) {
    return allobj[a] < allobj[b];
  }, allobj), s) {
    if((search(s, "Destructed?") == -1) && allobj[s]>2)
    {
      res += sprintf("<tr bgcolor=#f0f0ff><td><b>%s</b></td>"
		     "<td align=right><b>%d</b></td></tr>\n",
		     s - a, allobj[s]);
    }
  }
  res += "</table>";
  first += html_border( res, 0, 5 );
  res = "";
#endif
#if efun(_num_objects)
  first += ("Number of destructed objects: " + _num_dest_objects() +"<br>\n");
#endif  
  return first +"</ul>";
}

mixed handle(object id) { return wizard_for(id,0); }
