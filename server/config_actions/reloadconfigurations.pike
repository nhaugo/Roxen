/*
 * $Id: reloadconfigurations.pike,v 1.5 1998/06/05 19:27:21 grubba Exp $
 */

inherit "roxenlib";
constant name= "Cache//Reload configurations from disk";

constant doc = ("Force a reload of all configuration information from the "
		"configuration files");

constant more=1;

mixed handle(object id, object mc)
{
  report_notice("Reloading configuration files from disk\n");
  roxen->configs = ([]);
  roxen->setvars(roxen->retrieve("Variables", 0));
  roxen->initiate_configuration_port( 0 );

  foreach(roxen->configurations, object o)
  {
    // Closing ports...
    if (o->server_ports) {
      // Roxen 1.2.26 or later
      Array.map(values(o->server_ports), o->do_dest);
    } else {
      Array.map(indices(o->open_ports), o->do_dest);
    }
    report_notice("Updating old configuration "+o->name+"\n");
    o->stop();
    o->create(o->name);
    o->start();
  }

  int new;
  foreach(roxen->list_all_configurations(), string config)
  {
    foreach(roxen->configurations, object o)
    {
      if(lower_case(o->name) == lower_case(config))
      {
	new=0;
	break;
      }
    }
    if(new)
    {
      report_notice("Adding new configuration "+config+"\n");
      array err;
      if(err=catch { roxen->enable_configuration(config)->start();  })
	report_error("Error while enabling configuration "+config+":\n"+
		  describe_backtrace(err)+"\n");
    }
  }

  return http_redirect(roxen->config_url()+
		       "Actions/?action=reloadconfiginterface.pike&foo="+
		       time(1));
}
