//! Variant of PXml that parses only entities.
//!
//! This parser is the default for arguments.
//!
//! Created 2000-01-28 by Martin Stjernholm.
//!
//! $Id: PEnt.pike,v 1.18 2001/03/01 03:13:32 mast Exp $

//#pragma strict_types // Disabled for now since it doesn't work well enough.

#include <config.h>

inherit RXML.PXml;

// Block these to avoid confusion.
constant add_tag = 0;
constant add_tags = 0;
constant add_container = 0;
constant add_containers = 0;

static void init_entities()
{
  if (!type->entity_syntax) {
    // Don't decode normal entities if we're outputting xml-like stuff.
#ifdef OLD_RXML_COMPAT
    clear_entities();
    if (not_compat) {
#endif
      add_entities (tag_set->get_string_entities());
#ifdef OLD_RXML_COMPAT
    }
#endif
  }

#ifdef OLD_RXML_COMPAT
  if (not_compat)
#endif
    _set_entity_callback (.utils.p_xml_entity_cb);
#ifdef OLD_RXML_COMPAT
  else
    _set_entity_callback (.utils.p_xml_compat_entity_cb);
#endif
}

void reset (RXML.Context ctx, RXML.Type _type, RXML.TagSet _tag_set)
{
  context = ctx;
#ifdef DEBUG
  if (type != _type) error ("Internal error: Type change in reset().\n");
  if (tag_set != _tag_set) error ("Internal error: Tag set change in reset().\n");
#endif

#ifdef OLD_RXML_COMPAT
  int new_not_compat = !(ctx && ctx->id && ctx->id->conf->old_rxml_compat);
  if (new_not_compat == not_compat) return;
  not_compat = new_not_compat;
  init_entities();
#endif
}

this_program clone (RXML.Context ctx, RXML.Type type, RXML.TagSet tag_set)
{
#ifdef OLD_RXML_COMPAT
  int new_not_compat = !(ctx && ctx->id && ctx->id->conf->old_rxml_compat);
  if (new_not_compat != not_compat) return this_program (ctx, type, tag_set);
#endif
  return [object(this_program)] _low_clone (ctx, type, tag_set, 1);
}

static void create (
  RXML.Context ctx, RXML.Type type, RXML.TagSet tag_set, void|int cloned)
{
#ifdef OLD_RXML_COMPAT
  not_compat = !(ctx && ctx->id && ctx->id->conf->old_rxml_compat);
#endif

  _tag_set_parser_create (ctx, type, tag_set);

  if (cloned) return;

  if (!type->free_text) {
    mixed_mode (1);
    _set_data_callback (.utils.return_empty_array);
  }
  ignore_tags (1);
  lazy_entity_end (1);
  match_tag (0);

  init_entities();
}

// These have no effect since we don't parse tags.
constant add_runtime_tag = 0;
constant remove_runtime_tag = 0;

#ifdef OBJ_COUNT_DEBUG
string _sprintf()
{
  return sprintf ("RXML.PEnt(%O,%O)%s", type, tag_set,
		  __object_marker ? "[" + __object_marker->count + "]" : "");
}
#else
string _sprintf()
{
  return sprintf ("RXML.PEnt(%O,%O)", type, tag_set);
}
#endif
