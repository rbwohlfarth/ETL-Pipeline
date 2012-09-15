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

	# Stop processing once we reach the last record.
	my $last_row  = $self->worksheet->{'MaxRow'};
	return 0 if $self->position >= $last_row;

	# Copy the entire row into a list. This makes it easier to build the raw
	# data value.
	my $not_empty = 0;
	foreach my $column (@{$self->columns}) {
		my $cell  = $self->worksheet->{Cells}[$self->position][$column];
		my $value = defined( $cell ) ? $cell->value : '';

		$self->record->{$_} = $value foreach (@{$self->names->{$column}});

		$not_empty = 1 if hascontent( $value );
	}

	return ($self->stop_on_blank ? $not_empty : 1);
};


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
	foreach my $column ($first_column .. $last_column) {
		my $name = convert_column_number_into_letters( $column );
		$self->names->{$column} = [$name];
	}

	# Deal with the header row.
	$self->record_number( $self->worksheet->{'MinRow'} );
	$self->record_number_add( $self->skip );
	if (defined( $self->headers ) and $self->next_record) {
		my %headers = %{$self->headers};
		foreach my $number (keys %{$self->names}) {
			my $letter = $self->names ->{$number}[0];
			my $text   = $self->record->{$letter}   ;
			if (hascontent( $text )) {
				foreach my $pattern (keys %headers) {
					if ($text ~~ $pattern) {
						push( @{$self->names->{$number}}, $headers{$pattern} );
						delete $headers{$pattern};
						last;
					}
				}
			}
		}
	}
}


=head3 headers

This hash matches the column headers with standardized field names. In an
ideal world, the column headings would be the same between runs. We all know
the world isn't ideal. I<My ID> becomes I<MyID>, then I<MyId>, followed next
time by I<My Identifier>.

The keys to this hash are regular expressions. The L</setup> code finds the
first regular expression that matches a column header. When L</next_record>
reads the data, it uses the corresponding value as the field name. This way,
when the column header changes slightly, your code still gets the right data.

You should make sure that each regular expression matches only one column.

=cut

has 'headers' => (
	is  => 'rw',
	isa => 'HashRef[Str]',
);


=head3 skip

The number of rows to skip before the data starts. Some reporting software
adds page headers before the data. This setting jumps over those rows.

The attribute defaults to zero (do not skip rows). If your column headers
are in the first row of the spread sheet, then you want this set to zero.

B<Warning:> Do not skip over column headers. Use the L</headers> attribute
instead.

=cut

has 'skip' => (
	default => 0,
	is      => 'rw',
	isa     => 'Int',
);


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

=head3 convert_column_number_into_letters

This little method translates a column number into the letters that you see
in MS Excel. Computers like numbers. People like letters. This class lets you
identify columns by their letter designation.

=cut

sub convert_column_number_into_letters {
	my ($self, $column_number) = @_;

	if

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


=head3 names

A hash that maps column numbers to column names. When reading a record, the
code uses the name as a key for L<Data::ETL::Extract/record>. The I<transform>
phase then works with the field names instead of unwieldy column numbers.

Each column can have more than one name. We use both the column letter and the
header row as names.

=cut

has 'names' => (
	default => sub { {} },
	is      => 'ro',
	isa     => 'HashRef[ArrayRef[Str]]',
);


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
