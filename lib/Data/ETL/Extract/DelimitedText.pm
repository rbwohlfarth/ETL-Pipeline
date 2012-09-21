=pod

=head1 NAME

Data::ETL::Extract::DelimitedText - Input source for CSV files

=head1 SYNOPSIS

  use ETL;
  extract_using 'DelimitedText', root => 'C:\Data', file_name => qr/\.csv$/;
  transform 1 => ExternalID, Name => PatientName;
  load_into 'Access';
  run;

=head1 DESCRIPTION

B<ETL> stands for I<Extract-Transform-Load>. You often hear this design
pattern associated with Data Warehousing. In fact, ETL works with almost
any type of data conversion. You read the source (I<Extract>), translate the
data for your target (I<Transform>), and store the result (I<Load>).

This class defines an ETL input source that reads CSV files. Actually, the
class supports any delimiter - not just commas. You can use any delimiter
supported by the L<Text::CSV> module.

L<Text::CSV> automatically handles delimiters inside of quote marks. So your
data can have embedded commas.

You use this class by naming it in the L<Data::ETL/extract_using> call. You
would not normally use it directly.

=cut

package Data::ETL::Extract::DelimitedText;
use Moose;

with 'Data::ETL::Extract';
with 'Data::ETL::Extract::File';

use Text::CSV;


=head1 METHODS & ATTRIBUTES

=head3 next_record

Read one record from the file and populate L<Data::ETL::Extract/record>. The
method returns the number of records loaded. A B<0> means that we reached the
end of the file.

C<next_record> uses the field number as the name. If you define field names
using L</headers>, then C<next_record> also sets those fields in
L<Data::ETL::Extract/record>. You can mix and match the field numbers and the
field names in the transform process.

=cut

sub next_record {
	my ($self) = @_;

	my $fields = $self->csv->getline( $self->file );

	if (defined $fields) {
		my $names = $self->names;
		my %record;

		foreach my $index (0 .. $#$fields) {
			$record{$index} = $fields->[$index];
			$record{$names->[$index]} = $fields->[$index]
				if defined $names->[$index];
		}

		$self->record( \%record );
		return 1;
	} else { return 0; }
}


=head3 setup

This method configures the input source. In this object, that means opening
the file and looking for a header record. If the file has a header row, then
I name the fields based on the header row. You can identify data by the
field name or by the column name. See L</headers> for more information.

=cut

sub setup {
	my ($self) = @_;

	# Open the new file for reading. Failure = end of file.
	my $path = $self->path;
	my $handle;

	die "Unable to open '$path' for reading"
		unless open( $handle, '<', $path );

	$self->file( $handle );

	# Process the header row, but only if we're expecting headers. Most often
	# the data begins in the first row. I don't want to miss the first record.
	if (defined( $self->headers ) and $self->next_record) {
		# Copy the headers so that I can remove them as I match them.
		my %headers = %{$self->headers};

		# The record has index numbers as the key. I want to add the names to
		# a list in the same order as the data fields.
		foreach my $field (sort keys %{$self->record}) {
			$text = $self->record->{$field};
			if (hascontent( $text )) {
				# I used "foreach" to break out of the loop early. "each"
				# remembers its position and would start the next loop skipping
				# over some of the patterns.
				foreach my $pattern (keys %headers) {
					if ($text ~~ $pattern) {
						push( @{$self->names}, $headers{$pattern} );
						delete $headers{$pattern};
						last;
					}
				}

				# Quit looking when we run out of field names.
				last unless scalar( %headers );
			}
		}
	}
}


=head3 headers

This hash matches the field headers with standardized field names. The first
row of your CSV file may contain field names. A lot of software expects you to
read these files in MS Excel. We can use those field names instead of numbers.

In an ideal world, the field headings would be the same between runs. We all
know the world isn't ideal. I<My ID> becomes I<MyID>, then I<MyId>, followed
next time by I<My Identifier>.

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


=head3 finished

This method shuts down the input source. In our case, it does nothing.

=cut

sub finished { close $self->file; }


=head2 Internal Attributes and Methods

You should never use these items. They can change at any moment. I documented
them for the module maintainers.

=head3 csv

The L<Text::CSV> object for doing the actual parsing work. Using the module
lets me build on the bug fixes and hard learned lessons of others.

=cut

has 'csv' => (
	default => sub { Text::CSV->new; },
	is      => 'ro',
	isa     => 'Text::CSV',
	handles => {seperator => 'sep_char'},
);


=head3 file

The Perl file handle for reading data. L<Text::CSV> operates on a handle.

=cut

has 'file' => (
	is  => 'rw',
	isa => 'Maybe[FileHandle]',
);


=head3 names

A hash that maps column numbers to column names. When reading a record, the
code uses the name as a key for L<Data::ETL::Extract/record>. The I<transform>
phase then works with the field names instead of unwieldy column numbers.

Each column can have more than one name. We use both the column letter and the
header row as names.

=cut

has 'names' => (
	default => sub { [] },
	is      => 'ro',
	isa     => 'ArrayRef[Str]',
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










=head1 METHODS & ATTRIBUTES

=head3 augment extract()

This method populates an L<ETL::Record> with data from the file.

This code sets the position to the line number last read. Line numbers
begin at 1 - not 0.

=cut

augment 'extract' => sub {
	my ($self) = @_;

	# Read one line and break it into fields.
	my $fields = $self->csv->getline( $self->handle );
	$self->position( $self->position + 1 );

	# Generate a record object...
	if (defined $fields) {
		if (scalar( @$fields ) > 0) {
			return ETL::Record->from_array( $fields );
		} else {
			return new ETL::Record( is_blank => 1 );
		}
	} else { return undef; }
};


