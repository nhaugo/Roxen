#include <config_interface.h>
#include <config.h>
#include <roxen.h>
//<locale-token project="roxen_config">_</locale-token>
#define _(X,Y)	_STR_LOCALE("roxen_config",X,Y)

mapping images = ([]);
int image_id = time() ^ gethrtime();

string is_image( string x )
{
  if( !search( x, "GIF" ) )
    return "gif";
  if( has_value( x, "JFIF" ) )
    return "jpeg";
  if( !search( x, "\x89PNG" ) )
    return "png";
}


int is_encode_value( string what )
{
  return !search( what, "�ke0" );
}

string format_decode_value( string what )
{
  string trim_comments( string what ) /* Needs work */
  {
    string a, b;
    while( sscanf( what, "%s/*%*s*/%s", a, b ) )
      what = a+b;
    return what;
  };

  catch
  {
    mixed q = decode_value( what );
    if( objectp( q ) || programp( q ) )
      return Roxen.http_encode_string("<"+_(233,"bytecode data")+">");
    return trim_comments( sprintf("%O", q ) );
  };
  return what;
}

string store_image( string x )
{
  string id = (string)image_id++;

  images[ id ] = ([
    "type":"image/"+(is_image( x )||"unknown"),
    "data":x,
    "len":strlen(x),
  ]);
  
  return id;
}

mapping|string parse( RequestID id )
{
  if( id->variables->image )
  {
    return m_delete( images, id->variables->image );
  }
  Sql.Sql db = DBManager.get( id->variables->db );
  string url = DBManager.db_url( id->variables->db );
  string res =
    "<use file='/template'/><tmpl>"
    "<topmenu base='../' selected='dbs'/>"
    "<content><cv-split><subtablist width='100%'><st-tabs>"
    "<!--<insert file='subtabs.pike'/>--></st-tabs><st-page>"
    "<input type=hidden name='db' value='&form.db:http;' />\n";

  if( id->variables->table )
    res += "<input type=hidden name='table' value='&form.table:http;' />\n";

  res +=
    "<br />"
    "<table cellspacing=0 cellpadding=0 border=0 width=100% bgcolor='&usr.titlebg;'><tr><td>"
    "<colorscope bgcolor='&usr.titlebg;' text='&usr.titlefg;'>"
    "<cimg border='0' format='gif' src='&usr.database-small;' alt='' "
    "max-height='20'/></td><td>"
    "<gtext fontsize='20'>"+id->variables->db+
    "</gtext></colorscope></td></tr>"
    "<tr><td></td><td>";
  
  if( !url )
    res += "<b>Internal database</b>";
  else
    res += "<b>"+url+"</b>";

  res += "</td></tr><tr><td></td><td>";

  res += "<table>";

  array table_data = ({});
  int sort_ok;
  array sel_t_columns = ({});
  string deep_table_info( string table )
  {
    string res = "<tr><td></td><td colspan='3'><table>";
    array data = db->query( "describe "+table );
    foreach( data, mapping r )
    {
      if( search( lower_case(r->Type), "blob" ) == -1 )
	sel_t_columns += ({ r->Field });
      res += "<tr>\n";
      res += "<td><font size=-1><b>"+r->Field+"</b></font></td>\n";
      res += "<td><font size=-1>"+r->Type+"</font></td>\n";
      res += "<td><font size=-1>"+(strlen(r->Key)?_(373,"Key"):"")+"</font></td>\n";
      res += "<td><font size=-1>"+r->Extra+"</font></td>\n";
      res += "</tr>\n";
    }
    return res+ "</table></td></tr>";
  };

  void add_table_info( string table, mapping tbi )
  {
    string res ="";
    res += "<tr>\n";
    res += "<td> <cimg src='&usr.table-small;' max-height='12'/> </td>\n";
    res += "<td> <a href='browser.pike?db=&form.db:http;&table="+
      Roxen.http_encode_string(table)+"'>"+table+"</a> </td>";

    
    if( tbi )
    {
      res += "<td align=right> <font size=-1>"+
	tbi->Rows+" "+_(374,"rows")+"</font></td><td align=right><font size=-1>"+
	( (int)tbi->Data_length+(int)tbi->Index_length)/1024+_(375,"KiB")+
	"</font></td>";
    }
    res += "</tr>\n";
    if( tbi )
      sort_ok = 1;
    table_data += ({({ table,
		     (tbi ?(int)tbi->Data_length+ (int)tbi->Index_length:0),
		     (tbi ?(int)tbi->Rows:0),
		     res+
		       ( id->variables->table == table ?
			 deep_table_info( table ) : "")
		  })});
  };

  if( catch
  {
    array(mapping) tables = db->query( "show table status" );
    
    foreach( tables, mapping tb )
      add_table_info( tb->Name, tb );
  } )
  {
    if( catch
    {
      object _tables = db->big_query( "show tables" );
      array tables = ({});
      while( array q = _tables->fetch_row() )
	tables += q;
      foreach( tables, string tb )
	add_table_info( tb, 0 );
    } )
      ;
  }

  switch( id->variables->sort )
  {
    default:
      sort( column( table_data, 0 ), table_data );
      break;
    case "rows":
      sort( column( table_data, 2 ), table_data );
      table_data = reverse( table_data );
      break;
    case "size":
      sort( column( table_data, 1 ), table_data );
      table_data = reverse( table_data );
      break;
  }
#define SEL(X,Y) ((id->variables->sort==X||(Y&&!id->variables->sort))?"<img src='&usr.selected-indicator;' border=0 alt='&gt;' />":"")

  if( sort_ok )
  {
    res +=
      "<tr><td align=right>"+SEL("name",1)+"</td>"
      "<td><b><a href='browser.pike?db=&form.db:http;&sort=name'>"+
      _(376,"Name")+
      "</a></b></td>\n"
      "<td align=right><b><a href='browser.pike?db=&form.db:http;&sort=rows'>"+
      SEL("rows",0)+String.capitalize(_(374,"rows"))+
      "</a></b></td>\n"
      "<td align=right><b><a href='browser.pike?db=&form.db:http;&sort=size'>"+
      SEL("size",0)+_(377,"Size")+
      "</a></b></td>\n"
      "</tr>";
  }
  res += column( table_data, 3 )*"\n";

  res += "</table></td></tr></table>";

  if( !id->variables->query || id->variables["clear_q.x"] )
    if( id->variables->table )
      id->variables->query = "SELECT "+(sel_t_columns*", ")+" FROM "+id->variables->table;
    else
      id->variables->query = "SHOW TABLES";

  res +=
    "<table><tr><td valign=top><font size=-1>"
    "<textarea rows=8 cols=50 wrap=soft name='query'>&form.query:html;</textarea>"
    "</font></td><td valign=top>"
    "<submit-gbutton2 name=clear_q> "+_(378,"Clear query")+" </submit-gbutton2>"
    "<br />"
    "<submit-gbutton2 name=run_q> "+_(379,"Run query")+" </submit-gbutton2>"
    "<br /></td></tr></table>";

  if( id->variables["run_q.x"] )
  {
    string query = "";
    // 1: Normalize.
    foreach( replace((id->variables->query-"\r"),"\t"," ")/"\n", string q )
    {
      q = (q/" "-({""}))*" ";
      if( strlen(q) && (q[0] == ' ') )  q = q[1..];
      if( strlen(q) && (q[-1] == ' ') ) q = q[..strlen(q)-2];
      query +=  q + "\n";
    }
    foreach( (query/";\n")-({""}), string q )
    {
      res += "<table celpadding=2><tr>";
      mixed e = catch {
	multiset right_columns = (<>);
	object big_q = db->big_query( q );
	int column;
	if( big_q )
	{
	  foreach( big_q->fetch_fields(), mapping field )
	  {
	    switch( field->type  )
	    {
	      case "long":
	      case "int":
	      case "short":
		right_columns[column]=1;
		res += "<td align=right>";
		break;
	      default:
		res += "<td>";
	    }
	    res += "<b><font size=-1>"+field->name+
	      "</font size=-1></b></td>\n";
	    column++;
	  }
	  res += "</tr>";
      
	  while( array q = big_q->fetch_row() )
	  {
	    res += "<tr>";
	    for( int i = 0; i<sizeof(q); i++ )
	      if( /* image_columns[i] ||*/ is_image( q[i] ) )
		res +=
		  "<td><img src='browser.pike?image="+store_image( q[i] )+
		  "' /></td>";
	      else if( is_encode_value( q[i] ) )
		res +=
		  "<td>"+format_decode_value(q[i]) +"</td>";
	      else if( right_columns[i] )
		res += "<td align=right>"+ Roxen.html_encode_string(q[i]) +
		  "</td>";
	      else
		res += "<td>"+ Roxen.html_encode_string(q[i]) +"</td>";
	  }
	}
      };
      if( e )
	res += "<tr><td> <font color='&usr.warncolor;'>"+
	  sprintf((string)_(380,"While running %s: %s"), q,describe_error(e) )+
	  "</td></tr>\n";
      res += "</table>";
    }
  }
  
  // TODO: actions:
  //    move
  //    rename ( !(local || shared) )
  //    delete ( !(local || shared) )
  //    clear
      return res+"</st-page></subtablist></cv-split></content></tmpl>";
}
