//! Things that belong elsewhere but can't lie there for various silly reasons.
//!
//! E.g. one reason is to avoid circular references in the parser
//! objects when the callbacks are defined in them.
//!
//! Created 2000-01-21 by Martin Stjernholm
//!
//! $Id: utils.pmod,v 1.5 2000/02/13 18:07:15 mast Exp $


array return_zero (mixed... ignored) {return 0;}
array return_empty_array (mixed... ignored) {return ({});}

int(1..1)|string|array free_text_error (Parser.HTML p, string str)
{
  sscanf (str, "%[ \t\n\r]", string ws);
  if (str != ws) {
    sscanf (reverse (str), "%*[ \t\n\r]%s", str);
    sscanf (reverse (str), "%*[ \t\n\r]%s", str);
    RXML.rxml_parse_error ("Free text %O is not allowed in this context.\n", str);
  }
  return ({});
}

int(1..1)|string|array unknown_tag_error (Parser.HTML p, string str)
{
  RXML.rxml_parse_error ("Unknown tag %O. Unknown tags are not "
			 "allowed in this context.\n", p->tag_name());
  return ({});
}

int(1..1)|string|array output_error_cb (Parser.HTML p, string str)
{
  if (p->errmsgs) str = p->errmsgs + str, p->errmsgs = 0;
  if (p->type->free_text) p->_set_data_callback (0);
  else p->_set_data_callback (free_text_error);
  return ({str});
}


// PXml callbacks.

int(1..1)|string|array p_xml_entity_cb (Parser.HTML p, string str)
{
  string entity = p->tag_name();
  if (sizeof (entity)) {
    if (entity[0] != '#')
      return p->handle_var (entity);
    if (p->type->quoting_scheme != "xml") {
      // Don't decode any normal entities if we're outputting xml-like stuff.
      if (!p->type->free_text) return ({});
      string out;
      if ((<"#x", "#X">)[entity[..1]]) {
	if (sscanf (entity, "%*2s%x%*c", int c) == 2) out = (string) ({c});
      }
      else
	if (sscanf (entity, "%*c%d%*c", int c) == 2) out = (string) ({c});
      return out && ({out});
    }
  }
  return p->type->free_text ? 0 : ({});
}


// PHtmlCompat callbacks.

int(1..1)|string|array p_html_compat_tagmap_tag_cb (
  Parser.HTML p, string str, mixed... extra)
{
  string name = p->flag_parse_html_compat ? lower_case (p->tag_name()) : p->tag_name();
  if (mixed tdef = p->tagmap_tags[name])
    if (stringp (tdef))
      return ({tdef});
    else if (arrayp (tdef))
      return tdef[0] (p, p->tag_args(), @tdef[1..], @extra);
    else
      return tdef (p, p->tag_args(), @extra);
  else if (mixed cdef = p->tagmap_containers[name])
    // A container has been added.
    p->_low_add_container (name, p_html_compat_tagmap_container_cb);
  return 1;
}

int(1..1)|string|array p_html_compat_tagmap_container_cb (
  Parser.HTML p, mapping(string:string) args, string content, mixed... extra)
{
  string name = p->flag_parse_html_compat ? lower_case (p->tag_name()) : p->tag_name();
  if (mixed cdef = p->tagmap_containers[name])
    if (stringp (cdef))
      return ({cdef});
    else if (arrayp (cdef))
      return cdef[0] (p, args, content, @cdef[1..], @extra);
    else
      return cdef (p, args, content, @extra);
  else
    // The container has disappeared from the mapping.
    p->_low_add_container (name, 0);
  return 1;
}

array p_html_compat_entity_cb (Parser.HTML p, string str)
{
  string entity = p->tag_name();
  if (sizeof (entity) && entity[0] != '#') return p->handle_var (entity);
  return p->type->free_text ? 0 : ({});
}
