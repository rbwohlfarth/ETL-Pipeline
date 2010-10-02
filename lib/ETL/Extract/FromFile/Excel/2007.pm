=pod

=head1 SYNOPSIS

 use ETL::Extract::FromFile::Excel::2007;
 my $parser = new ETL::Extract::FromFile::Excel::2007;
 
 # Open a spreadsheet for reading.
 $parser->connect( 'C:\InputData.xlsx' );

 # Read the file, one record at a time.
 while (my $record = $parser->extract) {
     # Do stuff here...
 }

=head1 DESCRIPTION

L<ETL::Extract::FromFile::Excel::2007> reads MS Excel 2007 files.

=cut

package ETL::Extract::FromFile::Excel::2007;
use Moose;

extends 'ETL::Extract::FromFile';
with 'ETL::Extract::FromFile::Spreadsheet';

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


=head3 augment connect( $path )

This method opens the spread sheet for reading.

=cut

augment 'connect' => sub {
	my ($self, $path) = @_;
	$self->log->debug( __PACKAGE__ . '->connect called...' );

	# Create the Excel parser.
	$self->excel( Spreadsheet::XLSX->new( $path ) );
	$self->worksheet( shift @{$self->excel->{Worksheet}} );

	# An error is the same as "end of file".
	unless (defined $self->worksheet) {
		$self->log->fatal( 
			"Unable to read the Excel spreadsheet $path: "
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


=head3 augment extract()

This method populates an L<ETL::Extract::FromFile::Record> with information
from the spreadsheet.

=cut

augment 'extract' => sub {
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

L<ETL::Extract::FromFile>, L<ETL::Extract::FromFile::Record>,
L<Spreadsheet::XLSX>

=head1 LICENSE

Copyright 2010  The Center for Patient and Professional Advocacy, 
                Vanderbilt University Medical Center
Contact Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=cut

no Moose;
__PACKAGE__->meta->make_immutable;

