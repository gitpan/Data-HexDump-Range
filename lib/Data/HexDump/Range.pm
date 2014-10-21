
package Data::HexDump::Range ;

use strict;
use warnings ;
use Carp ;

BEGIN 
{

use Sub::Exporter -setup => 
	{
	exports => [ qw() ],
	groups  => 
		{
		all  => [ qw() ],
		}
	};
	
use vars qw ($VERSION);
$VERSION     = '0.06';
}

#-------------------------------------------------------------------------------

use English qw( -no_match_vars ) ;

use Readonly ;
Readonly my $EMPTY_STRING => q{} ;

use Carp qw(carp croak confess) ;

#use Graphics::ColorNames
use List::Util qw(min) ;
use List::MoreUtils qw(all) ;
use Scalar::Util qw(looks_like_number) ;
use Term::ANSIColor ;

#-------------------------------------------------------------------------------

=head1 NAME

Data::HexDump::Range - Hexadecial Range Dumper

=head1 SYNOPSIS

  my $hdr = Data::HexDump::Range->new() ;
  
  print $hdr->dump(['magic cookie', 12, 'red'], $data) ;
  
  $hdr->gather(['magic cookie', 12, 'red'], $data) ; 
  $hdr->gather(['image type', 2, 'green'], $other_data) ;
  $hdr->gather(['image data ...', 100, 'yellow'], $more_data, 0, CONSUME_ALL_DATA) ;
  
  print $hdr->dump_gathered() ;
  
  $hdr->reset() ;

=head1 DESCRIPTION

Creates a dump from binary data and user defined I<range> descriptions. The goal of this modules is
to create an easy to understand dump of binary data. This achieved through:

=over 2

=item * Highlighted (colors) dump that is easier to understand than a monochrome blob of hex data

=item * Multiple rendering modes with different output formats

=item * The possibility to describe complex structures

=back

=head1 DOCUMENTATION

The shortest perl dumper is C<perl -ne 'BEGIN{$/=\16} printf "%07x0: @{[unpack q{(H2)*}]}\n", $.-1'>, courtesy of a golfing session 
with Andrew Rodland <arodland@cpan.org> aka I<hobbs> on #perl.

B<hexd> from libma L<http://www.ioplex.com/~miallen/libmba/> is nice tools that inspired me to write this module. It may be a better 
alternative If you need very fast dump generation.

priodev, tm604, Khisanth and other helped with the html output.


B<Data::HexDump::Range> splits binary data according to user defined I<ranges> and rendered as a B<hex> or/and B<decimal> data dump.
The data dump can be rendered in ANSI, ASCII or HTML.

=head2 Orientation

=head3 Vertical

In this orientation mode, each range displayed separately starting with the range name
followed by the binary data dump. 

  magic cookie     00000000 00000000 0a 70 61 63 6b 61 67 65 20 44 61 74               .package Dat
  padding          0000000c 00000000 61 3a 3a 48 65 78 44 75 6d 70 3a 3a 52 61 6e 67   a::HexDump::Rang
  padding          0000001c 00000010 65 20 3b 0a 0a 75 73 65 20 73 74 72 69 63 74 3b   e ;..use strict;
  data header      0000002c 00000000 0a 75 73 65 20                                    .use
  data             00000031 00000000 77 61 72 6e 69 6e 67 73 20 3b 0a 75 73 65 20 43   warnings ;.use C
  data             00000041 00000010 61 72 70 20                                       arp
  extra data       00000045 00000000 3b 0a 0a 42 45 47 49 4e 20 0a 7b 0a               ;..BEGIN .{.
  data header      00000051 00000000 0a 75 73 65 20                                    .use
  data             00000056 00000000 53 75 62 3a 3a 45 78 70 6f 72 74 65 72 20 2d 73   Sub::Exporter -s
  data             00000066 00000010 65 74 75 70                                       etup
  footer           0000006a 00000000 20 3d 3e 20                                        =>



=begin html

<pre style ="font-family: monospace; background-color: #222 ;">

<span style='color:#fff;'>RANGE_NAME       OFFSET   CUMULATI HEX_DUMP                                         ASCII_DUMP       </span> 
<span style='color:#fff;'>                                   0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f   0123456789012345 </span> 
<span style='color:#0f0;'>12:header       </span> <span style='color:#fff;'>00000000</span> <span style='color:#fff;'>00000000</span> <span style='color:#0f0;'>63 6f 6d 6d 69 74 20 37 34 39 30 39             </span> <span style='color:#0f0;'>commit 74909    </span> 
<span style='color:#f00;'>"comment"</span> 
<span style='color:#ff0;'><0:zero></span> 
<span style='color:#ff0;'>10:name         </span> <span style='color:#fff;'>0000000c</span> <span style='color:#fff;'>00000000</span> <span style='color:#ff0;'>63 37 36 35 37 65 64 62 38 39                   </span> <span style='color:#ff0;'>c7657edb89      </span> 
<span style='color:#f0f;'>5:offset        </span> <span style='color:#fff;'>00000016</span> <span style='color:#fff;'>00000000</span> <span style='color:#f0f;'>34 65 66 61 65                                  </span> <span style='color:#f0f;'>4efae           </span> 
<span style='color:#f00;'>17:footer       </span> <span style='color:#fff;'>0000001b</span> <span style='color:#fff;'>00000000</span> <span style='color:#f00;'>65 34 63 64 37 39 34 33 63 65 37 38 37 35 66 62 </span> <span style='color:#f00;'>e4cd7943ce7875fb</span> 
<span style='color:#f00;'>17:footer       </span> <span style='color:#fff;'>0000002b</span> <span style='color:#fff;'>00000010</span> <span style='color:#f00;'>32                                              </span> <span style='color:#f00;'>2               </span> 
<span style='color:#fff;'>5:something     </span> <span style='color:#fff;'>0000002c</span> <span style='color:#fff;'>00000000</span> <span style='color:#fff;'>36 31 39 20 28                                  </span> <span style='color:#fff;'>619 (           </span> 

</pre>

=end html

=head3 Horizontal

In this mode, the data are packed together in the dump

  00000000 0a 70 61 63 6b 61 67 65 20 44 61 74 61 3a 3a 48   .package Data::H magic cookie, padding,
  00000010 65 78 44 75 6d 70 3a 3a 52 61 6e 67 65 20 3b 0a   exDump::Range ;. padding,
  00000020 0a 75 73 65 20 73 74 72 69 63 74 3b 0a 75 73 65   .use strict;.use padding, data header,
  00000030 20 77 61 72 6e 69 6e 67 73 20 3b 0a 75 73 65 20    warnings ;.use  data header, data,
  00000040 43 61 72 70 20 3b 0a 0a 42 45 47 49 4e 20 0a 7b   Carp ;..BEGIN .{ data, extra data,
  00000050 0a 0a 75 73 65 20 53 75 62 3a 3a 45 78 70 6f 72   ..use Sub::Expor extra data, data header, data,
  00000060 74 65 72 20 2d 73 65 74 75 70 20 3d 3e 20         ter -setup =>    data, footer,

=head2 Rendered fields

You can choose which fields are rendered by setting options when creating a Data::HexDump::Range object.
The default rendering corresponds to the following object construction:

  Data::HexDump::Range->new
	(
	FORMAT => 'ANSI',
	COLOR => 'cycle',
	
	ORIENTATION => 'horizontal',
	
	DISPLAY_RANGE_NAME => 1 ,
	
	DISPLAY_OFFSET  => 1 ,
	OFFSET_FORMAT => 'hex',
	
	DISPLAY_HEX_DUMP => 1,
	DISPLAY_ASCII_DUMP => 1,
	
	DATA_WIDTH => 16,
	) ;

See L<new>.

=head2 Range definition

  my $simple_range = ['magic cookie', 12, 'red'] ;
  
Ranges are Array references containing four (4) elements:

=over 2

=item * name - a string

=item * size - an integer

=item * color - a string or undef

=item * user information - a very short string descibing  the range

=back

Any of the three first elements can be replaced by a subroutine reference. See L<Dynamic range definition> below.

You can also declare the ranges in a string. The string use the format used by the I<hdr> command line range dumper
that was installed by this module.

Example:

  hdr -r 'header,12:name,10:xx, 2:yy,2:offset,4:BITMAP,4,bright_yellow,hi:ff,x2b2:fx,b32:f0,b16: \
       field,x8b8:field2, b17:footer,17:something,5'  \
       -col -display_ruler -display_range_size 1 -show_dec_dump 1 -o ver my_data_file

TODO: document string range format

=head3 Coloring

Ranges and ranges names are displayed according to the color field in the range definition. 

The color definition is one of:

=over 2

=item * A user defined color name found in B<COLOR_NAMES> (see L<new>)

=item * An ansi color definition - 'blue on_yellow'

=item * undef - will be repaced by a white color or picked from a cyclic color list (see B<COLOR> in L<new>).

=back

=head3 Linear ranges

For simple data formats, your can put all the your range descriptions in a array:

  my $image_ranges =
	[
	  ['magic cookie', 12, 'red'],
	  ['size', 10, 'yellow'],
	  ['data', 10, 'blue on_yellow'],
	  ['timestamp', 5, 'green'],
	] ;

=head3 Structured Ranges

  my $data_range = # definition to re-use
	[
	  ['data header', 5, 'blue on_yellow'],
	  ['data', 100, 'blue'],
	] ;
			
  my $structured_range = 
	[
	  [
	    ['magic cookie', 12, 'red'],
	    ['padding', 88, 'yellow'],
	    $data_range, 
	  ],
		
	  [
	    ['extra data', 12, undef],
	    [
	      $data_range, 
	      ['footer', 4, 'yellow on_red'],
	    ]
	  ],
	]
	
=head4 Comment ranges

If the size of a range is the string '#', the whole range is considered a comment

  my $range_defintion_with_comments = 
	[
	  ['comment text', '#', 'optional color for meta range'],
	  ['magic cookie', 12, 'red'],
	  ['padding', 88, 'yellow'],
	    
	  [
	    ['another comment', '#'],
	    ['data header', 5, 'blue on_yellow'],
	    ['data', 100, 'blue'],
	  ],
	] ;

=head3 Bitfields

Bitfields can be up to 32 bits long and can overlap each other. Bitfields are applied on the previously defined range.

  hdr -r 'BITMAP,4,bright_yellow:ff,x2b2:fx,3b17:f0,7b13' -col -o ver ~/my_file


In the I<hdr> example above, four bitfields I<ff, fx, f0> are defined. They will be applied on the data defined by the
I<BITMAP> range.



                   .------------.                      .--------------.
                   | data range |                      | data hexdump |
                   '------------'                      '--------------'
                          |                                    |
                          |                                    |
             RANGE_NAME   |   OFFSET   CUMULATI HEX_DUMP       |                                 ASCII_DUMP     
             BITMAP  <----'   00000000 00000000 63 6f 6d 6d <--'                                 comm           
         .-> .ff              02 .. 03          -- -- -- 02 --10----------------------------     .bitfield: ---.
         .-> .fx              03 .. 19          -- 00 36 f6 ---00011011011110110------------     .bitfield: -.6?
         .-> .f0              07 .. 17          -- -- 05 bd -------10110111101--------------     .bitfield: --.?
         |                        ^                   ^                   ^                            ^
         |                        |                   |                   |                            |
      .-----------.     .-------------------.         |       .----------------------.      .---------------------.
      | bitfields |     | start and end bit |         |       | bitfield binary dump |      | bitfield ascci dump |
      '-----------'     '-------------------'         |       '----------------------'      '---------------------'
                                            .-------------------.
                                            | bitfields hexdump |
                                            '-------------------'

The definiton follows the format an optional "x (for offset) + offset" + "b (for bits) + number of bits".

The dump with colors:

=begin html

<pre style ="font-family: monospace; background-color: #000 ;">

<span style='color:#fff;'>RANGE_NAME       OFFSET   CUMULATI HEX_DUMP                                         ASCII_DUMP       </span> 
<span style='color:#ff0;'>BITMAP          </span> <span style='color:#fff;'>00000000</span> <span style='color:#fff;'>00000000</span> <span style='color:#ff0;'>63 6f 6d 6d                                     </span> <span style='color:#ff0;'>comm            </span> 
<span style='color:#0f0;'>.ff             </span> <span style='color:#0f0;'>02 .. 03</span> <span style='color:#0f0;'>        </span> <span style='color:#0f0;'>-- -- -- 02 --10----------------------------    </span> <span style='color:#0f0;'>.bitfield: ---. </span> 
<span style='color:#ff0;'>.fx             </span> <span style='color:#ff0;'>03 .. 19</span> <span style='color:#ff0;'>        </span> <span style='color:#ff0;'>-- 00 36 f6 ---00011011011110110------------    </span> <span style='color:#ff0;'>.bitfield: -.6� </span> 
<span style='color:#f0f;'>.f0             </span> <span style='color:#f0f;'>07 .. 19</span> <span style='color:#f0f;'>        </span> <span style='color:#f0f;'>-- -- 16 f6 -------1011011110110------------    </span> <span style='color:#f0f;'>.bitfield: --.� </span> 

</pre>

=end html

=head3 Dynamic range definition

The whole range can be replaced by a subroutine reference or elements of the range can be replaced by
a subroutine definition.

  my $dynamic_range =
	[
	  [\&name, \&size, \&color ],
	  [\&define_range] # returns a range definition
	] ;

=head4 'name' sub ref

  sub cloth_size
  {
  my ($data, $offset, $size) = @_ ;
  my %types = (O => 'S', 1 => 'M', 2 => 'L',) ;
  return 'size:' . ($types{$data} // '?') ;
  }
  
  $hdr->dump([\&cloth_size, 1, 'yellow'], $data) ;
  
=head4 'size' sub ref

  sub cloth_size
  {
  my ($data, $offset, $size) = @_ ;
  return unpack "a", $data ;
  }
  
  $hdr->dump(['data', \&get_size, 'yellow'], $data) ;
  
=head4 'color' sub ref

  my $flip_flop = 1 ;
  my @colors = ('green', 'red') ;
  
  sub alternate_color {$flip_flop ^= 1 ; return $colors[$flip_flop] }
  
  $hdr->dump(['data', 100, \&alternate_color], $data) ;

=head4 'range' sub ref

  sub whole_range(['whole range', 5, 'on_yellow']}
  
  $hdr->dump([\&whole_range], $data) ; #note this is very different from L<User defined range generator>

=head3  User defined range generator

A subroutine reference can be passed as a range definition. The cubroutine will be called repetitively
till the data is exhausted or the subroutine returns I<undef>.

  sub my_parser 
  	{
  	my ($data, $offset) = @_ ;
  	
  	my $first_byte = unpack ("x$offset C", $data) ;
  	
  	$offset < length($data)
  		?  $first_byte == ord(0)
  			? ['from odd', 5, 'blue on_yellow']
  			: ['from even', 3, 'green']
  		: undef ;
  	}
  
  my $hdr = Data::HexDump::Range->new() ;
  print $hdr->dump(\&my_parser, '01' x 50) ;

=head2 my_parser($data, $offset)

Returns a range description for the next range to dump

I<Arguments> - See L<gather>

=over 2

=item * $data - Binary string - the data passed to the I<dump> method

=item * $offset - Integer - current offset in $data

=back

I<Returns> - 

=over 2

=item * $range - An array reference containing a name, size and color

OR

=item * undef - Done parsing

=back

=cut

=head1 EXAMPLES

See L<HDR.html>

=head1 OTHER IDEAS

- allow pack format as range size
	pack in array context returns the amount of fields processed
	fixed format can be found with a length of unpack

- hook with Convert::Binary::C to automatically create ranges

=head1 SUBROUTINES/METHODS

Subroutines prefixed with B<[P]> are not part of the public API and shall not be used directly.

=cut


#-------------------------------------------------------------------------------

Readonly my $RANGE_DEFINITON_FIELDS => 4 ;

Readonly my $NEW_ARGUMENTS => 	
	[
	qw(
	NAME INTERACTION VERBOSE
	
	FORMAT 
	COLOR 
	OFFSET_FORMAT 
	DATA_WIDTH 
	DISPLAY_COLUMN_NAMES
	DISPLAY_RULER
	DISPLAY_OFFSET DISPLAY_CUMULATIVE_OFFSET
	DISPLAY_ZERO_SIZE_RANGE_WARNING
	DISPLAY_ZERO_SIZE_RANGE 
	DISPLAY_RANGE_NAME
	MAXIMUM_RANGE_NAME_SIZE
	DISPLAY_RANGE_SIZE
	DISPLAY_ASCII_DUMP
	DISPLAY_HEX_DUMP
	DISPLAY_DEC_DUMP
	DISPLAY_USER_INFORMATION
	COLOR_NAMES 
	ORIENTATION 
	)] ;

sub new
{

=head2 new(NAMED_ARGUMENTS)

Create a Data::HexDump::Range object.

  my $hdr = Data::HexDump::Range->new() ; # use default setup
  
  my $hdr = Data::HexDump::Range->new
		(
		FORMAT => 'ANSI'|'ASCII'|'HTML',
		COLOR => 'bw' | 'cycle',
		OFFSET_FORMAT => 'hex' | 'dec',
		DATA_WIDTH => 16 | 20 | ... ,
		DISPLAY_RANGE_NAME => 1 ,
		MAXIMUM_RANGE_NAME_SIZE => 16,
		DISPLAY_COLUMN_NAMES => 0,
		DISPLAY_RULER => 0,
		DISPLAY_OFFSET  => 1 ,
		DISPLAY_CUMULATIVE_OFFSET  => 1 ,
		DISPLAY_ZERO_SIZE_RANGE_WARNING => 1,
		DISPLAY_ZERO_SIZE_RANGE => 1,
		DISPLAY_RANGE_SIZE => 1,
		DISPLAY_ASCII_DUMP => 1 ,
		DISPLAY_HEX_DUMP => 1,
		DISPLAY_DEC_DUMP => 1,
		COLOR_NAMES => {},
		ORIENTATION => 'horizontal',
		) ;

I<Arguments> - All arguments are optional. Default values are listed below.

=over 2 

=item * NAME - String - Name of the Data::HexDump::Range object, set to 'Anonymous' by default

=item * INTERACTION - Hash reference - Set of subs that are used to display information to the user

Useful if you use Data::HexDump::Range in an application without terminal.

=item * VERBOSE - Boolean - Display information about the creation of the object. Default is I<false>

=item * FORMAT - String - format of the dump string generated by Data::HexDump::Range.

Default is B<ANSI> which allows for colors. Other formats are 'ASCII' and 'HTML'.

=item * COLOR - String 'bw' or 'cycle'.

Ranges for which no color has been defined, in 'ANSI' or 'HTML' format mode, will be rendered in
black and white or with a color picked from a cyclic color list. Default is 'bw'.

=item * OFFSET_FORMAT - String - 'hex' or 'dec'

If set to 'hex', the offset will be displayed in base 16. When set to 'dec' the offset is displayed
in base 10. Default is 'hex'.

=item * DATA_WIDTH - Integer - Number of elements displayed per line. Default is 16.

=item * DISPLAY_RANGE_NAME - Boolean - If set, range names are displayed in the dump.

=item * MAXIMUM_RANGE_NAME_SIZE - Integer - maximum size of a range name (horizontal mode). Default size is 16.

=item * DISPLAY_COLUMN_NAMES - Boolean -  If set, the column names are displayed. Default I<false>

=item * DISPLAY_RULER - Boolean - if set, a ruler is displayed above the dump, Default is I<false>

=item * DISPLAY_OFFSET - Boolean - If set, the offset column is displayed. Default I<true>

=item * DISPLAY_CUMULATIVE_OFFSET - Boolean - If set, the cumulative offset column is displayed in 'vertical' rendering mode. Default is I<true>

=item * DISPLAY_ZERO_SIZE_RANGE - Boolean - if set, ranges that do not consume data are displayed. default is I<true> 

=item * DISPLAY_ZERO_SIZE_RANGE_WARNING - Boolean - if set, a warning is emitted if ranges that do not consume data. Default is I<true> 

=item * DISPLAY_RANGE_SIZE - Bolean - if set the range size is prepended to the name. Default I<false>

=item * DISPLAY_ASCII_DUMP - Boolean - If set, the ASCII representation of the binary data is displayed. Default is I<true>

=item * DISPLAY_HEX_DUMP - Boolean - If set, the hexadecimal dump column is displayed. Default is I<true>

=item * DISPLAY_DEC_DUMP - Boolean - If set, the decimall dump column is displayed. Default is I<false>

=item * COLOR_NAMES - A hash reference

  {
  ANSI =>
	{
	header => 'yellow on_blue',
	data => 'yellow on_black',
	},
	
  HTML =>
	{
	header => 'FFFF00 0000FF',
	data => 'FFFF00 000000',
	},
  }


=item * ORIENTATION - String - 'vertical' or 'horizontal' (the default).

=back

I<Returns> - Nothing

I<Exceptions> - Dies if an unsupported option is passed.

=cut

my ($invocant, @setup_data) = @_ ;

my $class = ref($invocant) || $invocant ;
confess 'Invalid constructor call!' unless defined $class ;

my $object = {} ;

my ($package, $file_name, $line) = caller() ;
bless $object, $class ;

$object->Setup($package, $file_name, $line, @setup_data) ;

return($object) ;
}

#-------------------------------------------------------------------------------

sub Setup
{

=head2 [P] Setup(...)

Helper sub called by new. This is a private sub.

=cut

my ($self, $package, $file_name, $line, @setup_data) = @_ ;

if (@setup_data % 2)
	{
	croak "Invalid number of argument '$file_name, $line'!" ;
	}

$self->{INTERACTION}{INFO} ||= sub {print @_} ;
$self->{INTERACTION}{WARN} ||= \&Carp::carp ;
$self->{INTERACTION}{DIE}  ||= \&Carp::croak ;
$self->{NAME} = 'Anonymous';
$self->{FILE} = $file_name ;
$self->{LINE} = $line ;

$self->CheckOptionNames($NEW_ARGUMENTS, @setup_data) ;

%{$self} = 
	(
	%{$self},
	
	VERBOSE => 0,

	FORMAT => 'ANSI',
	COLOR => 'bw',
	COLORS =>
		{
		ASCII => [],
		ANSI => ['white', 'green', 'bright_yellow','cyan', 'red' ],
		HTML => ['white', 'green', 'bright_yellow','cyan', 'red' ],
		},
		
	OFFSET_FORMAT => 'hex',
	DATA_WIDTH => 16,
	
	DISPLAY_ZERO_SIZE_RANGE_WARNING => 1,
	DISPLAY_ZERO_SIZE_RANGE => 1,
	
	DISPLAY_RANGE_NAME => 1,
	MAXIMUM_RANGE_NAME_SIZE => 16,
	DISPLAY_RANGE_SIZE => 1,
	
	DISPLAY_COLUMN_NAMES  => 0 ,
	DISPLAY_RULER => 0,
	
	DISPLAY_OFFSET => 1,
	DISPLAY_CUMULATIVE_OFFSET => 1,
	DISPLAY_HEX_DUMP => 1,
	DISPLAY_DEC_DUMP => 0,
	DISPLAY_ASCII_DUMP => 1,
	DISPLAY_USER_INFORMATION => 0,

	COLOR_NAMES => 
		{
		HTML =>
			{
			white => "style='color:#fff;'",
			green => "style='color:#0f0;'",
			bright_yellow => "style='color:#ff0;'",
			yellow => "style='color:#ff0;'",
			cyan => "style='color:#f0f;'",
			red => "style='color:#f00;'",
			},
		},

	ORIENTATION => 'horizontal',
	
	GATHERED => [],
	@setup_data,
	) ;

my $location = "$self->{FILE}:$self->{LINE}" ;

if($self->{VERBOSE})
	{
	$self->{INTERACTION}{INFO}('Creating ' . ref($self) . " '$self->{NAME}' at $location.\n") ;
	}

$self->{OFFSET_FORMAT} = $self->{OFFSET_FORMAT} =~ /^hex/ ? "%08x" : "%010d" ;
$self->{MAXIMUM_RANGE_NAME_SIZE} = 2 if$self->{MAXIMUM_RANGE_NAME_SIZE} <= 2 ;

$self->{FIELDS_TO_DISPLAY} =  $self->{ORIENTATION} =~ /^hor/
	? [qw(OFFSET HEX_DUMP DEC_DUMP ASCII_DUMP RANGE_NAME)]
	: [qw(RANGE_NAME OFFSET CUMULATIVE_OFFSET HEX_DUMP DEC_DUMP ASCII_DUMP USER_INFORMATION)] ;


return(1) ;
}

#-------------------------------------------------------------------------------

sub CheckOptionNames
{

=head2 [P] CheckOptionNames(...)

Verifies the named options passed to the members of this class. Calls B<{INTERACTION}{DIE}> in case
of error. 

=cut

my ($self, $valid_options, @options) = @_ ;

if (@options % 2)
	{
	$self->{INTERACTION}{DIE}->('Invalid number of argument!') ;
	}

if('HASH' eq ref $valid_options)
	{
	# OK
	}
elsif('ARRAY' eq ref $valid_options)
	{
	$valid_options = { map{$_ => 1} @{$valid_options} } ;
	}
else
	{
	$self->{INTERACTION}{DIE}->("Invalid argument '$valid_options'!") ;
	}

my %options = @options ;

for my $option_name (keys %options)
	{
	unless(exists $valid_options->{$option_name})
		{
		$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid Option '$option_name' at '$self->{FILE}:$self->{LINE}'!")  ;
		}
	}

if
	(
	   (defined $options{FILE} && ! defined $options{LINE})
	|| (!defined $options{FILE} && defined $options{LINE})
	)
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: Incomplete option FILE::LINE!") ;
	}

return(1) ;
}

#-------------------------------------------------------------------------------

sub gather
{

=head2 gather($range_description, $data, $offset, $size)

Dump the data, up to $size, according to the description. The data dump is kept in the object so you can
merge multiple gathered dumps and get a single rendering.

  $hdr->gather($range_description, $data, $offset, $size)
  $hdr->gather($range_description, $more_data)
  
  print $hdr->dump_gathered() ;

I<Arguments>

=over 2 

=item * $range_description - See L<Range definition>
  
=item * $data - A string - binary data to dump

=item * $offset - dump data from offset

=over 2

=item * undef - start from first byte

=back

=item * $size - amount of data to dump

=over 2

=item * undef - use range description

=item * CONSUME_ALL_DATA - apply range descritption till all data is consumed

=back

=back

I<Returns> - An integer - the number of processed bytes

I<Exceptions> - See L<_gather>

=cut

my ($self, $range, $data, $offset, $size) = @_ ;

my ($gathered_data, $used_data) = $self->_gather($self->{GATHERED}, $range, $data, $offset, $size) ;

return $used_data ;
}

#-------------------------------------------------------------------------------

sub dump_gathered
{

=head2 dump_gathered()

Returns the dump string for the gathered data.

  $hdr->gather($range_description, $data, $size)
  $hdr->gather($range_description, $data, $size)
  
  print $hdr->dump_gathered() ;

I<Arguments> - None

I<Returns> - A string - the binary data formated according to the rnage descriptions

I<Exceptions> - None

=cut

my ($self) = @_ ;

my $split_data = $self->split($self->{GATHERED}) ;

$self->add_information($split_data) ;

return $self->format($split_data) ;
}

#-------------------------------------------------------------------------------

sub dump
{

=head2 dump($range_description, $data, $offset, $size)

Dump the data, up to $size, according to the description

I<Arguments> - See L<gather>

I<Returns> - A string -  the formated dump

I<Exceptions> - dies if the range description is invalid

=cut

my ($self, $range_description, $data, $offset, $size) = @_ ;

return unless defined wantarray ;

my ($gathered_data, $used_data) = $self->_gather(undef, $range_description, $data, $offset, $size) ;

my $split_data = $self->split($gathered_data) ;

$self->add_information($split_data) ;

return $self->format($split_data) ;
}

#-------------------------------------------------------------------------------

sub add_information
{

=head2 [P] add_information($split_data)

Add information, according to the options passed to the constructor, to the internal data.

I<Arguments> - See L<gather>

=over 2

=item * $split_data - data returned by _gather()

=back

I<Returns> - Nothing

I<Exceptions> - None

=cut

my ($self, $split_data) = @_ ;

my @information ;

if($self->{DISPLAY_COLUMN_NAMES})
	{
	my $information = '' ;
	
	for my $field_name (@{$self->{FIELDS_TO_DISPLAY}})
		{
		if(exists $split_data->[0]{$field_name})
			{
			my $length = 0 ;
			
			for (@{$split_data->[0]{$field_name}})
				{
				$length += length($_->{$field_name}) ;
				}
				
			$information .= sprintf "%-${length}.${length}s ", $field_name
			}
		}
		
	push @information,
		{
		INFORMATION => [ {INFORMATION => $information} ], 
		NEW_LINE => 1,
		} ;
	}

if($self->{DISPLAY_RULER})
	{
	my $information = '' ;
	
	for my $field_name (@{$self->{FIELDS_TO_DISPLAY}})
		{
		if(exists $split_data->[0]{$field_name})
			{
			my $length = 0 ;
			
			for (@{$split_data->[0]{$field_name}})
				{
				$length += length($_->{$field_name}) ;
				}
				
			for ($field_name)
				{
				/HEX_DUMP/ and do
					{
					$information .= join '', map {sprintf '%x  ' , $ _ % 16} (0 .. $self->{DATA_WIDTH} - 1) ;
					$information .= ' ' ;
					last ;
					} ;
					
				/DEC_DUMP/ and do
					{
					$information .= join '', map {sprintf '%d   ' , $ _ % 10} (0 .. $self->{DATA_WIDTH} - 1) ;
					$information .= ' ' ;
					last ;
					} ;
					
				/ASCII_DUMP/ and do
					{
					$information .= join '', map {$ _ % 10} (0 .. $self->{DATA_WIDTH} - 1) ;
					$information .= ' ' ;
					last ;
					} ;
					
				$information .= ' ' x $length  . ' ' ;
				}
			}
		}
		
	push @information,
		{
		RULER => [ {RULER=> $information} ], 
		NEW_LINE => 1,
		} ;
	}
	
unshift @{$split_data}, @information ;

}

#-------------------------------------------------------------------------------

sub get_dump_and_consumed_data_size
{

=head2 get_dump_and_consumed_data_size($range_description, $data, $offset, $size)

Dump the data, from $offset up to $size, according to the $range_description

I<Arguments> - See L<gather>

I<Returns> - 

=over 2

=item *  A string -  the formated dump

=item * An integer - the number of bytes consumed by the range specification

=back 

I<Exceptions> - dies if the range description is invalid

=cut

my ($self) = shift ;

return unless defined wantarray ;

my ($gathered_data, $used_data) = $self->_gather(undef, @_) ;

my $dump =$self->format($self->split($gathered_data)) ;

return  $dump, $used_data ;
}

#-------------------------------------------------------------------------------

sub reset
{

=head2 reset()

Clear the gathered dump 

I<Arguments> - None

I<Returns> - Nothing

I<Exceptions> - None

=cut

my ($self) = @_ ;

$self->{GATHERED} = [] ;

return ;
}

#-------------------------------------------------------------------------------

sub _gather
{

=head2 [P] _gather($range_description, $data, $offset, $size)

Creates an internal data structure from the data to dump.

  $hdr->_gather($container, $range_description, $data, $size)

I<Arguments> - See L<gather>

=over 2 

=item * $container - an array reference or undef - where the gathered data 

=item * $range_description - See L<gather> 

=item * $data - See L<gather>

=item * $offset - See L<gather>

=item * $size - See L<gather>

=back

I<Returns> - 

=over 2 

=item * $container - the gathered data 

=item * $used_data - integer - the location in the data where the dumping ended

=back

I<Exceptions> dies if passed invalid parameters

=cut

my ($self, $collected_data, $range_description, $data, $offset, $size) = @_ ;

my $range_provider ;

if('CODE' eq ref($range_description))
	{
	$range_provider = $range_description ;
	}
else
	{
	my $ranges = $self->create_ranges($range_description) ;
	
	$range_provider = 
		sub
		{
		while(@{$ranges})
			{
			return shift @{$ranges} ;
			}
		}
	}

my $used_data = $offset || 0 ;

if($used_data < 0)
	{
	my $location = "$self->{FILE}:$self->{LINE}" ;
	$self->{INTERACTION}{DIE}("Warning: Invalid negative offset at '$location'.\n")
	}

$size = defined $size ? min($size, length($data) - $used_data) : length($data) - $used_data ;

my $location = "$self->{FILE}:$self->{LINE}" ;
my $skip_ranges = 0 ;

my $last_data = '' ;

while(my $range  = $range_provider->($data, $used_data))
	{
	my ($range_name, $range_size, $range_color, $range_user_information) = @{$range} ;
	my $is_comment = 0 ;
	my $is_bitfield = 0 ;
	
	my $range_size_definition = $range_size ; # needed for comment and bitfield
	
	#~ use Data::TreeDumper ;
	#~ print DumpTree $range ;
	
	my $unpack_format = '#' ;

	if('' eq ref($range_size))
		{
		if('#' eq  $range_size)
			{
			$is_comment++ ;
			$range_size = 0 ;
			$unpack_format = '#' ;
			}
		elsif($range_size =~ 'b')
			{
			$is_bitfield++ ;
			$range_size = 0 ;
			$unpack_format = '#' ;
			}
		elsif(looks_like_number($range_size))
			{
			# OK
			$unpack_format = "x$used_data a$range_size"  ;
			}
		else
			{
			$self->{INTERACTION}{DIE}("Error: size '$range_size' doesn't look like a number in range '$range_name' at '$location'.\n")
			}
		}
	#todo: check it is a sub
	
	my @sub_or_scalar ;
	
	push @sub_or_scalar, ref($range_name) eq 'CODE' ? $range_name->($data, $used_data, $size)  : $range_name ;
	push @sub_or_scalar, ref($range_size) eq 'CODE' ? $range_size->($data, $used_data, $size)  : $range_size ;
	push @sub_or_scalar, ref($range_color) eq 'CODE' ? $range_color->($data, $used_data, $size)  : $range_color;
	
	($range_name, $range_size, $range_color) = @sub_or_scalar ;
	
	if($self->{DISPLAY_RANGE_SIZE})
		{
		unless($is_comment || $is_bitfield)
			{
			$range_name = $range_size . ':' . $range_name ;
			}
		}
		
	#todo: merge bith tests qbove qnd below
	#
	if(!$is_comment && ! $is_bitfield)
		{
		if($range_size == 0 && $self->{DISPLAY_ZERO_SIZE_RANGE_WARNING}) 
			{
			$self->{INTERACTION}{WARN}("Warning: range '$range_name' requires zero bytes.\n") ;
			}
		}
		
	if($range_size > $size)
		{
		my $location = "$self->{FILE}:$self->{LINE}" ;
		$self->{INTERACTION}{WARN}("Warning: not enough data for range '$range_name', $range_size needed but only $size available.\n") ;
		
		$range_name = '-' . ($range_size - $size)  . ':' . $range_name ;
		
		$range_size = $size;
		$skip_ranges++ ;
		}

	$last_data = unpack($unpack_format, $data) unless $unpack_format eq '#' ; # get out data from the previous range for bitfield

	push @{$collected_data}, 		
		{
		NAME => $range_name, 
		COLOR => $range_color,
		OFFSET => $used_data,
		DATA =>  $last_data,
		IS_BITFIELD => $is_bitfield ? $range_size_definition : 0,
		USER_INFORMATION => $range_user_information,
		} ;
	
	$used_data += $range_size ;
	$size -= $range_size ;
	
	last if $skip_ranges ;
	}

return $collected_data, $used_data ;
}

#-------------------------------------------------------------------------------

sub create_ranges
{

=head2 [P] create_ranges($range_description)

transforms the user supplied ranges into an internal format

I<Arguments> - 

=over 2 

=item * $range_description - See L<gather> 

=back

I<Returns> - Nothing

I<Exceptions> - Croaks with an error messge if the input data is invalid

=cut

my ($self, $range_description) = @_ ;

return $self->create_ranges_from_array_ref($range_description) if 'ARRAY' eq ref($range_description) ;
return $self->create_ranges_from_string($range_description) if '' eq ref($range_description) ;

}

#-------------------------------------------------------------------------------

sub create_ranges_from_string
{

=head2 [P] create_ranges_from_string($range_description)

transforms the user supplied ranges into an internal format

I<Arguments> - 

=over 2 

=item * $range_description - A string - See L<gather> 

=back

I<Returns> - Nothing

I<Exceptions> - Croaks with an error messge if the input data is invalid

=cut

my ($self, $range_description) = @_ ;

# 'comment,#:name,size,color:name,size:name,size,color'

my @ranges = 
	map
	{
		[ map {s/^\s+// ; s/\s+$//; $_} split /,/ ] ;
	} split /:/, $range_description ;

my @flattened = $self->flatten(\@ranges) ;
@ranges = () ;

while(@flattened)
	{
	push @ranges, [splice(@flattened, 0, $RANGE_DEFINITON_FIELDS)] ;
	}

return \@ranges ;
}


sub create_ranges_from_array_ref
{

=head2 [P] create_ranges_from_array_ref($range_description)

transforms the user supplied ranges into an internal format

I<Arguments> - 

=over 2 

=item * $range_description - An array reference - See L<gather> 

=back

I<Returns> - Nothing

I<Exceptions> - Croaks with an error messge if the input data is invalid

=cut

my ($self, $range_description) = @_ ;

my @flattened = $self->flatten($range_description) ;

my @ranges ;

while(@flattened)
	{
	push @ranges, [splice(@flattened, 0, $RANGE_DEFINITON_FIELDS)] ;
	}
	
return \@ranges ;
}

#-------------------------------------------------------------------------------

sub flatten 
{ 
	
=head2 [P] flatten($range_description)

transforms the user supplied ranges into an internal format

I<Arguments> - 

=over 2 

=item * $range_description - See L<gather> 

=back

I<Returns> - Nothing

I<Exceptions> - Croaks with an error messge if the input data is invalid

=cut

my $self = shift ;

map 
	{
	my  $description = $_ ;
	
	if(ref($description) eq 'ARRAY')
		{
		if(all {'' eq ref($_) || 'CODE' eq ref($_) } @{$description} ) # todo: handle code refs
			{
			my $location = "$self->{FILE}:$self->{LINE}" ;
			
			# a simple  range description, color is  optional
			if(@{$description} == 0)
				{
				$self->{INTERACTION}{DIE}->
					(
					"Error: too few elements in range description [" 
					. join(', ', map {defined $_ ? $_ : 'undef'} @{$description})  
					. "] at '$location'." 
					) ;
				}
			elsif(@{$description} == 1)
				{
				if('' eq ref($description->[0]))
					{
					$self->{INTERACTION}{DIE}->
						(
						"Error: too few elements in range description [" 
						. join(', ', map {defined $_ ? $_ : 'undef'} @{$description})  
						. "] at '$location'." 
						) ;
					}
				else
					{
					@{$description} = $description->[0]() ;
					
					$self->{INTERACTION}{DIE}->
						(
						"Error: single sub range definition returned ["
						. join(', ', map {defined $_ ? $_ : 'undef'}@{$description})  
						. "] at '$location'." 
						) 
						unless (@{$description} == 3) ;
					}
				}
			elsif(@{$description} == 2)
		        	{
				push @{$description}, undef, undef ;
				}
			elsif(@{$description} == 3)
				{
				push @{$description}, undef ;
				}
			elsif(@{$description} > $RANGE_DEFINITON_FIELDS)
				{
				$self->{INTERACTION}{DIE}->
					(
					"Error: too many elements in range description [" 
					. join(', ', map {defined $_ ? $_ : 'undef'} @{$description}) 
					. "] at '$location'." 
					) ;
				}
				
			@{$description} ;
			}
		else
			{
			$self->flatten(@{$description}) ;
			}
		}
	else
		{
		$description
		}
	} @_ 
}

#-------------------------------------------------------------------------------

sub split
{

=head2 [P] split($collected_data)

Split the collected data into lines

I<Arguments> - 

=over 2 

=item * $container - Collected data

=back

I<Returns> - Nothing

I<Exceptions>

=cut

my ($self, $collected_data) = @_ ;

#~ use Data::TreeDumper ;
#~ print DumpTree $collected_data ;

my @lines ;
my $line = {} ;
my $current_offset = 0 ;

my $room_left = $self->{DATA_WIDTH} ;
my $total_dumped_data = 0 ;
my $max_range_name_size = $self->{MAXIMUM_RANGE_NAME_SIZE} ;

my @found_bitfields ;

for my $data (@{$collected_data})
	{
	my $data_length = defined $data->{DATA} ? length($data->{DATA}) : 0 ;
	my $is_comment = ! defined $data->{DATA} ;
	my ($start_quote, $end_quote) = $is_comment ? ('"', '"') : ('<', '>') ;
	
	$data->{COLOR} = $self->get_default_color()  unless defined $data->{COLOR} ;
	
	if($self->{ORIENTATION} =~ /^hor/)
		{
		my $last_data = $data == $collected_data->[-1] ? 1 : 0 ;
		my $dumped_data = 0 ;
		my $data_length = defined $data->{DATA} ? length($data->{DATA}) : 0 ;
		
		if(0 == $data_length && $self->{DISPLAY_ZERO_SIZE_RANGE} && $self->{DISPLAY_RANGE_NAME})
			{
			my $name_size_quoted = $max_range_name_size - 2 ;
			$name_size_quoted =  2 if $name_size_quoted < 2 ;
			
			push @{$line->{RANGE_NAME}},
				{
				'RANGE_NAME' => $start_quote . sprintf("%.${name_size_quoted}s", $data->{NAME}) . $end_quote,
				'RANGE_NAME_COLOR' => $data->{COLOR},
				},
				{
				'RANGE_NAME_COLOR' => undef,
				'RANGE_NAME' => ', ',
				} ;
			}
		
		while ($dumped_data < $data_length)
			{
			my $size_to_dump = min($room_left, length($data->{DATA}) - $dumped_data) ;
			$room_left -= $size_to_dump ;
			
			for my  $field_type 
				(
				['OFFSET', sub {exists $line->{OFFSET} ? '' : sprintf $self->{OFFSET_FORMAT}, $current_offset}, undef, 0],
				['HEX_DUMP', sub {sprintf '%02x ' x $size_to_dump, @_}, $data->{COLOR}, 3],
				['DEC_DUMP', sub {sprintf '%03u ' x $size_to_dump, @_}, $data->{COLOR}, 4],
				['ASCII_DUMP', sub {sprintf '%c' x $size_to_dump, map{$_ < 30 ? ord('.') : $_ } @_}, $data->{COLOR}, 1],
				['RANGE_NAME',sub {sprintf "%.${max_range_name_size}s", $data->{NAME}}, $data->{COLOR}, 0],
				['RANGE_NAME', sub {', '}, undef, 0],
				)
				{
				my ($field_name, $field_data_formater, $color, $pad_size) = @{$field_type} ;
				
				if($self->{"DISPLAY_$field_name"})
					{
					#todo: move unpack out of the loop
					#todo: pass object as argument to sub
					my $field_text = $field_data_formater->(unpack("x$dumped_data C$size_to_dump", $data->{DATA})) ;
					
					my $pad = $last_data 
							? $pad_size 
								? ' ' x ($room_left * $pad_size) 
								: '' 
							: '' ;
							
					push @{$line->{$field_name}},
						{
						$field_name . '_COLOR' => $color,
						$field_name => $field_text . $pad,
						} ;
					}
				}
				
			$dumped_data += $size_to_dump ;
			$current_offset += $self->{DATA_WIDTH} ;
			
			if($data->{IS_BITFIELD} && ! $data->{BITFIELD_DISPLAYED})
				{
				push @found_bitfields, $self->get_bitfield_lines($data) ;
				$data->{BITFIELD_DISPLAYED}++ ;
				}
			
			if($room_left == 0 || $last_data)
				{
				$line->{NEW_LINE}++ ;
				push @lines, $line ;
				
				if(@found_bitfields)
					{
					push @lines, {NEW_LINE => 1}, @found_bitfields, {NEW_LINE => 1} ;
					@found_bitfields = () ;
					}
					
				$line = {} ;
				$room_left = $self->{DATA_WIDTH} ;
				}
			}
		}
	else
		{ 
		# vertical mode
			
		$line = {} ;

		my $dumped_data = 0 ;
		my $current_range = '' ;
		
		if(0 == $data_length && $self->{DISPLAY_ZERO_SIZE_RANGE} && $self->{DISPLAY_RANGE_NAME})
			{
			push @{$line->{RANGE_NAME}},
				{
				'RANGE_NAME_COLOR' => $data->{COLOR},
				'RANGE_NAME' => "$start_quote$data->{NAME}$end_quote",
				} ;
				
			$line->{NEW_LINE} ++ ;
			push @lines, $line ;
			$line = {};
			}
			
		while ($dumped_data < $data_length)
			{ 
			last if($data->{IS_BITFIELD}) ;

			my $size_to_dump = min($self->{DATA_WIDTH}, length($data->{DATA}) - $dumped_data) ;
			my @range_data = unpack("x$dumped_data C$size_to_dump", $data->{DATA}) ;
			
			for my  $field_type 
				(
				['RANGE_NAME',  sub {sprintf "%-${max_range_name_size}.${max_range_name_size}s", $data->{NAME} ; }, $data->{COLOR}, $max_range_name_size] ,
				['OFFSET', sub {sprintf $self->{OFFSET_FORMAT}, $total_dumped_data ;}, undef, 8],
				['CUMULATIVE_OFFSET', sub {sprintf $self->{OFFSET_FORMAT}, $dumped_data}, undef, 8],
				['HEX_DUMP', sub {sprintf '%02x ' x $size_to_dump, @{$_[0]}}, $data->{COLOR}, 3 * $self->{DATA_WIDTH}],
				['DEC_DUMP', sub {sprintf '%03u ' x $size_to_dump, @{ $_[0] }}, $data->{COLOR}, 4 * $self->{DATA_WIDTH}],
				['ASCII_DUMP', sub {sprintf '%c' x $size_to_dump, map{$_ < 30 ? ord('.') : $_ } @{$_[0]}}, $data->{COLOR}, $self->{DATA_WIDTH}],
                                ['USER_INFORMATION', sub { sprintf '%-20.20s', $data->{USER_INFORMATION} || ''}, $data->{COLOR}, 20],
				)
				{
				
				my ($field_name, $field_data_formater, $color, $field_text_size) = @{$field_type} ;
				
				if($self->{"DISPLAY_$field_name"})
					{
					my $field_text = $field_data_formater->(\@range_data) ;
					my $pad = ' ' x ($field_text_size -  length($field_text)) ;
					
					push @{$line->{$field_name}},
						{
						$field_name . '_COLOR' => $color,
						$field_name =>  $field_text .  $pad,
						} ;
					}
				}
				
			$dumped_data += $size_to_dump ;
			$total_dumped_data += $size_to_dump ;
			
			$line->{NEW_LINE} ++ ;
			push @lines, $line ;
			$line = {};
			}
			
		push @lines, $self->get_bitfield_lines($data) if($data->{IS_BITFIELD}) ;
		}
	}

return \@lines ;
}

sub get_bitfield_lines
{

my ($self, $data) = @_ ;

my $max_range_name_size = $self->{MAXIMUM_RANGE_NAME_SIZE} ;

my @lines ;

for my $bitfield_description ($data)
	{
	#todo: handle 'x' outside of string in unpack
	#todo: handle bitfield without data
	
	#~ my @bitfield_data = unpack("$bitfield_description->{IS_BITFIELD}", $bitfield_description->{DATA}) ;

	my ($offset, $size) = $bitfield_description->{IS_BITFIELD} =~ m/x?(.*)b(.*)/ ;

	$offset ||= 0 ;
	$size ||= 1 ;

	my $line = {};

	for my  $field_type 
		(
		['RANGE_NAME',  sub {sprintf "%-${max_range_name_size}.${max_range_name_size}s", '.' . $_[0]->{NAME} ; }, undef, $max_range_name_size ] ,
		['OFFSET', sub {sprintf '%02u .. %02u', $offset, ($offset + $size) - 1}, undef, 8],
		['CUMULATIVE_OFFSET', sub {''}, undef, 8],
		['HEX_DUMP', 
			sub 
			{
			my @binary = split '', unpack("B*",  $_[0]->{DATA}) ;
			splice(@binary, 0, $offset) ;
			splice(@binary, $size) ;
			my $binary = join('', @binary) ;
			
			my $value = unpack("N", pack("B32", substr("0" x 32 . $binary, -32)));

			my $binary_dashed = '-' x $offset . $binary . '-' x (32 - ($size + $offset)) ;
			my $bytes = $size > 24 ? 4 : $size > 16 ? 3 : $size > 8 ? 2 : 1 ;
			
			my @bytes = unpack("(H2)*", pack("B32", substr("0" x 32 . $binary, -32)));
			
			my $number_of_bytes = @binary > 24 ? 4 : @binary > 16 ? 3 : @binary > 8 ? 2 : 1 ;
			splice @bytes, 0 , (4 - $number_of_bytes), map {'--'} 1 .. (4 - $number_of_bytes) ;
			
			join(' ', @bytes) . ' ' . $binary_dashed;
			},
			
			undef, 3 * $self->{DATA_WIDTH}],
		['DEC_DUMP', 
			sub 
			{
			my @binary = split '', unpack("B*",  $_[0]->{DATA}) ;
			splice(@binary, 0, $offset) ;
			splice(@binary, $size) ;
			my $binary = join('', @binary) ;
			my $value = unpack("N", pack("B32", substr("0" x 32 . $binary, -32)));
			
			my @values = map {sprintf '%03u', $_} unpack("W*", pack("B32", substr("0" x 32 . $binary, -32)));
			
			my $number_of_bytes = @binary > 24 ? 4 : @binary > 16 ? 3 : @binary > 8 ? 2 : 1 ;
			splice @values, 0 , (4 - $number_of_bytes), map {'---'} 1 .. (4 - $number_of_bytes) ;
			
			join(' ',  @values) . ' ' . "value: $value"  ;
			},
			
			$bitfield_description->{COLOR}, 4 * $self->{DATA_WIDTH}],
			
		['ASCII_DUMP',
			sub 
			{
			my @binary = split '', unpack("B*",  $_[0]->{DATA}) ;
			splice(@binary, 0, $offset) ;
			splice(@binary, $size) ;
			my $binary = join('', @binary) ;
			
			my @chars = map{$_ < 30 ? '.' : chr($_) } unpack("C*", pack("B32", substr("0" x 32 . $binary, -32)));
			
			my $number_of_bytes = @binary > 24 ? 4 : @binary > 16 ? 3 : @binary > 8 ? 2 : 1 ;
			splice @chars, 0 , (4 - $number_of_bytes), map {'-'} 1 .. (4 - $number_of_bytes) ;
			
			'.bitfield: '.  join('',  @chars) 
			},

			undef, $self->{DATA_WIDTH}],
		)
		{
		my ($field_name, $field_data_formater, $color, $field_text_size) = @{$field_type} ;
		
		$color = $bitfield_description->{COLOR} ;
		
		if($self->{"DISPLAY_$field_name"})
			{
			my $field_text = $field_data_formater->($bitfield_description) ;
			my $pad_size = $field_text_size -  length($field_text) ;
			
			push @{$line->{$field_name}},
				{
				$field_name . '_COLOR' => $color,
				$field_name =>  $field_text . ' ' x $pad_size,
				} ;
				
			}
		}
	
	$line->{NEW_LINE} ++ ;
	push @lines, $line ;
	}
	
return @lines ;
}
#-------------------------------------------------------------------------------

my $current_color_index = 0 ;

sub get_default_color
{

=head2 [P] get_default_color()

Returns a color to use with a range that has none

  my $default_color = $self->get_default_color() ;

I<Arguments> - None

I<Returns> - A string - a color according to the COLOR option and FORMAT

I<Exceptions> - None

=cut

my ($self) = @_ ;

my $default_color ;

if($self->{COLOR} eq 'bw')
	{
	$default_color = $self->{COLORS}{$self->{FORMAT}}[0] ;
	}
else
	{
	$current_color_index++ ;
	$current_color_index = 0 if $current_color_index >= @{$self->{COLORS}{$self->{FORMAT}}} ;
	
	$default_color = $self->{COLORS}{$self->{FORMAT}}[$current_color_index] ;
	}
	
return $default_color ;
}

sub format
{
	
=head2 [P] format($line_data)

Transform the line data into ANSI, ASCII or HTML

I<Arguments> -

=over 2 

=item * \%line_data - See L<gather> 

=back

I<Returns> - A dump in ANSI, ASCII or HTML.

=cut

my ($self, $line_data) = @_ ;

#~ use Data::TreeDumper ;
#~ print DumpTree $line_data ;

my $formated = '' ;

my @fields = @{$self->{FIELDS_TO_DISPLAY}} ;
unshift @fields, 'INFORMATION', 'RULER' ;


for ($self->{FORMAT})
	{
	/ASCII/ || /ANSI/ and do
		{
		my $colorizer = /ASCII/ ? sub {$_[0]} : \&colored ;
		
		for my $line (@{$line_data})
			{
			for my $field (@fields)
				{
				if(exists $line->{$field})
					{
					for my $range (@{$line->{$field}})
						{
						my $user_color = (defined $self->{COLOR_NAMES} &&  defined $range->{"${field}_COLOR"})
										? $self->{COLOR_NAMES} {$self->{FORMAT}}{$range->{"${field}_COLOR"}}  ||  $range->{"${field}_COLOR"}
										: $range->{"${field}_COLOR"} ;
						
						if(defined $user_color && $user_color ne '')
							{
							$formated .= $colorizer->($range->{$field}, $user_color) ;
							}
						else
							{
							$formated .= $range->{$field} ;
							}
						}
						
					$formated .= ' '
					}
				}
				
			$formated .= "\n" if $line->{NEW_LINE} ;
			}
		} ;
		
	/HTML/ and do
		{
		$formated = <<'EOH' ;
<pre style ="font-family: monospace; background-color: #000 ;">

EOH
		for my $line (@{$line_data})
			{
			for my $field (@fields)
				{
				if(exists $line->{$field})
					{
					for my $range (@{$line->{$field}})
						{
						my $user_color = (defined $self->{COLOR_NAMES} &&  defined $range->{"${field}_COLOR"})
										? $self->{COLOR_NAMES} {$self->{FORMAT}}{$range->{"${field}_COLOR"}}  ||  $range->{"${field}_COLOR"}
										: $range->{"${field}_COLOR"} ;
						
						$user_color = "style='color:#fff;'" unless defined $user_color ;
						$formated .= "<span $user_color>" . $range->{$field} . "</span>" ;
						}
						
					$formated .= ' ' ;
					}
				}
				
			$formated .= "\n" if $line->{NEW_LINE} ;
			}
		
		$formated .= "\n</pre>\n" ;
		} ;
	}
	
return $formated ;
}

#-------------------------------------------------------------------------------

1 ;

=head1 BUGS AND LIMITATIONS

None so far.

=head1 AUTHOR

	Nadim ibn hamouda el Khemir
	CPAN ID: NKH
	mailto: nadim@cpan.org

=head1 COPYRIGHT & LICENSE

Copyright 2010 Nadim Khemir.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over 4

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the Artistic License version 2.0.

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::HexDump::Range

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-HexDump-Range>

=item * RT: CPAN's request tracker

Please report any bugs or feature requests to  L <bug-data-hexdump-range@rt.cpan.org>.

We will be notified, and then you'll automatically be notified of progress on
your bug as we make changes.

=item * Search CPAN

L<http://search.cpan.org/dist/Data-HexDump-Range>

=back

=head1 SEE ALSO

L<Data::Hexdumper>, L<Data::ParseBinary>, L<Convert::Binary::C>, L<Parse::Binary>

=cut
