inherit "etc/test/tests/pike_test_common.pike"; // Necessary for stuff in testsuite.h to work...

#include <testsuite.h>

array(Standards.URI) get_test_urls(Configuration conf,
                                   string webdav_mount_point,
                                   string|void username,
                                   string|void password)
{
  array(Standards.URI) uris = ({});
  // Run the suite once with every http protocol modules in the conf.
  // This allows for testing such things as sub-path mounted sites etc.
  foreach(conf->registered_urls, string full_url) {
    mapping(string:string|Configuration|array(Protocol)) port_info =
      roxen.urls[full_url];
    if (!test_true(mappingp, port_info)) continue;
    array(Protocol) ports = port_info->ports;
    if (!test_true(arrayp, ports)) continue;
    foreach(ports, Protocol prot) {
      if (!test_true(stringp, prot->prot_name)) continue;
      if (prot->prot_name != "http") continue;

      if (prot->bound != 1) continue;

      if (!test_true(mappingp, prot->urls)) continue;

      // Strip the fragment from the full_url.
      string url = (full_url/"#")[0];
      mapping(string:mixed) url_data = prot->urls[url];
      if (!test_true(mappingp, url_data)) continue;

      report_debug("url data: %O\n", url_data);
      test_true(`==, url_data->conf, conf);
      test_true(`==, url_data->port, prot);
      test_true(stringp, url_data->hostname);
      test_true(stringp, url_data->path || "/");

      Standards.URI url_uri = Standards.URI(url, "http://*/");
      Standards.URI base_uri = Standards.URI(
        Stdio.append_path(url_data->path || "/",
                          webdav_mount_point),
                          url_uri);
      base_uri->port = prot->port;
      base_uri->host = prot->ip;

      if (username) {
        base_uri->user = username;
        base_uri->password = password;
      }
      uris += ({base_uri});
    }
  }
  return uris;
}
