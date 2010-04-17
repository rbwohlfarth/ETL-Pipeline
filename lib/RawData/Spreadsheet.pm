=pod

=head1 Description

This role provides helper methods for working with spreadsheet data.

It assumes one record per row of the spreadsheet. This is how our clients send
their data. I don't want to add complexity that isn't necessary.

=cut

package RawData::Spreadsheet;
use Moose::Role;

use RawData::Record;


=head1 Column Names

Spreadsheet programs reference cells with a column and row. They typically
show columns as letters across the top of the window. The Perl drivers, 
though, reference columns using numbers. These functions translate from one
format to the other. I want my code using the letters - just like it appears
to the user on the screen.

=over

=item column_name_in_file

Convert from a cell reference with letters to one with numbers. This function
only converts the column name. It strips off the row.

=cut

sub column_name_in_file($$) {
	my ($self, $on_screen) = @_;

	# Already in file format...
	return $on_screen if ($on_screen =~ m/^\d*$/);

	# Strip off the row number, if there is one...
	$on_screen =~ s/^([[:alpha:]]+)\d*$/$1/;
	$on_screen =  uc( $on_screen );

	# Convert letters into ordinal numbers.
	# A = 0; B = 1; etc...
	my @decimals;
	
	my @letters = split( //, $on_screen );
	foreach my $letter (@letters) {
		unshift @decimals, ord( $letter ) - ord( 'A' );
	}

	# Now add the numbers together in base 26.
	my $value = 0;
	for (my $index = $#decimals; $index >= 0; $index--) {
		$value += $decimals[$index] * (26**$index);
	}
}


=item column_name_on_screen

Convert from a column number into its alphabetic name.

=cut

sub column_name_on_screen($$) {
	my ($self, $in_file) = @_;

	# Already in file format...
	return $in_file if ($in_file =~ m/^[[:alpha:]]*$/);

	# Break apart the base 26 number.
	my @letters;
	
	my $remaining = $in_file;
	while ($remaining > 0) {
		# Remainder is the letter in this place.
		my $count = $remaining % 26;
		
		# Quotient is the rest of the number to analyze.
		$remaining = int( $remaining / 26 );

		# Convert to an uppercase letter...
		unshift @letters, chr( ord( 'A' ) + $count );
	}

	# Return the first column because the loop won't translate a zero.
	return ((@letters == 0) ? 'A' : join( '', @letters ));
}


=back

=head1 Accessing the Record Data

Spreadsheets use the column screen name as the field name... the first
column goes into field B<A>, second into B<B>, third into B<C>, etc. 

=over 

=item array_to_record

Convert data from an array of values into a hash, keyed by the column name.
The method accepts a list of data, or a reference to a list. It returns the 
populated L<RawData::Record> object.

=cut

sub array_to_record($@) {
	my ($self, @data) = @_;

	# Accept either an array or an array reference. If I always use a 
	# reference, then I don't cut and paste code.
	my $array = \@data;
	   $array = $data[0] if ((@data == 1) and (ref( $data[0] ) eq 'ARRAY'));
	
	# Create a new record object. I assume the record is blank until we find
	# a non-blank field.
	my $record = RawData::Record->new();
	   $record->is_blank( 1 );
	   
	# Populate the fields using the column name - not its index.
	for (my $index = 0; $index < @$array; $index++) {
		my $column = $self->column_name_on_screen( $index );
		my $value  = $array->[$index];

		$record->data->{$column} = $value;
		$record->is_blank( 0 ) unless ($value =~ m/^\s*$/);
	}
}


=back

=cut
1;

