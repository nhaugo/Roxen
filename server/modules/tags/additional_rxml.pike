// This is a roxen module. Copyright � 2000 - 2001, Roxen IS.
//

#include <module.h>
inherit "module";

constant cvs_version = "$Id: additional_rxml.pike,v 1.29 2004/05/31 02:43:31 _cvs_stephen Exp $";
constant thread_safe = 1;
constant module_type = MODULE_TAG;
constant module_name = "Tags: Additional RXML tags";
constant module_doc  = "This module provides some more complex and not as widely used RXML tags.";

class TagDice {
  inherit RXML.Tag;
  constant name = "dice";
  constant flags = RXML.FLAG_EMPTY_ELEMENT;

  class Frame {
    inherit RXML.Frame;

    string do_return(RequestID id) {
      NOCACHE();
      if(!args->type) args->type="D6";
      args->type = replace( args->type, "T", "D" );
      int value;
      args->type=replace(args->type, "-", "+-");
      foreach(args->type/"+", string dice) {
	if(has_value(dice, "D")) {
	  if(dice[0]=='D')
	    value+=random((int)dice[1..])+1;
	  else {
	    array(int) x=(array(int))(dice/"D");
	    if(sizeof(x)!=2)
	      RXML.parse_error("Malformed dice type.\n");
	    value+=x[0]*(random(x[1])+1);
	  }
	}
	else
	  value+=(int)dice;
      }

      if(args->variable)
	RXML.user_set_var(args->variable, value, args->scope);
      else
	result=(string)value;

      return 0;
    }
  }
}

class TagEmitKnownLangs
{
  inherit RXML.Tag;
  constant name = "emit", plugin_name = "known-langs";
  array get_dataset(mapping m, RequestID id)
  {
    return map(get_core()->list_languages(),
	       lambda(string id)
	       {
		 object language = roxenp()->language_low(id);
		 string eng_name = language->id()[1];
		 if(eng_name == "standard")
		   eng_name = "english";
		 return ([ "id" : id,
			 "name" : language->id()[2],
		  "englishname" : eng_name ]);
	       });
  }
}

class TagInsertLocate {
  inherit RXML.Tag;
  constant name= "insert";
  constant plugin_name = "locate";

  RXML.Type get_type( mapping args )
  {
    if (args->quote=="html")
      return RXML.t_text;
    return RXML.t_xml;
  }

  string get_data(string var, mapping args, RequestID id)
  {
    array(string) result;
    
    result = VFS.find_above_read( id->not_query, var, id );

    if( !result )
      RXML.run_error("Cannot locate any file named "+var+".\n");

    return result[1];
  }  
}

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

class TagRecode
{
  inherit RXML.Tag;
  constant name="recode";
  mapping(string:RXML.Type) opt_arg_types = ([
    "from" : RXML.t_text(RXML.PEnt),
    "to"   : RXML.t_text(RXML.PEnt),
  ]);

  class Frame
  {
    inherit RXML.Frame;
    array do_return( RequestID id )
    {
      if( !content ) content = "";

      if( args->from && catch {
	content=Locale.Charset.decoder( args->from )->feed( content )->drain();
      })
	RXML.run_error("Illegal charset, or unable to decode data: %s\n",
		       args->from );
      if( args->to && catch {
	content=Locale.Charset.encoder( args->to )->feed( content )->drain();
      })
	RXML.run_error("Illegal charset, or unable to encode data: %s\n",
		       args->to );
      return ({ content });
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
      if(has_value(s, "<br />\n<br />\n")) s=p+s;
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
    if(has_value(s, "\n\n")) s=p+s;
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

  string _sprintf(int t) {
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
    index = array_sscanf(Crypto.SHA1.hash(m->seed), "%4c")[0]%sizeof(q);
  else
    index = random(sizeof(q));

  return q[index];
}

class TagIfDate {
  inherit RXML.Tag;
  constant name = "if";
  constant plugin_name = "date";

  int eval(string date, RequestID id, mapping m) {
    CACHE(60); // One minute accuracy is probably good enough...
    int a, b;
    mapping t = ([]);

    date = replace(date, "-", "");
    if(sizeof(date)!=8 && sizeof(date)!=6)
      RXML.run_error("If date attribute doesn't conform to YYYYMMDD syntax.");
    if(sscanf(date, "%04d%02d%02d", t->year, t->mon, t->mday)==3)
      t->year-=1900;
    else if(sscanf(date, "%02d%02d%02d", t->year, t->mon, t->mday)!=3)
      RXML.run_error("If date attribute doesn't conform to YYYYMMDD syntax.");

    if(t->year>70) {
      t->mon--;
      a = mktime(t);
    }

    t = localtime(time(1));
    b = mktime(t - (["hour": 1, "min": 1, "sec": 1, "isdst": 1, "timezone": 1]));

    // Catch funny guys
    if(m->before && m->after) {
      if(!m->inclusive)
	return 0;
      m_delete(m, "before");
      m_delete(m, "after");
    }

    if( (m->inclusive || !(m->before || m->after)) && a==b)
      return 1;

    if(m->before && a>b)
      return 1;

    if(m->after && a<b)
      return 1;

    return 0;
  }
}

class TagIfTime {
  inherit RXML.Tag;
  constant name = "if";
  constant plugin_name = "time";

  int eval(string ti, RequestID id, mapping m) {
    CACHE(time(1)%60); // minute resolution...

    int|object a, b, d;
    
    if(sizeof(ti) <= 5 /* Format is hhmm or hh:mm. */)
    {
	    mapping c = localtime(time(1));
	    
	    b=(int)sprintf("%02d%02d", c->hour, c->min);
	    a=(int)replace(ti,":","");

	    if(m->until)
		    d = (int)m->until;
		    
    }
    else /* Format is ISO8601 yyyy-mm-dd or yyyy-mm-ddThh:mm etc. */
    {
	    if(has_value(ti, "T"))
	    {
		    /* The Calendar module can for some reason not
		     * handle the ISO8601 standard "T" extension. */
		    a = Calendar.ISO.dwim_time(replace(ti, "T", " "))->minute();
		    b = Calendar.ISO.Minute();
	    }
	    else
	    {
		    a = Calendar.ISO.dwim_day(ti);
		    b = Calendar.ISO.Day();
	    }

	    if(m->until)
		    if(has_value(m->until, "T"))
			    /* The Calendar module can for some reason not
			     * handle the ISO8601 standard "T" extension. */
			    d = Calendar.ISO.dwim_time(replace(m->until, "T", " "))->minute();
		    else
			    d = Calendar.ISO.dwim_day(m->until);
    }
    
    if(d)
    {
      if (d > a && (b > a && b < d) )
	return 1;
      if (d < a && (b > a || b < d) )
	return 1;
      if (m->inclusive && ( b==a || b==d ) )
	return 1;
      return 0;
    }
    else if( (m->inclusive || !(m->before || m->after)) && a==b )
      return 1;
    if(m->before && a>b)
      return 1;
    else if(m->after && a<b)
      return 1;
  }
}

class TagIfUser {
  inherit RXML.Tag;
  constant name = "if";
  constant plugin_name = "user";

  int eval(string u, RequestID id, mapping m)
  {
    object db;
    if( m->database )
      db = id->conf->find_user_database( m->database );
    User uid = id->conf->authenticate( id, db );

    if( !uid && !id->auth )
      return 0;

    NOCACHE();

    if( u == "any" )
      if( m->file )
	// Note: This uses the compatibility interface. Should probably
	// be fixed.
	return match_user( id->auth, id->auth[1], m->file, !!m->wwwfile, id);
      else
	return !!u;
    else
      if(m->file)
	// Note: This uses the compatibility interface. Should probably
	// be fixed.
	return match_user(id->auth,u,m->file,!!m->wwwfile,id);
      else
	return has_value(u/",", uid->name());
  }

  private int match_user(array u, string user, string f, int wwwfile, RequestID id) {
    string s, pass;
    if(u[1]!=user)
      return 0;
    if(!wwwfile)
      s=Stdio.read_bytes(f);
    else
      s=id->conf->try_get_file(Roxen.fix_relative(f,id), id);
    return ((pass=simple_parse_users_file(s, u[1])) &&
	    (u[0] || match_passwd(u[2], pass)));
  }

  private int match_passwd(string try, string org) {
    if(!strlen(org)) return 1;
    if(crypt(try, org)) return 1;
  }

  private string simple_parse_users_file(string file, string u) {
    if(!file) return 0;
    foreach(file/"\n", string line)
      {
	array(string) arr = line/":";
	if (arr[0] == u && sizeof(arr) > 1)
	  return(arr[1]);
      }
  }
}

class TagIfGroup {
  inherit RXML.Tag;
  constant name = "if";
  constant plugin_name = "group";

  int eval(string u, RequestID id, mapping m) {
    object db;
    if( m->database )
      db = id->conf->find_user_database( m->database );
    User uid = id->conf->authenticate( id, db );

    if( !uid && !id->auth )
      return 0;

    NOCACHE();
    if( m->groupfile )
      return ((m->groupfile && sizeof(m->groupfile))
	      && group_member(id->auth, u, m->groupfile, id));
    return sizeof( uid->groups() & (u/"," )) > 0;
  }

  private int group_member(array auth, string group, string groupfile, RequestID id) {
    if(!auth)
      return 0; // No auth sent

    string s;
    catch { s = Stdio.read_bytes(groupfile); };

    if (!s)
      s = id->conf->try_get_file( Roxen.fix_relative( groupfile, id), id );

    if (!s) return 0;

    s = replace(s,({" ","\t","\r" }), ({"","","" }));

    multiset(string) members = simple_parse_group_file(s, group);
    return members[auth[1]];
  }

  private multiset simple_parse_group_file(string file, string g) {
    multiset res = (<>);
    array(string) arr ;
    foreach(file/"\n", string line)
      if(sizeof(arr = line/":")>1 && (arr[0] == g))
	res += (< @arr[-1]/"," >);
    return res;
  }
}

TAGDOCUMENTATION;
#ifdef manual
constant tagdoc=([
  "dice":#"<desc type='cont'><p><short>
 Simulates a D&amp;D style dice algorithm.</short></p></desc>

<attr name='type' value='string' default='D6'><p>
 Describes the dices. A six sided dice is called 'D6' or '1D6', while
 two eight sided dices is called '2D8' or 'D8+D8'. Constants may also
 be used, so that a random number between 10 and 20 could be written
 as 'D9+10' (excluding 10 and 20, including 10 and 20 would be 'D11+9').
 The character 'T' may be used instead of 'D'.</p>
</attr>",

//----------------------------------------------------------------------

"smallcaps":#"<desc type='cont'><p><short>
 Prints the contents in smallcaps.</short> If the size attribute is
 given, font tags will be used, otherwise big and small tags will be
 used.</p>

<ex><smallcaps>ChiliMoon</smallcaps></ex>
</desc>

<attr name='space'>
 <p>Put a space between every character.</p>
<ex><smallcaps space=''>ChiliMoon</smallcaps></ex>
</attr>

<attr name='class' value='string'>
 <p>Apply this cascading style sheet (CSS) style on all elements.</p>
</attr>

<attr name='smallclass' value='string'>
 <p>Apply this cascading style sheet (CSS) style on all small elements.</p>
</attr>

<attr name='bigclass' value='string'>
 <p>Apply this cascading style sheet (CSS) style on all big elements.</p>
</attr>

<attr name='size' value='number'>
 <p>Use font tags, and this number as big size.</p>
</attr>

<attr name='small' value='number' default='size-1'>
 <p>Size of the small tags. Only applies when size is specified.</p>

 <ex><smallcaps size='6' small='2'>ChiliMoon</smallcaps></ex>
</attr>",

//----------------------------------------------------------------------

"charset":#"<desc type='both'><p>
 <short>Set output character set.</short>
 The tag can be used to decide upon the final encoding of the resulting page.
 All character sets listed in <a href='http://rfc.roxen.com/1345'>RFC 1345</a>
 are supported.
</p>
</desc>

<attr name='in' value='Character set'><p>
 Converts the contents of the charset tag from the character set indicated
 by this attribute to the internal text representation.</p>

 <note><p>This attribute is depricated, use &lt;recode 
 from=\"\"&gt;...&lt;/recode&gt; instead.</p></note>
</attr>

<attr name='out' value='Character set'><p>
 Sets the output conversion character set of the current request. The page
 will be sent encoded with the indicated character set.</p>
</attr>
",

//----------------------------------------------------------------------

"recode":#"<desc type='cont'><p>
 <short>Converts between character sets.</short>
 The tag can be used both to decode texts encoded in strange character
 encoding schemas, and encode internal data to a specified encoding
 scheme. All character sets listed in <a
 href='http://rfc.roxen.com/1345'>RFC 1345</a> are supported.
</p>
</desc>

<attr name='from' value='Character set'><p>
 Converts the contents of the charset tag from the character set indicated
 by this attribute to the internal text representation. Useful for decoding
 data stored in a database.</p>
</attr>

<attr name='to' value='Character set'><p>
 Converts the contents of the charset tag from the internal representation
 to the character set indicated by this attribute. Useful for encoding data
 before storing it into a database.</p>
</attr>
",

//----------------------------------------------------------------------

"emit#known-langs":({ #"<desc type='plugin'><p><short>
 Outputs all languages partially supported by roxen for writing
 numbers, weekdays et c.</short>
 Outputs all languages partially supported by roxen for writing
 numbers, weekdays et c (for example for the number and date tags).
 </p>
</desc>

 <ex><emit source='known-langs' sort='englishname'>
  4711 in &_.englishname;: <number lang='&_.id;' num='4711'/><br />
</emit></ex>",
			([
			  "&_.id;":#"<desc type='entity'>
 <p>Prints the three-character ISO 639-2 id of the language, for
 example \"eng\" for english and \"deu\" for german.</p>
</desc>",
			  "&_.name;":#"<desc type='entity'>
 <p>The name of the language in the language itself, for example
 \"fran�ais\" for french.</p>
</desc>",
			  "&_.englishname;":#"<desc type='entity'>
 <p>The name of the language in English.</p>
</desc>",

//----------------------------------------------------------------------

"random":#"<desc type='cont'><p><short>
 Randomly chooses a message from its contents.</short>
</p></desc>

<attr name='separator' value='string'>
 <p>The separator used to separate the messages, by default newline.</p>

<ex><random separator='#'>Foo#Bar#Baz</random></ex>
</attr>

<attr name='seed' value='string'>
 <p>Enables you to use a seed that determines which message to choose.</p>

<ex-box>Tip of the day:
<set variable='var.day'><date type='iso' date=''/></set>
<random seed='var.day'><insert file='tips.txt'/></random></ex-box>
</attr>",

//----------------------------------------------------------------------

"if#date":#"<desc type='plugin'><p><short>
 Is the date yyyymmdd?</short> The attributes before, after and
 inclusive modifies the behavior. This is a <i>Utils</i> plugin.
</p></desc>
<attr name='date' value='yyyymmdd | yyyy-mm-dd' required='required'><p>
 Choose what date to test.</p>
</attr>

<attr name='after'><p>
 The date after todays date.</p>
</attr>

<attr name='before'><p>
 The date before todays date.</p>
</attr>

<attr name='inclusive'><p>
 Adds todays date to after and before.</p>

 <ex>
  <if date='19991231' before='' inclusive=''>
     - 19991231
  </if>
  <else>
    20000101 -
  </else>
 </ex>
</attr>",

//----------------------------------------------------------------------

"if#time":#"<desc type='plugin'><p><short>
 Is the time hhmm, hh:mm, yyyy-mm-dd or yyyy-mm-ddThh:mm?</short> The attributes before, after,
 inclusive and until modifies the behavior. This is a <i>Utils</i> plugin.
</p></desc>
<attr name='time' value='hhmm|yyyy-mm-dd|yyyy-mm-ddThh:mm' required='required'><p>
 Choose what time to test.</p>
</attr>

<attr name='after'><p>
 The time after present time.</p>
</attr>

<attr name='before'><p>
 The time before present time.</p>
</attr>

<attr name='until' value='hhmm|yyyy-mm-dd|yyyy-mm-ddThh:mm'><p>
 Gives true for the time range between present time and the time value of 'until'.</p>
</attr>

<attr name='inclusive'><p>
 Adds present time to after and before.</p>

<ex-box>
  <if time='1200' before='' inclusive=''>
    ante meridiem
  </if>
  <else>
    post meridiem
  </else>
</ex-box>
</attr>",

//----------------------------------------------------------------------

//----------------------------------------------------------------------
			]) }),

#if 0
  // This applies to the old rxml 1.x parser. The doc for this tag is
  // here only for historical interest, to serve as a monument over
  // the quoting horrors that do_output_tag and its likes incurred.
  "recursive-output": #"\
<desc type='cont'>
  <p>This container provides a way to implement recursive output,
  which is mainly useful when you want to create arbitrarily nested
  trees from some external data, e.g. an SQL database. Put simply, the
  <tag>recurse</tag> tag is replaced by everything inside and
  including the <tag>recursive-output</tag> container. Although simple
  in theory, it tends to get a little bit messy in practice.</p>

  <p>To make it work you have to pay some attention to the parsing
  order of the involved tags. After the <tag>recursive-output</tag>
  container have replaced every <tag>recurse</tag> with itself, the
  whole thing is parsed again. Therefore, to make it terminate, you
  must always put the <tag>recurse</tag> inside a conditional
  container (typically an <tag>if</tag>) that does not preparse its
  contents.</p>

  <p>So far so good, but you'll almost always want to use some sort of
  output container, e.g. <tag>formoutput</tag> or
  <tag>sqloutput</tag>, together with this tag, which makes it
  slightly more complex due to the necessary treatment of the quote
  characters. Since the contents of <tag>recursive-output</tag> is
  expanded two levels at any time, each level needs its own set of
  quotes. To accomplish this, <tag>recursive-output</tag> can rotate
  two quote sets which are specified by the `inside' and `outside'
  arguments. Each time a <tag>recurse</tag> is replaced, every string
  in the `inside' set is replaced by the string in the corresponding
  position in the `outside' set, then the two sets trade places. Thus,
  you should put all quote characters you use inside
  <tag>recursive-output</tag> in the `inside' set and some other
  characters that doesn't clash with anything in the `outside' set.
  You might also have to quote the quote characters when writing these
  sets, which is done by doubling them.</p>
</desc>

<attr name='inside' value='string,...'><p>
  The list of quotes `inside' the container, to be replaced in with the
  `outside' set in every other round of recursion.</p>
</attr>

<attr name='outside' value='string,...'><p>
  The list of quotes `outside' the container, to be replaced in with
  the `inside' set in every other round of recursion.</p>
</attr>

<attr name='multisep' value='separator'><p>
  The given value is used as the separator between the strings in the
  two sets. It defaults to ','.</p>
</attr>

<attr name='limit' value='number'><p>
  Specifies the maximum nesting depth. As a safeguard it defaults to
  100.</p>
</attr>",
#endif

]);
#endif
