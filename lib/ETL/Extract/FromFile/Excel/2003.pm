=pod

=head1 NAME

ETL::Extract::FromFile::Excel::2003 - Read data from XLS files

=head1 DESCRIPTION

This class extracts data from MS Excel 97/2003 spreadsheet files.

=cut

package ETL::Extract::FromFile::Excel::2003;
use Moose;

extends 'ETL::Extract::FromFile';
with 'ETL::Extract::FromFile::Spreadsheet';

use Spreadsheet::ParseExcel;


=head1 METHODS & ATTRIBUTES

=head3 BUILD()

L<Moose> calls this method dring object construction. It opens the spreadsheet
file and prepares it for reading.

=cut

sub BUILD {
	my ($self, $options) = @_;

	my $path = $self->path;
	$self->workbook( $self->excel->parse( $path ) );

	if (defined $self->workbook) {
		# Setting the worksheet also sets our position in the file. By default,
		# we use the first worksheet.
		$self->worksheet( 0 );
	} else {
		$self->log->logdie( 
			"Unable to read the Excel spreadsheet $path:"
			. $self->excel->error()
		);
	}
}


=head3 excel

Rather than re-invent the wheel, I used the L<Spreadsheet::ParseExcel> module.
This attribute points to an instance of that class. This is what actually 
reads the file and parses it.

=cut

has 'excel' => (
	default => sub { Spreadsheet::ParseExcel->new; },
	is      => 'ro',
	isa     => 'Spreadsheet::ParseExcel',
);


=head3 augument extract()

This method populates an L<ETL::Record> with information from the spreadsheet.

=cut

augment 'extract' => sub {
	my ($self) = @_;

	# Stop processing once we reach the last record. The class counts rows
	# from zero. "position" counts rows from 1. "position" should move one
	# row past what the class says. That's why I used ">" instead of ">=".
	my ($first_row, $last_row) = $self->worksheet->row_range();
	$self->log->debug( "Rows $first_row to $last_row" );

	if ($self->position > $last_row) {
		$self->log->debug( 
			"No data past the last row: $last_row < " 
			. $self->position 
		);
		return undef;
	}

	# Copy the entire row into a list...
	my @spreadsheet;

	my ($first_column, $last_column) = $self->worksheet->col_range();
	$self->log->debug( "Columns $first_column to $last_column" );

	for my $column ($first_column .. $last_column) {
		$self->log->debug( 
			'Cell ' 
			. $self->column_name_on_screen( $column )
			. ($self->position + 1)
		);

		my $cell = $self->worksheet->get_cell( 
			$self->position, 
			$column 
		);
		push @spreadsheet, (defined( $cell ) ? $cell->value : '');
	}

	# I count from 1, the Excel class counts from zero. So I read the data
	# before incrementing the position. That way "position" always returns
	# the Excel row number of the current data.
	$self->position( $self->position + 1 );

	# Build a record from the list.
	return $self->array_to_record( @spreadsheet );
};


=head3 workbook

The code creates this object to traverse the Excel data.

=cut

has 'workbook' => (
	is  => 'rw',
	isa => 'Object',
);


=head3 worksheet( [$sheet_name] )

Returns or sets the current worksheet. This controls where Excel reads your
data. If you change this value, the code resets to the first row in the new 
worksheet.

Pass a worksheet name and the method changes the current worksheet. The method
always returns a reference to the current sheet.

=cut

has '_worksheet' => (
	is  => 'rw',
	isa => 'Object',
);


sub worksheet($;$) {
	my ($self, $name) = @_;

	# Change the worksheet to a new value...
	if (defined $name) {
		$self->_worksheet( 
			$self->workbook->worksheet( $name )
		);

		if (defined $self->_worksheet) {
			# Find the actual starting row. The Excel parser begins on row 
			# zero. I use row 1 - to match the Excel screen. So the number
			# returned by Excel is the row before my first row of data.
			my ($first_row, $last_row) = $self->_worksheet->row_range();
			$self->log->debug( "First row: $first_row" );

			$self->position( $first_row );
		} else {
			$self->log->error( "Worksheet '$name' does not exist" );
			$self->position( 0 );
		}
	}

	# Reader and writer both return the object.
	return $self->_worksheet;
}


=head1 SEE ALSO

L<ETL::Extract::FromFile>, L<ETL::Record>,
L<ETL::Extract::FromFile::Spreadsheet>, L<Spreadsheet::ParseExcel>

=head1 LICENSE

Copyright 2010  The Center for Patient and Professional Advocacy, Vanderbilt University Medical Center
Contact Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
