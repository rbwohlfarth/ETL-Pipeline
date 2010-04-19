=pod

=head1 Description

This class handles MS Excel 2003 files. These files have a different format
from Excel 2007.

=cut

package RawData::Excel2003;
use Moose;

extends 'RawData::File';
with 'RawData::Spreadsheet';

use Spreadsheet::ParseExcel;


=head1 Attributes & Methods

=over

=item excel

Rather than re-invent the wheel, I used the L<Spreadsheet::Excel> module. This
attribute points to an instance of that class. This is what actually reads the
file and parses it.

=cut

has 'excel' => (
	default => sub { new Spreadsheet::ParseExcel; },
	is      => 'ro',
	isa     => 'Spreadsheet::ParseExcel',
);


=item open (private)

Perl automatically triggers this code when the C<file> attribute changes.
This method...

=over

=item *

Opens the new file using the L</excel> attribute.

=item *

Sets the record at the first populated row.

=back

=cut

augment 'open' => sub {
	my ($self, $new_path, $old_path) = @_;
	$self->log->debug( __PACKAGE__ . '->open called' );

	# Create the Excel parser.
	$self->_set_workbook( $self->excel->parse( $new_path ) );

	# Crash if there's an error.
	$self->log->logdie( 
		'Unable to read any data from the Excel spreadsheet '
		. $new_path
		. ': '
		. $self->excel->error()
	) unless (defined $self->workbook);

	# Setting the worksheet also sets our position in the file. By default,
	# we use the first worksheet.
	$self->worksheet( 0 );
};


=item read_one_record

This method populates a L<PARS::Record> with information from the 
spreadsheet. It uses L</fields> to map columns to field names.

=cut

augment 'read_one_record' => sub {
	my ($self, $record) = @_;

	# Stop processing once we reach the last record.
	my ($first_row, $last_row) = $self->worksheet->row_range();
	$self->log->debug( "Rows $first_row to $last_row" );

	if ($self->position >= $last_row) {
		$self->log->debug( 
			"No data past the last row: $last_row <= " 
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
			. $self->position
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


=item workbook

The code creates this object to traverse the Excel data.

=cut

has 'workbook' => (
	is     => 'ro',
	isa    => 'Object',
	writer => '_set_workbook',
);


=item worksheet

The name of the worksheet with the data that you want. Reading the attribute
returns an object for accessing cells. When writing, pass it the worksheet
name. The class automatically sets the object from the current workbook.

If you change this value, the code resets to the first row in the new 
worksheet.

=cut

has 'worksheet' => (
	is     => 'rw',
	isa    => 'Object',
	reader => '_get_worksheet',
	writer => '_set_worksheet',
);


sub worksheet($;$) {
	my ($self, $name) = @_;

	# Change the worksheet to a new value...
	if (defined $name) {
		$self->_set_worksheet( 
			$self->workbook->worksheet( $name )
		);

		if (defined $self->_get_worksheet) {
			# Find the actual starting row. The Excel parser begins with row 
			# zero. I use row 1 - to match the Excel screen. So the number
			# returned by Excel is the row before my first row of data.
			my ($first_row, $last_row) = $self->_get_worksheet->row_range();
			$self->log->debug( "First row: $first_row" );

			$self->position( $first_row );
		} else {
			$self->log->error( "Worksheet '$name' does not exist" );
			$self->position( 0 );
		}
	}

	# Reader and writer both return the object.
	return $self->_get_worksheet;
}


=back

=cut

no Moose;
__PACKAGE__->meta->make_immutable;

