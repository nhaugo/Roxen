/*
 * $Id: processstatus.pike,v 1.1 2000/02/02 04:14:17 per Exp $
 */

constant action="status";
constant name= "Process status";
constant doc = ("Shows various information about the roxen process.");

string describe_global_status()
{
  return "Server uptime             : "+
    roxen->msectos((time(1) - roxen->start_time)*1000) +"\n";
}

#define MB (1024*1024)

mixed parse(object id)
{
  string res;
  int *ru, tmp, use_ru;
  array err;
  if(err = catch(ru=rusage()))
    return sprintf("<h1>Failed to get rusage information: </h1><pre>%s</pre>",
		   describe_backtrace(err));

  if(ru[0])
    tmp=ru[0]/(time(1) - roxen->start_time+1);

  return (/* "<font size=\"+1\"><a href=\""+ roxen->config_url()+
	     "Actions/?action=processstatus.pike&foo="+ time(1)+
	     "\">Process status</a></font>"+ */
	  "<pre>"+
	  describe_global_status()+
	  "CPU-Time used             : "+roxen->msectos(ru[0]+ru[1])+
	  " ("+tmp/10+"."+tmp%10+"%)\n"
	  +(ru[-2]?(sprintf("Resident set size (RSS)   : %.3f Mb\n",
			    (float)ru[-2]/(float)MB)):"")
	  +(ru[-1]?(sprintf("Stack size                : %.3f Mb\n",
			    (float)ru[-1]/(float)MB)):"")
	  +(ru[6]?"Page faults (non I/O)     : " + ru[6] + "\n":"")
	  +(ru[7]?"Page faults (I/O)         : " + ru[7] + "\n":"")
	  +(ru[8]?"Full swaps (should be 0)  : " + ru[8] + "\n":"")
	  +(ru[9]?"Block input operations    : " + ru[9] + "\n":"")
	  +(ru[10]?"Block output operations   : " + ru[10] + "\n":"")
	  +(ru[11]?"Messages sent             : " + ru[11] + "\n":"")
	  +(ru[12]?"Messages received         : " + ru[12] + "\n":"")
	  +(ru[13]?"Number of signals received: " + ru[13] + "\n":"")
	  +"</pre><p><cf-ok>");
}
