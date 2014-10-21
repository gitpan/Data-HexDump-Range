
package Data::HexDump::Range ; ## no critic (Modules::RequireFilenameMatchesPackage)

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
}

#-------------------------------------------------------------------------------

use English qw( -no_match_vars ) ;

use Readonly ;
Readonly my $EMPTY_STRING => q{} ;

use Carp qw(carp croak confess) ;

#-------------------------------------------------------------------------------

=head1 NAME

Data::HexDump::Range::Split - Handles formating for Data::HexDump::Range

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 DOCUMENTATION

=head1 SUBROUTINES/METHODS

Subroutines prefixed with B<[P]> are not part of the public API and shall not be used directly.

=cut

#-------------------------------------------------------------------------------

sub split
{

=head2 [P] split($collected_data)

Split the collected data into lines

I<Arguments> - 

=over 2 

=item * $container - Collected data

=back

I<Returns> -  An Array  containing column elements

I<Exceptions>

=cut

my ($self, $collected_data) = @_ ;

my @lines ;
my $line = {} ;
my $wrapped_line = 0 ;

my $current_offset = 0 ;
my $total_dumped_data = 0 ;
my $room_left = $self->{DATA_WIDTH} ;

my $max_range_name_size = $self->{MAXIMUM_RANGE_NAME_SIZE} ;
my $user_information_size = $self->{MAXIMUM_USER_INFORMATION_SIZE} ;
my $range_source = ['?', 'white'] ;

my @found_bitfields ;

my $last_range = (grep {!  $_->{IS_BITFIELD}}@{$collected_data})[-1] ;

for my $range (@{$collected_data})
	{
	my $data_length = defined $range->{DATA} ? length($range->{DATA}) : 0 ;
	my ($start_quote, $end_quote) = $range->{IS_COMMENT} ? ('"', '"') : ('<', '>') ;
		
	$range->{SOURCE} = $range_source  if $range->{IS_BITFIELD} ;
		
	if($self->{ORIENTATION} =~ /^hor/)
		{
		$range->{COLOR} = $self->get_default_color()  unless defined $range->{COLOR} ;
		
		if($range->{IS_BITFIELD}) 
			{
			push @found_bitfields, $self->get_bitfield_lines($range) ;
			
			next ;
			}
		
		if($room_left == $self->{DATA_WIDTH})
			{
			push @lines,  @found_bitfields ;
			@found_bitfields = () ;
			}
		
		# remember what range we process in case next range is bitfield
		unless($range->{IS_COMMENT})
			{
			$range_source = [$range->{NAME}, $range->{COLOR}]  ;
			}
		
		my $dumped_data = 0 ;
		my $data_length = defined $range->{DATA} ? length($range->{DATA}) : 0 ;
		
		if(0 == $data_length && $self->{DISPLAY_RANGE_NAME})
			{
			my $display_range_name = 0 ;
			
			if($range->{IS_COMMENT})
				{
				$display_range_name++ if $self->{DISPLAY_COMMENT_RANGE} ;
				}
			else
				{
				$display_range_name++ if $self->{DISPLAY_ZERO_SIZE_RANGE} ;
				}
					
			if($display_range_name)
				{
				my $name_size_quoted = $max_range_name_size - 2 ;
				$name_size_quoted =  2 if $name_size_quoted < 2 ;
				
				push @{$line->{RANGE_NAME}},
					{
					'RANGE_NAME' => $start_quote . sprintf("%.${name_size_quoted}s", $range->{NAME}) . $end_quote,
					'RANGE_NAME_COLOR' => $range->{COLOR},
					},
					{
					'RANGE_NAME_COLOR' => undef,
					'RANGE_NAME' => ', ',
					} ;
				}
			}
			
		if($range->{IS_SKIP}) 
			{
			# skip range don't display any data
			my $size_to_dump = $data_length ;
			
			#justify offset for next range
			$current_offset += $size_to_dump ;
			
			$range->{NAME} = '>>' . $range->{NAME} ;
			
			#dump nothing
			$size_to_dump = 0 ;
			
			for my  $field_type 
				(
				['OFFSET', sub {exists $line->{OFFSET} ? '' : sprintf $self->{OFFSET_FORMAT}, $current_offset + $self->{OFFSET_START}}, undef, 0],
				['BITFIELD_SOURCE', sub {exists $line->{BITFIELD_SOURCE} ? '' : ' ' x 8}, undef, 0],
				['HEX_DUMP', sub {sprintf '%02x ' x $size_to_dump, @_}, $range->{COLOR}, 3],
				['DEC_DUMP', sub {sprintf '%03u ' x $size_to_dump, @_}, $range->{COLOR}, 4],
				['ASCII_DUMP', sub {sprintf '%c' x $size_to_dump, map{$_ < 30 ? ord('.') : $_ } @_}, $range->{COLOR}, 1],
				['RANGE_NAME',sub {sprintf "%.${max_range_name_size}s", $range->{NAME}}, $range->{COLOR}, 0],
				)
				{
				my ($field_name, $field_data_formater, $color, $pad_size) = @{$field_type} ;
				
				if($self->{"DISPLAY_$field_name"})
					{
					my $field_text = $field_data_formater->() ;
					
					my $pad = $pad_size  ? ' ' x ($room_left * $pad_size) : ''  ;
					
					push @{$line->{$field_name}},
						{
						$field_name . '_COLOR' => $color,
						$field_name => $field_text . $pad,
						} ;
					}
				}
			
			$line->{NEW_LINE}++ ;
			push @lines, $line ;
				
			push @lines,  @found_bitfields ;
			@found_bitfields = () ;
			
			# start a fresh line
			
			$line = {} ;
			$room_left = $self->{DATA_WIDTH} ;
				
			next ;
			}
			
		while ($dumped_data < $data_length)
			{
			my $size_to_dump = min($room_left, $data_length - $dumped_data) || 0 ;
			
			$room_left -= $size_to_dump ;
			
			my @range_unpacked_data = unpack("x$dumped_data C$size_to_dump", $range->{DATA}) ;
		
			for my  $field_type 
				(
				['OFFSET', sub {exists $line->{OFFSET} ? '' : sprintf $self->{OFFSET_FORMAT}, $current_offset + $self->{OFFSET_START}}, undef, 0],
				['BITFIELD_SOURCE', sub {exists $line->{BITFIELD_SOURCE} ? '' : ' ' x 8}, undef, 0],
				['HEX_DUMP', sub {sprintf '%02x ' x $size_to_dump, @_}, $range->{COLOR}, 3],
				['DEC_DUMP', sub {sprintf '%03u ' x $size_to_dump, @_}, $range->{COLOR}, 4],
				['ASCII_DUMP', sub {sprintf '%c' x $size_to_dump, map{$_ < 30 ? ord('.') : $_ } @_}, $range->{COLOR}, 1],
				['RANGE_NAME',sub {sprintf "%.${max_range_name_size}s", $range->{NAME}}, $range->{COLOR}, 0],
				['RANGE_NAME', sub {', '}, undef, 0],
				)
				{
				my ($field_name, $field_data_formater, $color, $pad_size) = @{$field_type} ;
				
				if($self->{"DISPLAY_$field_name"})
					{
					my $field_text = $field_data_formater->(@range_unpacked_data) ;
					
					my $pad = $last_range == $range ? $pad_size  ? ' ' x ($room_left * $pad_size) : '' : '' ;
					
					push @{$line->{$field_name}},
						{
						$field_name . '_COLOR' => $color,
						$field_name => $field_text . $pad,
						} ;
					}
				}
				
			$dumped_data += $size_to_dump ;
			$current_offset += $size_to_dump ;
			
			if($room_left == 0 || $last_range == $range)
				{
				$line->{NEW_LINE}++ ;
				push @lines, $line ;
				
				$line = {} ;
				$room_left = $self->{DATA_WIDTH} ;
				
				push @lines,  @found_bitfields ;
				@found_bitfields = () ;
				}
			}
		}
	else
		{ 
		# vertical mode
			
		$range->{COLOR} = $self->get_default_color()  unless defined $range->{COLOR} ;
		
		$line = {} ;

		my $dumped_data = 0 ;
		my $current_range = '' ;
		
		if(!$range->{IS_BITFIELD} && 0 == $data_length && $self->{DISPLAY_RANGE_NAME}) # && $self->{DISPLAY_RANGE_NAME})
			{
			my $display_range_name = 0 ;
			
			if($range->{IS_COMMENT})
				{
				$display_range_name++ if $self->{DISPLAY_COMMENT_RANGE} ;
				}
			else
				{
				$display_range_name++ if $self->{DISPLAY_ZERO_SIZE_RANGE} ;
				}
					
			if($display_range_name)
				{
				push @{$line->{RANGE_NAME}},
					{
					'RANGE_NAME_COLOR' => $range->{COLOR},
					'RANGE_NAME' => "$start_quote$range->{NAME}$end_quote",
					} ;
					
				$line->{NEW_LINE} ++ ;
				push @lines, $line ;
				$line = {};
				}
			}
			
		if($range->{IS_SKIP}) 
			{
			my $size_to_dump = $data_length ;
			my $next_data_offset = $total_dumped_data + $data_length - 1 ;
			
			$range->{NAME} = '>>' . $range->{NAME} ;
		
			#dump nothing
			$size_to_dump = 0 ;
			
			for my  $field_type 
				(
				['RANGE_NAME',  sub {sprintf "%-${max_range_name_size}.${max_range_name_size}s", $range->{NAME} }, $range->{COLOR}, $max_range_name_size] ,
				['OFFSET', sub {sprintf $self->{OFFSET_FORMAT}, $total_dumped_data + $self->{OFFSET_START}}, undef, 8],
				['CUMULATIVE_OFFSET', sub {sprintf $self->{OFFSET_FORMAT}, $next_data_offset}, undef, 8],
				['BITFIELD_SOURCE', sub {' ' x 8}, undef, 8],
				[
				'HEX_DUMP', 
				sub 
					{
					my @bytes = unpack("(H2)*", pack("N", $data_length));
					"@bytes bytes skipped" ;
					},
				$range->{COLOR},
				3 * $self->{DATA_WIDTH},
				],
				[
				'DEC_DUMP', 
				sub 
					{
					my @values = map {sprintf '%03u', $_} unpack("(C3)*", pack("N", $data_length));
					join(' ',  @values) . " skipped: $data_length bytes"  ;
					},
				$range->{COLOR},
				4 * $self->{DATA_WIDTH}
				],
				['ASCII_DUMP', sub {$EMPTY_STRING}, $range->{COLOR}, $self->{DATA_WIDTH}],
                                ['USER_INFORMATION', sub { sprintf '%-20.20s', $range->{USER_INFORMATION} || ''}, $range->{COLOR}, 20],
				)
				{
				my ($field_name, $field_data_formater, $color, $field_text_size) = @{$field_type} ;
				
				if($self->{"DISPLAY_$field_name"})
					{
					my $field_text = $field_data_formater->([]) ;
					my $pad = ' ' x ($field_text_size -  length($field_text)) ;
					
					push @{$line->{$field_name}},
						{
						$field_name . '_COLOR' => $color,
						$field_name =>  $field_text .  $pad,
						} ;
					}
				}
			
			$total_dumped_data += $data_length ;
			
			$line->{NEW_LINE} ++ ;
			push @lines, $line ;
			$line = {};
				
			next ;
			}
			
		while ($dumped_data < $data_length)
			{ 
			last if($range->{IS_BITFIELD}) ;

			my $size_to_dump = min($self->{DATA_WIDTH}, length($range->{DATA}) - $dumped_data) ;
			my @range_data = unpack("x$dumped_data C$size_to_dump", $range->{DATA}) ;
			
			for my  $field_type 
				(
				['RANGE_NAME',  sub {sprintf "%-${max_range_name_size}.${max_range_name_size}s", $range->{NAME} ; }, $range->{COLOR}, $max_range_name_size] ,
				['OFFSET', sub {sprintf $self->{OFFSET_FORMAT}, $total_dumped_data + $self->{OFFSET_START}}, undef, 8],
				['CUMULATIVE_OFFSET', sub {sprintf $self->{OFFSET_FORMAT}, $dumped_data}, undef, 8],
				['BITFIELD_SOURCE', sub {'' x 8}, undef, 8],
				['HEX_DUMP', sub {sprintf '%02x ' x $size_to_dump, @{$_[0]}}, $range->{COLOR}, 3 * $self->{DATA_WIDTH}],
				['DEC_DUMP', sub {sprintf '%03u ' x $size_to_dump, @{ $_[0] }}, $range->{COLOR}, 4 * $self->{DATA_WIDTH}],
				['ASCII_DUMP', sub {sprintf '%c' x $size_to_dump, map{$_ < 30 ? ord('.') : $_ } @{$_[0]}}, $range->{COLOR}, $self->{DATA_WIDTH}],
                                ['USER_INFORMATION', sub { sprintf "%-${user_information_size}.${user_information_size}s", $range->{USER_INFORMATION} || ''}, $range->{COLOR}, $user_information_size],
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
			
		if($range->{IS_BITFIELD})
			{
			push @lines, $self->get_bitfield_lines($range)  ;
			}
		else
			{
			$range_source = [$range->{NAME}, $range->{COLOR}]  ;
			}
		}
	}

if(@found_bitfields)
	{
	push @lines,  @found_bitfields ;
	@found_bitfields = () ;
	}

return \@lines ;
}

sub get_bitfield_lines
{

=head2 [P] get_bitfield_lines($bitfield_description)

Split the collected data into lines

I<Arguments> - 

=over 2 

=item * $self - a Data::HexDump::Range object

=item * $bitfield_description - 

=back

I<Returns> - An Array  containing column elements, 

I<Exceptions> None but will embed an error in the element if any is found

=cut

my ($self, $bitfield_description) = @_ ;

#~ use Data::TreeDumper ;
#~ print DumpTree $bitfield_description, '$bitfield_description', QUOTE_VALUES => 1 ;

return unless $self->{DISPLAY_BITFIELDS} ;

my ($line, @lines) = ({}) ;

my ($byte_offset, $offset, $size) = $bitfield_description->{IS_BITFIELD} =~ m/(X\d*?)?(x\d*?)?(b\d*?)$/ ;
 
substr($byte_offset, 0, 1, '')  if defined $byte_offset ;
substr($offset, 0, 1, '') if defined $offset ;
substr($size, 0, 1, '') if defined $size ;

$byte_offset ||= 0 ;
$offset ||= 0 ; $offset += $byte_offset * 8 ;

$size ||= 1 ;

my $max_range_name_size = $self->{MAXIMUM_RANGE_NAME_SIZE} ;
my $max_bitfield_source_size = $self->{MAXIMUM_BITFIELD_SOURCE_SIZE} ;

my %always_display_field = map {$_ => 1} qw(RANGE_NAME OFFSET CUMULATIVE_OFFSET BITFIELD_SOURCE USER_INFORMATION) ;

#~ print DumpTree {length => length($bitfield_description->{DATA}), offset => $offset, size => $size, BF => $bitfield_description} ;

for my  $field_type 
	(
	['RANGE_NAME',  sub {sprintf "%-${max_range_name_size}.${max_range_name_size}s", '.' . $_[0]->{NAME} ; }, undef, $max_range_name_size ] ,
	['OFFSET', sub {sprintf '%02u .. %02u', $offset, ($offset + $size) - 1}, undef, 8],
	['CUMULATIVE_OFFSET', sub {''}, undef, 8],
	['BITFIELD_SOURCE', sub {sprintf "%-${max_bitfield_source_size}.${max_bitfield_source_size}s", $_[0]->{SOURCE}[0]}, $bitfield_description->{SOURCE}[1], 8],
	['HEX_DUMP', 
		sub 
		{
		my ($binary, @binary , $binary_dashed) ;
		
		if($self->{BIT_ZERO_ON_LEFT})
			{
			@binary = split '', unpack("B*",  $_[0]->{DATA}) ;
			splice(@binary, 0, $offset) ;
			splice(@binary, $size) ;
			
			$binary = join('', @binary) ;
			
			$binary_dashed = '-' x $offset . $binary . '-' x (32 - ($size + $offset)) ;
			$binary_dashed  = substr($binary_dashed , -32) ;
			}
		else
			{
			@binary = split '', unpack("B*",  $_[0]->{DATA}) ;
			splice(@binary, -$offset) unless $offset == 0 ;
			@binary = splice(@binary, - $size) ;
			
			$binary = join('',  @binary) ;
			
			$binary_dashed = '-' x (32 - ($size + $offset)) . $binary . '-' x $offset  ;
			$binary_dashed  = substr($binary_dashed , 0, 32) ;
			}
		
		my $bytes = $size > 24 ? 4 : $size > 16 ? 3 : $size > 8 ? 2 : 1 ;
		
		my @bytes = unpack("(H2)*", pack("B32", substr("0" x 32 . $binary, -32)));
		
		my $number_of_bytes = @binary > 24 ? 4 : @binary > 16 ? 3 : @binary > 8 ? 2 : 1 ;
		splice @bytes, 0 , (4 - $number_of_bytes), map {'--'} 1 .. (4 - $number_of_bytes) ;
		
		join(' ', @bytes) . '    ' . $binary_dashed;
		},
		
		undef, 3 * $self->{DATA_WIDTH}],
	['DEC_DUMP', 
		sub 
		{
		my ($binary, @binary , $value) ;
		
		if($self->{BIT_ZERO_ON_LEFT})
			{
			@binary = split '', unpack("B*",  $_[0]->{DATA}) ;
			splice(@binary, 0, $offset) ;
			splice(@binary, $size) ;
			$binary = join('', @binary) ;
			$value = unpack("N", pack("B32", substr("0" x 32 . $binary, -32)));
			}
		else
			{
			@binary = split '', unpack("B*",  $_[0]->{DATA}) ;
			splice(@binary, -$offset) unless $offset == 0 ;
			@binary = splice(@binary, - $size) ;
			$binary = join('', @binary) ;
			$value = unpack("N", pack("B32", substr("0" x 32 . $binary, -32)));
			}
		
		my @values = map {sprintf '%03u', $_} unpack("W*", pack("B32", substr("0" x 32 . $binary, -32)));
		
		my $number_of_bytes = @binary > 24 ? 4 : @binary > 16 ? 3 : @binary > 8 ? 2 : 1 ;
		splice @values, 0 , (4 - $number_of_bytes), map {'---'} 1 .. (4 - $number_of_bytes) ;
		
		join(' ',  @values) . ' ' . "value: $value"  ;
		},
		
		$bitfield_description->{COLOR}, 4 * $self->{DATA_WIDTH}],
		
	['ASCII_DUMP',
		sub 
		{
		my ($binary, @binary , @chars) ;
		
		if($self->{BIT_ZERO_ON_LEFT})
			{
			@binary = split '', unpack("B*",  $_[0]->{DATA}) ;
			splice(@binary, 0, $offset) ;
			splice(@binary, $size) ;
			}
		else
			{
			@binary = split '', unpack("B*",  $_[0]->{DATA}) ;
			splice(@binary, -$offset) unless $offset == 0 ;
			@binary = splice(@binary, - $size) ;
			}
			
		$binary = join('', @binary) ;
		@chars = map{$_ < 30 ? '.' : chr($_) } unpack("C*", pack("B32", substr("0" x 32 . $binary, -32)));
		
		my $number_of_bytes = @binary > 24 ? 4 : @binary > 16 ? 3 : @binary > 8 ? 2 : 1 ;
		splice @chars, 0 , (4 - $number_of_bytes), map {'-'} 1 .. (4 - $number_of_bytes) ;
		
		'.bitfield: '.  join('',  @chars) 
		},

		undef, $self->{DATA_WIDTH}],
		
		['USER_INFORMATION', sub { sprintf '%-20.20s', $_[0]->{USER_INFORMATION} || ''}, $bitfield_description->{COLOR}, 20],
		
	)
	{
	my ($field_name, $field_data_formater, $color, $field_text_size) = @{$field_type} ;
	
	$color ||= $bitfield_description->{COLOR} ;
	
	if($self->{"DISPLAY_$field_name"})
		{
		my $field_text ;
		
		my $not_enough_data = $EMPTY_STRING eq $bitfield_description->{DATA} ;
		$not_enough_data += length($bitfield_description->{DATA}) * 8 < ($offset + $size) ;
		
		if($not_enough_data && ! $always_display_field{$field_name})
			{
			$field_text = '?' ;
			}
		else
			{
			$field_text = $field_data_formater->($bitfield_description) ;
			}
		
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

return @lines ;
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
			my $length = $self->{FIELD_LENGTH}{$field_name} || croak "Error: undefined field length" ;
				
			$information .= sprintf "%-${length}.${length}s ", $field_name
			}
		}
		
	push @information,
		{
		INFORMATION => [ {INFORMATION_COLOR => 'bright_white', INFORMATION => $information} ], 
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
					
				$information .= ' ' x $self->{FIELD_LENGTH}{$field_name}  . ' ' ;
				}
			}
		}
		
	push @information,
		{
		RULER => [ {RULER_COLOR => 'bright_white', RULER=> $information} ], 
		NEW_LINE => 1,
		} ;
	}
	
unshift @{$split_data}, @information ;

}

#-------------------------------------------------------------------------------

1 ;

=head1 BUGS AND LIMITATIONS

None so far.

=head1 AUTHOR

	Nadim ibn hamouda el Khemir
	CPAN ID: NKH
	mailto: nadim@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright Nadim Khemir 2010.

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

L<Data::HexDump::Range>

=cut
