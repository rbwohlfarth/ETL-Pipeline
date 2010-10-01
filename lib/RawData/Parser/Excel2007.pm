=pod

=head1 SYNOPSIS

 use RawData::Parser::Excel2007;
 my $parser = new RawData::Parser::Excel2007;
 
 # Open a spreadsheet for reading.
 $parser->file( 'C:\InputData.xlsx' );

 # Read the file, one record at a time.
 while (my $record = $parser->read_one_record) {
     # Do stuff here...
 }

=head1 DESCRIPTION

This class handles MS Excel 2007 files (XLSX). These files have a different 
format from Excel 2003 (XLS).

=cut

package RawData::Parser::Excel2007;
use Moose;

extends 'RawData::Parser';
with 'RawData::Spreadsheet';

use Spreadsheet::XLSX;
use String::Util qw/define/;


=head1 METHODS & ATTRIBUTES

=head3 excel

Rather than re-invent the wheel. I used the C<Spreadsheet::Excel> module. The
C<excel> attribute points to an instance of that class. This is what actually
reads the file and parses it.

=cut

has 'excel' => (
	is  => 'rw',
	isa => 'Spreadsheet::ParseExcel::Workbook',
);


=head3 augment open( $new_path, $old_path )

Perl automatically triggers this code when the C<file> attribute changes.
This method...

=over

=item * Opens the new file using the L</excel> attribute.

=item * Sets the record at the first populated row.

=back

=cut

augment 'open' => sub {
	my ($self, $new_path, $old_path) = @_;
	$self->log->debug( __PACKAGE__ . '->open called' );

	# Create the Excel parser.
	$self->excel( Spreadsheet::XLSX->new( $new_path ) );
	$self->worksheet( shift @{$self->excel->{Worksheet}} );

	# An error is the same as "end of file".
	unless (defined $self->worksheet) {
		$self->log->fatal( 
			"Unable to read the Excel spreadsheet $new_path: "
			. $self->excel->error()
		);
		return 0;
	}

	# Find the starting row.
	$self->position( $self->worksheet->{'MinRow'} );
	$self->log->debug( 'First row: ' . $self->position );

	# Tell the surrounding code that we're good to go.
	return 1;
};


=head3 augment read_one_record()

This method populates a L<RawData::Record> with information from the 
spreadsheet.

=cut

augment 'read_one_record' => sub {
	my ($self) = @_;

	# Stop processing once we reach the last record.
	my $last_row  = $self->worksheet->{'MaxRow'};
	$self->log->debug( "Last row: $last_row" );

	if ($self->position > $last_row) {
		$self->log->debug( 
			"No data past the last row: $last_row < " 
			. $self->position
		);
		return undef;
	}

	# Copy the entire row into a list. This makes it easier to build the raw
	# data value.
	my @spreadsheet;

	my $first_column = $self->worksheet->{'MinCol'};
	my $last_column  = $self->worksheet->{'MaxCol'};
	$self->log->debug( "Columns $first_column to $last_column" );

	for my $column ($first_column .. $last_column) {
		$self->log->debug( 'Cell ' . $self->position . ",$column" );

		my $cell = $self->worksheet->{Cells}[$self->position][$column];
		push @spreadsheet, (defined( $cell ) ? $cell->value : '');
	}

	# I count from 1, the Excel class counts from zero. So I read the data
	# before incrementing the position. That way "position" always returns
	# the Excel row number for the file handling logic above.
	$self->position( $self->position + 1 );

	# Build a record from the list.
	return $self->array_to_record( @spreadsheet );
};


=head3 worksheet

The code creates this object to traverse the Excel data.

=cut

has 'worksheet' => (
	is  => 'rw',
	isa => 'Object',
);


=head1 SEE ALSO

L<RawData::Parser>, L<RawData::Record>, L<Spreadsheet::XLSX>

=head1 LICENSE

Copyright 2010  The Center for Patient and Professional Advocacy, 
                Vanderbilt University Medical Center
Contact Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=cut

no Moose;
__PACKAGE__->meta->make_immutable;

