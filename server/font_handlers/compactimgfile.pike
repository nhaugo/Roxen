#include <config.h>
inherit "imagetar";
constant name = "Compact image file font";
constant doc = 
#"A compact image file.
The format is very simple:
<pre>
'CIF1'      (4 bytes magic)
'fontname'  (64 bytes name, \\0 terminated)
for each char:
  char        (4 bytes charcode)
  len         (4 bytes image length)
  len bytes data
</pre>
All integers are NBO<p>
There is a small program included in bin (createcif.pike) that 
creates a cif font from an imagedir or imagetar font</p>";

class StringFile
{
  string data;
  int offset;

  string _sprintf()
  {
    return "StringFile("+strlen(data)+","+offset+")";
  }

  string read(int nbytes)
  {
    if(!nbytes)
    {
      offset = strlen(data);
      return data;
    }
    string d = data[offset..offset+nbytes-1];
    offset += strlen(d);
    return d;
  }

  void write(mixed ... args)
  {
    throw( ({ "File not open for write\n", backtrace() }) );
  }

  void seek(int to)
  {
    offset = to;
  }

  void create(string d)
  {
    data = d;
  }
}

class CIF
{
  Stdio.File fd;
  array filelist ;
  mapping offsets;
  array get_dir( string f )
  {
// #ifdef THREADS
//     object lock = lock->trylock();
// #endif
    if(!filelist)
    {
      offsets = ([]);
      filelist = ({ "/fontname" });
      
      fd->seek( 64 + 4 ); // header.
      int c;
      while( c = getint() )
      {
        offsets[c] = fd->tell();
        if( c < 48 || c > 127 )
          if( c == 0xffffffff )
            filelist += ({ "/fontinfo" });
          else
            filelist += ({ sprintf( "/0x%x", c ) });
        else
          filelist += ({ sprintf( "/%c", c ) });
        fd->read( getint() ); // skip data.
      }
    }
    return filelist;
  }

  int getint( )
  {
    int c;
    sscanf( fd->read( 4 ), "%4c", c );
    return c;
  }

  object open( string fname, string mode )
  {
// #ifdef THREADS
//     object lock = lock->trylock();
// #endif
    if(!offsets) get_dir( "foo" );
    fname -= "/";
    if( fname == "fontname" )
    {
      fd->seek( 4 );
      return StringFile( fd->read( 64 )-"\0" );
    }
//     werror("open "+fname+"\n");
    int wc;
    sscanf( fname, "%s.", fname );
    if( strlen(fname) > 2 ) sscanf( fname, "0x%x", wc ); else wc=fname[0];
    int c;

    if( fname == "fontinfo" )  wc = 0xffffffff;

    if( offsets[ wc ] )
    {
      fd->seek( offsets[ wc ] );
      return StringFile( fd->read( getint() ) );
    }
    return 0;
  }

  void create( string fname )
  {
    fd = Stdio.File( );
    if( !fd->open( fname, "r" ) )  error( "Illegal CIF\n");
    if( fd->read( 4 ) != "CIF1" )  error( "Illegal CIF\n");
  }
}

mapping(string:CIF) cif_cache = ([]);
CIF open_tar( string path )
{
  CIF res;
  if( cif_cache[ path ] )
    return cif_cache[ path ];
  if( !catch {  res= CIF( path ); } )
    cif_cache[ path ] = res;
  while( sizeof( cif_cache ) > 10 )
  {
    array q = indices( cif_cache );
    string w = q[ random( sizeof(q) ) ];
    if( w != path )
      m_delete( cif_cache, w );
  }
  return open_tar( path );
}

array(mapping) font_information( string fnt )
{
  array res = ::font_information( fnt );
  if( sizeof( res ) ) res[0]->format = "cif";
  return res;
}

void update_font_list()
{
  font_list = ([]);
  void rec_find_in_dir( string dir )
  {
    foreach( get_dir( dir )||({}), string pd )
    {
      if( file_stat( dir+pd )[ ST_SIZE ] == -2 ) // isdir
        rec_find_in_dir( dir+pd+"/" );
      else if( glob( "*.cif", pd ) )
      {
        CIF t = open_tar( dir+pd );
        if( Stdio.File f = t->open( "fontname", "r" ) )
          font_list[font_name( f->read() )] = dir+pd;
        else
          destruct( t );
      }
    }
  };

  foreach(roxen->query("font_dirs"), string dir)
    rec_find_in_dir( dir );
}
