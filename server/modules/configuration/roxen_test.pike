// This is a roxen module. Copyright � 2000, Roxen IS.

#include <module.h>
inherit "module";

constant cvs_version = "$Id: roxen_test.pike,v 1.34 2001/07/21 11:05:42 mast Exp $";
constant thread_safe = 1;
constant module_type = MODULE_TAG;
constant module_name = "Roxen self test module";
constant module_doc  = "Tests Roxen WebServer.";
constant is_roxen_tester_module = 1;

Configuration conf;
Stdio.File index_file;
Protocol port;

int verbose;

void start(int n, Configuration c)
{
  conf=c;
  index_file = Stdio.File();
  call_out( do_tests, 0.5 );
}

RequestID get_id()
{
  object id = RequestID(index_file, port, conf);
  id->conf = conf;
  id->misc = ([]);
  id->cookies=([]);
  id->config=(<>);
  id->real_variables=([]);
  id->variables = FakedVariables( id->real_variables );
  id->prestate=(<>);
  id->supports=(< "images" >);
  id->client_var=([]);

  id->pragma=(<>);
  id->client=({});

  id->realfile="etc/test/filesystem/index.html";
  id->query = "";
  id->not_query="/index.html";
  id->raw_url="/index.html";
  id->method="GET";
  id->request_headers=([]);
  id->remoteaddr="127.0.0.1";
  NOCACHE();

  id->misc->stat = conf->stat_file("/index.html", id);
  return id;
}

string canon_html(string in) {
  return Roxen.get_xml_parser()->_set_tag_callback (
    lambda (Parser.HTML p, string tag) {
      int xml = tag[-2] == '/';
      string ut = p->tag_name();
      mapping args = p->tag_args();
      foreach (sort (map (indices (args), lower_case)), string arg)
	ut += " " + arg + "='" + args[arg] + "'";
      if(xml) ut+="/";
      return ({"<", ut, ">"});
    })->finish (in)->read();
}


// --- XML-based test files -------------------------------

void xml_add_module(string t, mapping m, string c) {
  conf->enable_module(c);
  return;
}

void xml_drop_module(string t, mapping m, string c) {
  conf->disable_module(c);
  return;
}

void xml_use_module(string t, mapping m, string c,
		    mapping ignored, multiset(string) used_modules) {
  conf->enable_module(c);
  used_modules[c] = 1;
  return;
}

int tests, ltests;
int fails, lfails;
void xml_test(string t, mapping args, string c, mapping(int:RXML.PCode) p_code_cache) {

  ltests++;
  tests++;

  string rxml="", res;
  RXML.PCode p_code = p_code_cache[ltests];

  string indent( int l, string what )
  {
    array q = what/"\n";
    //   if( q[-1] == "" )  q = q[..sizeof(q)-2];
    string i = (" "*l+"|  ");
    return i+q*("\n"+i)+"\n";
  };
  string test_error( string message, mixed ... args )
  {
    if( sizeof( args ) )
      message = sprintf( message, @args );
    message = (p_code ? "[Eval from p-code] " : "[Eval from source] ") + message;
    if( verbose )
      if( strlen( rxml ) )
	report_debug("FAIL\n" );
    if( strlen( rxml ) )
      report_debug( indent(2, rxml ) );
    rxml="";
    report_debug( indent(2, message ) );
  };
  string test_ok(  )
  {
    rxml = "";
    if( verbose )
      report_debug( "PASS\n" );
  };
  string test_test( string test )
  {
    if( verbose && strlen( rxml ) )
      test_ok();
    rxml = test;
    if( verbose )
    {
      report_debug( "%4d %-69s %s  ",
		    ltests, replace(test[..68],
				    ({"\t","\n", "\r"}),
				    ({"\\t","\\n", "\\r"}) ),
		    p_code ? "(p-code)" : "(source)");
    }
  };

  RequestID id = get_id();
  int no_canon;
  Parser.HTML parser =
    Roxen.get_xml_parser()->
    add_containers( ([ "rxml" :
		       lambda(object t, mapping m, string c) {
			 test_test( c );
			 mixed err = catch {
			   if (!p_code) {
			     RXML.Parser parser = Roxen.get_rxml_parser (
			       id, m->type && RXML.t_type->encode (m->type) (RXML.PXml),
			       1);
			     parser->write_end (rxml);
			     res = parser->eval();
			     p_code_cache[ltests] = parser->p_code;
			   }
			   else
			     res = Roxen.eval_p_code (p_code, id);
			 };
			 if(err)
			 {
			   test_error("Failed (backtrace)\n");
			   test_error("%s\n",describe_backtrace(err));
			   throw(1);
			 }
			 if(!args["no-canon"])
			   res = canon_html(res);
			 else
			   no_canon = 1;
		       },
		       "result" :
		       lambda(object t, mapping m, string c) {
			 if( !no_canon )
			   c = canon_html( c );
			 if(res != c) {
			   if(m->not) return;
			   test_error("Failed (result %O != %O)\n", res, c);
			   throw(1);
			 }
			 test_ok( );
		       },
		       "glob" :
		       lambda(object t, mapping m, string c) {
			 if( !glob(c, res) ) {
			   if(m->not) return;
			   test_error("Failed (result %O does not match %O)\n",
				      res, c);
			   throw(1);
			 }
			 test_ok( );
		       },
		       "has-value" :
		       lambda(object t, mapping m, string c) {
			 if( !has_value(res, c) ) {
			   if(m->not) return;
			   test_error("Failed (result %O does not contain %O)\n",
				      res, c);
			   throw(1);
			 }
			 test_ok( );
		       },
		       "regexp" :
		       lambda(object t, mapping m, string c) {
			 if( !Regexp(c)->match(res) ) {
			   if(m->not) return;
			   test_error("Failed (result %O does not match %O)\n",
				      res, c);
			   throw(1);
			 }
			 test_ok( );
		       },
    ]) )
    ->add_tags( ([ "add" : lambda(object t, mapping m, string c) {
			     switch(m->what) {
			       default:
				 test_error("Could not <add> %O; "
					    "unknown variable.\n", m->what);
				 break;
			       case "prestate":
				 id->prestate[m->name] = 1;
				 break;
			       case "variable":
				 id->variables[m->name] = m->value || m->name;
				 break;
			       case "rvariable":
				 if(m->split && m->value)
				   id->real_variables[m->name] = m->value / m->split;
				 else
				   id->real_variables[m->name] = ({ m->value || m->name });
				 break;
			       case "cookies":
				 id->cookies[m->name] = m->value || "";
				 break;
			       case "supports":
				 id->supports[m->name] = 1;
				 break;
			       case "config":
				 id->config[m->name] = 1;
				 break;
			       case "client_var":
				 id->client_var[m->name] = m->value || "";
				 break;
			       case "misc":
				 id->misc[m->name] = m->value || "1";
				 break;
//  			       case "define":
//  				 id->misc->defines[m->name] = m->value || 1;
//  				 break;
			       case "not_query":
				 id->not_query = m->value;
				 break;
			       case "query":
				 id->query = m->value;
				 break;
			       case "request_header":
			         id->request_headers[m->name] = m->value;
			         break;
			     }
			   },
    ]) );

  if( catch(parser->finish(c)) ) {
    fails++;
    lfails++;
  }

  if( verbose && strlen( rxml ) ) test_ok();
  return;
}

void xml_comment(object t, mapping m, string c) {
  if(verbose)
    report_debug(c + (c[-1]=='\n'?"":"\n"));
}

void run_xml_tests(string data) {
  mapping(int:RXML.PCode) p_code_cache = ([]);
  multiset(string) used_modules = (<>);

  ltests=0;
  lfails=0;
  Roxen.get_xml_parser()->add_containers( ([
    "add-module" : xml_add_module,
    "drop-module" : xml_drop_module,
    "use-module": xml_use_module,
    "test" : xml_test,
    "comment": xml_comment,
  ]) )->
    add_quote_tag("!--","","--")->
    set_extra (p_code_cache, used_modules)->
    finish(data);

  data = Roxen.get_xml_parser()->add_quote_tag("!--","","--")->finish(data)->read();
  if(ltests<sizeof(data/"</test>")-1)
    report_warning("Possibly XML error in testsuite.\n");

  // Go through them again, evaluation from the p-code this time.
  ltests=0;
  Roxen.get_xml_parser()->add_containers( ([
    "add-module" : xml_add_module,
    "drop-module" : xml_drop_module,
    "test" : xml_test,
    "comment": xml_comment,
  ]) )->
    add_quote_tag("!--","","--")->
    set_extra (p_code_cache, used_modules)->
    finish(data);

  foreach (indices (used_modules), string modname)
    conf->disable_module (modname);

  report_debug("Did %d tests, failed on %d.\n", ltests * 2, lfails);
  continue_find_tests();
}


// --- Pike test files -----------------------

void run_pike_tests(object test, string path)
{
  void update_num_tests(int tsts, int fail)
  {
    tests+=tsts;
    fails+=fail;
    report_debug("Did %d tests, failed on %d.\n", tsts, fail);
    continue_find_tests();
  };

  if(!test)
    return;
  if( catch(test->low_run_tests(conf, update_num_tests)) )
    update_num_tests( 1, 1 );
}


// --- Mission control ------------------------

array(string) tests_to_run;
ADT.Stack file_stack = ADT.Stack();

void continue_find_tests( )
{
  while( string file = file_stack->pop() )
  {
    if( Stdio.Stat st = file_stat( file ) )
    {
      if( file!="CVS" && st->isdir )
      {
	string dir = file+"/";
	foreach( get_dir( dir ), string f )
	  file_stack->push( dir+f );
      }
      else if( glob("*/RoxenTest_*", file ) && file[-1]!='~')
      {
	report_debug("\nFound test file %s\n",file);
	int done;
	foreach( tests_to_run, string p )
	  if( glob( "*"+p+"*", file ) )
	  {
	    if(glob("*.xml",file))
	    {
	      call_out( run_xml_tests, 0, Stdio.read_file(file) );
	      return;
	    }
	    else if(glob("*.pike",file))
	    {
	      object test;
	      mixed error;
	      if( error=catch( test=compile_file(file)( verbose ) ) )
		report_error("Failed to compile %s\n%s\n", file,
			     describe_backtrace(error));
	      else
	      {
		call_out( run_pike_tests,0,test,file );
		return;
	      }
	    }
	    done++;
	    break;
	  }
	if( !done )
	  report_debug( "Skipped (not matched by --tests argument)\n" );
      }
    }
  }

  report_debug("\n\nDid a grand total of %d tests, %d failed.\n",
	       tests, fails);
  if( fails > 127 )
    fails = 127;
  exit( fails );
}

void do_tests()
{
  remove_call_out( do_tests );
  if(time() - roxen->start_time < 2 ) {
    call_out( do_tests, 0.2 );
    return;
  }

  tests_to_run = Getopt.find_option(roxen.argv, 0,({"tests"}),0,"" )/",";
  verbose = !!Getopt.find_option(roxen.argv, 0,({"tests-verbose"}),0, 0 );
  file_stack->push( 0 );
  file_stack->push( "etc/test/tests" );
  call_out( continue_find_tests, 0 );
}


// --- Some tags used in the RXML tests ---------------

class EntityDyn {
  inherit RXML.Value;
  int i;
  mixed rxml_var_eval(RXML.Context c, string var, string scope_name, void|RXML.Type type) {
    if(c->current_scope() && RXML.get_var("x"))
      return ENCODE_RXML_INT(i++, type);
    return ENCODE_RXML_INT(0, type);
  }
}

class EntityCVal(string val) {
  inherit RXML.Value;
  mixed rxml_const_eval(RXML.Context c, string var, string scope_name, void|RXML.Type type) {
    return ENCODE_RXML_TEXT(val, type);
  }
}

class EntityVVal(string val) {
  inherit RXML.Value;
  mixed rxml_var_eval(RXML.Context c, string var, string scope_name, void|RXML.Type type) {
    return ENCODE_RXML_TEXT(val, type);
  }
}

class TagEmitTESTER {
  inherit RXML.Tag;
  constant name = "emit";
  constant plugin_name = "TESTER";

  array(mapping(string:string)) get_dataset(mapping m, RequestID id) {
    switch(m->test) {
    case "4":
      return ({
	([ "a":"1", "b":EntityCVal("aa"), "c":EntityVVal("ca") ]),
	([ "a":"2", "b":EntityCVal("ba"), "c":EntityVVal("cb") ]),
	([ "a":"3", "b":EntityCVal("ab"), "c":EntityVVal("ba") ]),
      });

    case "3":
      return ({ (["data":"a"]), (["data":RXML.nil]), (["data":EntityDyn()]) });

    case "2":
      return map( "aa,a,aa,a,bb,b,cc,c,aa,a,dd,d,ee,e,aa,a,a,a,aa"/",",
		  lambda(string in) { return (["data":in]); } );
    case "1":
    default:
      return ({
	([ "a":"kex", "b":"foo", "c":1, "d":"12foo" ]),
	([ "a":"kex", "b":"boo", "c":2, "d":"foo" ]),
	([ "a":"krut", "b":"gazonk", "c":3, "d":"5foo33a" ]),
	([ "a":"kox", "c":4, "d":"5foo4a" ])
      });
    }
  }
}

class TagOEmitTESTER {
  inherit TagEmitTESTER;
  inherit "emit_object";
  constant plugin_name = "OTESTER";

  class MyEmit (array(mapping) dataset) {
    inherit EmitObject;
    int pos;

    private mapping(string:mixed) really_get_row() {
      return pos<sizeof(dataset)?dataset[pos++]:0;
    }
  }

  EmitObject get_dataset(mapping m, RequestID id) {
    return MyEmit( ::get_dataset(m,id) );
  }
}

class TagSEmitTESTER {
  inherit TagEmitTESTER;
  constant plugin_name = "STESTER";
  constant skiprows = 1;
  constant maxrows = 1;
  constant sort = 1;
}
