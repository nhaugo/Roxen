//! Things that belong elsewhere but can't lie there for various silly
//! reasons. Everything here is considered internal and not part of
//! the RXML.pmod API.
//!
//! E.g. one reason is to avoid circular references in the parser
//! objects when the callbacks are defined in them.
//!
//! Created 2000-01-21 by Martin Stjernholm
//!
//! $Id: utils.pmod,v 1.27 2001/07/09 04:03:03 mast Exp $

constant is_RXML_encodable = 1;

#ifdef RXML_ENCODE_DEBUG
string _sprintf() {return "RXML.utils.pmod";}
#endif

constant short_format_length = 40;

final string format_short (mixed val)
// This one belongs somewhere else..
{
  string res = "";

  void format_val (mixed val)
  {
    if (arrayp (val) || multisetp (val)) {
      string end;
      if (multisetp (val)) res += "(<", end = ">)", val = indices (val);
      else res += "({", end = "})";
      if (sizeof (res) >= short_format_length) throw (0);
      for (int i = 0; i < sizeof (val);) {
	format_val (val[i]);
	if (++i < sizeof (val)) res += ", ";
	if (sizeof (res) >= short_format_length) throw (0);
      }
      res += end;
    }
    else if (mappingp (val)) {
      res += "([";
      if (sizeof (res) >= short_format_length) throw (0);
      array ind = sort (indices (val));
      for (int i = 0; i < sizeof (ind);) {
	format_val (ind[i]);
	res += ": ";
	if (sizeof (res) >= short_format_length) throw (0);
	format_val (val[ind[i]]);
	if (++i < sizeof (ind)) res += ", ";
	if (sizeof (res) >= short_format_length) throw (0);
      }
      res += "])";
    }
    else {
      if (stringp (val) && sizeof (val) > short_format_length - sizeof (res)) {
	sscanf (val, "%[ \t\n\r]", string lead);
	if (sizeof (lead) > sizeof ("/.../") && sizeof (lead) < sizeof (val))
	  val = val[sizeof (lead)..], res += "/.../";
	if (sizeof (val) > short_format_length - sizeof (res)) {
	  res += sprintf ("%O", val[..short_format_length - sizeof (res) - 1]);
	  throw (0);
	}
      }
      res += sprintf ("%O", val);
    }
  };

  mixed err = catch {
    format_val (val);
    return res;
  };
  if (err) throw (err);
  return res + "/.../";
}

final array return_zero (mixed... ignored) {return 0;}
final array return_empty_array (mixed... ignored) {return ({});}
final mapping(string:string) return_empty_mapping (mixed... ignored)
  {return ([]);}
final mapping(string:string) return_help_arg (mixed... ignored)
  {return (["help": "help"]);}

final mixed get_non_nil (RXML.Type type, mixed... vals)
// Returns the single argument in vals that isn't RXML.nil, or
// RXML.nil if all of them are that value. Throws an rxml parse error
// if more than one argument isn't nil.
{
  int pos = -1;
  do
    if (++pos == sizeof (vals)) return RXML.nil;
  while (vals[pos] == RXML.nil);
  mixed res = vals[pos];
  for (pos++; pos < sizeof (vals); pos++)
    if (vals[pos] != RXML.nil)
      RXML.parse_error (
	"Cannot append another value %s to non-sequential value of type %s.\n",
	format_short (vals[pos]), type->name);
  return res;
}

final int(1..1)|string|array unknown_tag_error (object/*(RMXL.PXml)*/ p, string str)
{
  p->context->handle_exception (
    catch (RXML.parse_error (
	     "Unknown tag %s is not allowed in context of type %s.\n",
	     format_short (p->tag_name()), p->type->name)), p, 1);
  return ({});
}

final int(1..1)|string|array unknown_pi_tag_error (object/*(RMXL.PXml)*/ p, string str)
{
  sscanf (str, "%[^ \t\n\r]", str);
  p->context->handle_exception (
    catch (RXML.parse_error (
	     "Unknown processing instruction %s not allowed in context of type %s.\n",
	     format_short ("<" + p->tag_name() + str), p->type->name)), p, 1);
  return ({});
}

final int(1..1)|string|array invalid_cdata_error (object/*(RXML.PXml)*/ p, string str)
{
  p->context->handle_exception (
    catch (RXML.parse_error (
	     "CDATA text %O is not allowed in context of type %s.\n",
	     format_short (str), p->type->name)), p, 1);
  return ({});
}

final int(1..1)|string|array output_error_cb (object/*(RMXL.PXml)*/ p, string str)
{
  p->output_errors();
  return ({str});
}


// PXml and PEnt callbacks.

final int(1..1)|string|array p_xml_comment_cb (object/*(RXML.PXml)*/ p, string str)
// FIXME: This is a kludge until quote tags are handled like other tags.
{
  p->drain_output();
  string name = p->parse_tag_name (str);
  if (sizeof (name)) {
    name = p->tag_name() + name;
    if (string|array|function tdef = p->tags()[name]) {
      if (stringp (tdef))
	return ({tdef});
      else if (arrayp (tdef))
	return tdef[0] (p, p->parse_tag_args (str), @tdef[1..]);
      else
	return tdef (p, p->parse_tag_args (str));
    }
    else if (p->containers()[name])
      p->context->handle_exception (
	catch (RXML.parse_error (
		 "Sorry, can't handle containers beginning with %s.\n",
		 p->tag_name())), p, 1);
  }
  return p->type->free_text ? 0 : ({});
}

final int(1..1)|string|array p_xml_cdata_cb (object/*(RXML.PXml)*/ p, string str)
{
  return ({str});
}

final int(1..1)|string|array p_xml_entity_cb (object/*(RXML.PXml)*/ p, string str)
{
  RXML.Type type = p->type;
  string entity = p->tag_name();
  if (sizeof (entity))
    if (entity[0] == '#') {
      if (!p->type->entity_syntax) {
	// Don't decode normal entities if we're outputting xml-like stuff.
	if (sscanf (entity,
		    (<"#x", "#X">)[entity[..1]] ? "%*2s%x%*c" : "%*c%d%*c",
		    int char) == 2)
	  catch (str = (string) ({char}));
	// Lax error handling: Just let it through if it can't be
	// converted. Not really good, though.
      }
    }
    else
      if (entity[0] == ':') str = entity[1..];
      else if (has_value (entity, ".")) {
	p->drain_output();
	mixed value = p->handle_var (
	  p,
	  entity,
	  // No quoting of splice args. FIXME: Add some sort of
	  // safeguard against splicing in things like "nice><evil
	  // stuff='...'"?
	  p->html_context() == "splice_arg" ? RXML.t_any_text : type);
	if (value != RXML.nil) p->add_value (value);
	return ({});
      }
  return ({str});
}

final int(1..1)|string|array p_xml_compat_entity_cb (object/*(RMXL.PXml)*/ p, string str)
{
  RXML.Type type = p->type;
  string entity = p->tag_name();
  if (sizeof (entity) && entity[0] != '#')
    if (entity[0] == ':') str = entity[1..];
    else if (has_value (entity, ".")) {
      p->drain_output();
      mixed value = p->handle_var (
	p,
	entity,
	// No quoting of splice args. FIXME: Add some sort of
	// safeguard against splicing in things like "nice><evil
	// stuff='...'"?
	p->html_context() == "splice_arg" ? RXML.t_any_text : type);
      if (value != RXML.nil) p->add_value (value);
      return ({});
    }
  return ({str});
}
