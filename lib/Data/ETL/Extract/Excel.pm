=pod

=head1 NAME

Data::ETL::Extract::Excel - Input source for Microsoft Excel spreadsheets

=head1 SYNOPSIS

  use ETL;
  extract_using 'Excel', root => 'C:\Data', file_name => qr/\.xls(x|m)?$/;
  transform A => ExternalID, Name => PatientName;
  load_into 'Access';
  run;

=head1 DESCRIPTION

B<ETL> stands for I<Extract-Transform-Load>. You often hear this design
pattern associated with Data Warehousing. In fact, ETL works with almost
any type of data conversion. You read the source (I<Extract>), translate the
data for your target (I<Transform>), and store the result (I<Load>).

This class defines an ETL input source that reads Microsoft Excel spreadsheets.
It supports both the I<xls> and I<xlsx> formats.

You use this class by naming it in the L<Data::ETL/extract_using> call. You
would not normally use it directly.

=cut

package Data::ETL::Extract::Excel;
use Moose;

with 'Data::ETL::Extract';
with 'Data::ETL::Extract::File';

use Spreadsheet::ParseExcel;
use Spreadsheet::XLSX;
use String::Util qw/hascontent/;


=head1 METHODS & ATTRIBUTES

=head3 next_record

Read one record from the spreadsheet and populates
L<Data::ETL::Extract/record>. The method returns the number of records loaded.
A B<0> means that we reached the end of the data.

=cut

sub next_record {
	my ($self) = @_;
	my $row = $self->record_number;

	# Stop processing once we reach the last record.
	my $last_row  = $self->worksheet->{'MaxRow'};
	return 0 if $row > $last_row;

	my %record;
	my $not_empty = 0;
	foreach my $column (@{$self->columns}) {
		my $cell  = $self->worksheet->{Cells}[$row][$column];
		my $value = defined( $cell ) ? $cell->value : '';

		$record{$column} = $value;
		$not_empty = 1 if hascontent( $value );
	}
	$self->record( \%record );

	return ($self->stop_on_blank ? $not_empty : 1);
}


=head3 get

Return the value of a field from the current record. The only parameter is a
field name. You can use either the column letter or the field name.

=cut

sub get { $_[0]->record->{$_[1]}; }


=head3 setup

This method configures the input source. In this object, that means creating
the Excel parsing object and attaching it to the file.

C<setup> runs once per file. I put extra logic in here to speed up
L</next_record>. This method does 3 main things...

=over

=item 1. Create the correct worksheet object based on the Excel format.

=item 2. Convert column numbers into letter designations.

=item 3. And process the header row.

=back

Different classes parse different versions of the Excel file format. This
method matches the class to the file type by the extension. B<XLS> means
Excel 2003. And B<XLSX> means an Excel 2007 file.

The Excel parsers use column numbers. Excel uses letters instead. For
consistency, the I<transform> process also uses letters. This code sets up
the L</names> hash for that purpose.

I also name the fields based on the header row. You can identify data by the
field name or by the column name. See L</headers> for more information.

=cut

sub setup {
	my ($self) = @_;

	# Create the correct worksheet objects based on the file format.
	my $path = $self->path;
	if ($path =~ m/\.xls$/i) {
		my $excel    = Spreadsheet::ParseExcel->new;
		my $workbook = $excel->parse( $path );
		die( "Unable to open the Excel file $path" ) unless defined $workbook;
		$self->worksheet( $workbook->worksheet( 0 ) );
	} else {
		my $excel = Spreadsheet::XLSX->new( $path );
		$self->worksheet( shift @{$excel->{Worksheet}} );
		die( "Unable to open the Excel file $path: " . $excel->error )
			unless defined $self->worksheet;
	}

	# Convert the column numbers into their letter designations.
	my $first_column = $self->worksheet->{'MinCol'};
	my $last_column  = $self->worksheet->{'MaxCol'};
	$self->columns( [$first_column .. $last_column] );

	foreach my $column (@{$self->columns}) {
		my $name = $self->convert_column_number_into_letters( $column );
		$self->add_name( $name, $column );
	}

	# Start on the first row as defined by the spread sheet.
	$self->record_number( $self->worksheet->{'MinRow'} );
}


=head3 stop_on_blank

By default, we stop processing records at the first blank row. Some folks send
trailer information. And a blank row always comes before the trailer.

To change that, set this attribute to B<0>.

=cut

has 'stop_on_blank' => (
	default => 1,
	is      => 'rw',
	isa     => 'Bool',
);


=head3 finished

This method shuts down the input source. In our case, it does nothing.

=cut

sub finished {}


=head2 Internal Attributes and Methods

You should never use these items. They can change at any moment. I documented
them for the module maintainers.

=head3 record

This hash holds the record loaded from the file.

=cut

has 'record' => (
	is  => 'rw',
	isa => 'HashRef[Maybe[Str]]',
);


=head3 convert_column_number_into_letters

This little method translates a column number into the letters that you see
in MS Excel. Computers like numbers. People like letters. This class lets you
identify columns by their letter designation.

=cut

sub convert_column_number_into_letters {
	my ($self, $column_number) = @_;

	# Just keep adding letters as we cycle through the alphabet.
	my $name = '';
	while ($column_number > 25) {
		my $offset = $column_number % 26;
		my $letter = chr( ord( 'A' ) + $offset );
		$name = "$letter$name";

		$column_number = int( $column_number / 26 ) - 1;
	}

	# Add the last letter based on whatever is left.
	my $letter = chr( ord( 'A' ) + $column_number );
	$name = "$letter$name";

	return $name;
}


=head3 columns

An array of accessible column numbers. You can read data from all of the
columns listed here. Every record has to loop over this same list. With this
attribute, I only calculate it once.

=cut

has 'columns' => (
	is  => 'rw',
	isa => 'ArrayRef[Int]',
);


=head3 worksheet

This attribute holds the current worksheet object. The Excel parsers return an
object for the tab with our data. I hold the object here so that I can use it
to grab the data.

=cut

has 'worksheet' => (
	is  => 'rw',
	isa => 'Object',
);


=head1 SEE ALSO

L<Data::ETL>, L<Data::ETL::Extract>, L<Data::ETL::Extract::File>,
L<Spreadsheet::ParseExcel>, L<Spreadsheet::XLSX>

=head1 AUTHOR

Robert Wohlfarth <rbwohlfarth@gmail.com>

=head1 LICENSE

Copyright 2012  Robert Wohlfarth

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
