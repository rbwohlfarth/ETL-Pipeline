=pod

=head1 NAME

Data::ETL::Extract::Excel - Input source for Microsoft Excel spreadsheets

=head1 SYNOPSIS

  use ETL;
  working_folder 'C:\Data';
  extract_from 'Excel', find_file => qr/\.xls(x|m)?$/;
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

You use this class by naming it in the L<Data::ETL/extract_from> call. You
would not normally use it directly.

=cut

use 5.14.0;
use strict;
use warnings;

package Data::ETL::Extract::Excel;
use Moose;

with 'Data::ETL::Extract::AsHash';
with 'Data::ETL::Extract::File';
with 'Data::ETL::Extract';

use Spreadsheet::ParseExcel;
use Spreadsheet::XLSX;
use String::Util qw/hascontent/;


our $VERSION = '1.00';


=head1 METHODS & ATTRIBUTES

=head2 Set with the L<Data::ETL/extract_from> command

See L<Data::ETL::Extract::File> and L<Data::ETL::Extract::AsHash> for more 
attributes.

=head3 has_header_row

Most spread sheets contains a header row that names the columns. By default,
this class assumes that the first row are column headers. Set this attribute 
to B<false> if that's not the case. Otherwise you will lose the first row of
data.

=cut

has '+has_header_row' => (default => 1);


=head2 Automatically called from L<Data::ETL/run>

=head3 next_record

Read one record from the spreadsheet and populates
L<Data::ETL::Extract::AsHash/record>. The method returns the number of records 
loaded. A B<0> means that we reached the end of the data.

=cut

sub next_record {
	my ($self, $return_blank) = @_;

	my $count = 0;
	my $empty = 1;
	my $row = $self->record_number;
	my $last_row = $self->worksheet->{'MaxRow'};

	# Skip blank rows, but don't loop forever.
	while ($row <= $last_row and $empty) {
		my %record;
		foreach my $column (@{$self->columns}) {
			my $cell  = $self->worksheet->{Cells}[$row][$column];
			my $value = defined( $cell ) ? $cell->value : '';

			$record{$column} = $value;
			$empty = 0 if hascontent( $value );
		}
		$self->record( \%record );
		
		$count++;
		$row++;
		
		# When skipping over rows, the calling code expects that we loaded 
		# exactly one record, even if it's blank.
		$empty = 0 if $return_blank;
	}

	# Ignore blank rows on the end.
	return ($empty ? 0 : $count);
}


=head3 setup

This method configures the input source. In this object, that means creating
the Excel parsing object and attaching it to the file.

C<setup> runs once per file. I put extra logic in here to speed up
L</next_record>. This method does 2 main things...

=over

=item 1. Create the correct worksheet object based on the Excel format.

=item 2. Convert column numbers into letter designations.

=back

Different classes parse different versions of the Excel file format. This
method matches the class to the file type by the extension. B<XLS> means
Excel 2003. And B<XLSX> means an Excel 2007 file.

The Excel parsers use column numbers. The setup automatically aliases the 
column letters to the numbers. Your L<Data::ETL/transform_as> command can
then use the column letters - making it more human readable.

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
	$self->alias->{$self->letter_for( $_ )} = $_ foreach (@{$self->columns});

	# Start on the first row as defined by the spread sheet.
	$self->record_number( $self->worksheet->{'MinRow'} );
}


=head3 finished

This method shuts down the input source. In our case, it does nothing.

=cut

sub finished {}


=head2 Internal Attributes and Methods

You should never use these items. They can change at any moment. I documented
them for the module maintainers.

=head3 letter_for

This little method translates a column number into the letters that you see
in MS Excel. Computers like numbers. People like letters. This class lets you
identify columns by their letter designation.

=cut

sub letter_for {
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

L<Data::ETL>, L<Data::ETL::Extract>, L<Data::ETL::Extract::AsHash>, 
L<Data::ETL::Extract::File>, L<Spreadsheet::ParseExcel>, L<Spreadsheet::XLSX>

=head1 AUTHOR

Robert Wohlfarth <rbwohlfarth@gmail.com>

=head1 LICENSE

Copyright 2012  Robert Wohlfarth

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
