/* $Id: ftpstatus.pike,v 1.7 2004/05/31 23:01:45 _cvs_stephen Exp $ */

/* Disabled for now. (Was originally written for ftp mk I). */
#if 0

inherit "wizard";

constant task = "status";
constant name = "Current FTP sessions";
constant doc  = ("List all active FTP sessions and what files they are "
		 "currently transferring.");

static string describe_ftp(object ftp)
{
  string res = "<tr>";

  res += "<td>"+
    core->blocking_ip_to_host(((ftp->cmd_fd->query_address()||"")/" ")[0])+
    "</td>";

  if(ftp->session_auth)
    res += "<td>"+ftp->session_auth[1]+"</td>";
  else
    res += "<td><i>anonymous</i></td>";

  res += "<td>"+ftp->cwd+"</td>";

  if(ftp->curr_pipe || ftp->my_fd) {

    res += "<td>"+ftp->method+"</td><td>"+ftp->not_query+"</td>";

    if(ftp->curr_pipe) {
      int b;
      res += "<td>"+(b=ftp->curr_pipe->bytes_sent())+" bytes";
      if(ftp->file && ftp->file->len && ftp->file->len!=0x7fffffff)
	res += sprintf(" (%1.1f%%)", (100.0*b)/ftp->file->len);
      res += "</td>";
    } else if(ftp->my_fd) {
      int b;
      res += "<td>"+(b=ftp->my_fd->bytes_received())+" bytes";
      if(ftp->misc->len && ftp->misc->len!=0x7fffffff)
	res += sprintf(" (%1.1f%%)", (100.0*b)/ftp->misc->len);
      res += "</td>";
    }
  } else
    res += "<td><i>idle</i></td>";

  return res + "</tr>\n";
}

string parse( RequestID id )
{
  program p = ((program)"plugins/protocols/ftp");
  multiset(object) ftps = (< >);
  object o = next_object();
  for(;;) {
    if(o && object_program(o) == p && o->cmd_fd)
      ftps[o]=1;
    if(catch(o = next_object(o)))
      break;
  }

  if(sizeof(ftps))
    return "<table border='0'><tr align=left>"
      "<th>From</th><th>User</th><th>CWD</th>"
      "<th>Action</th><th>File</th><th>Transferred</th></tr>\n" +
      Array.map(indices(ftps), describe_ftp)*""+"</table>\n<cf-ok/>";
  else
    return "There are currently no active FTP sessions."
      "<p><cf-ok/></p>";
}

#endif /* 0 */
