=pod

=head1 NAME

Data::ETL::Extract::DelimitedText - Input source for CSV files

=head1 SYNOPSIS

  use ETL;
  working_folder 'C:\Data';
  extract_from 'DelimitedText', find_file => qr/\.csv$/;
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

You use this class by naming it in the L<Data::ETL/extract_from> call. You
would not normally use it directly.

=cut

package Data::ETL::Extract::DelimitedText;
use Moose;

use strict;
use warnings;

use 5.014;
use Text::CSV;


our $VERSION = '1.00';


=head1 METHODS & ATTRIBUTES

=head2 Set with the L<Data::ETL/extract_from> command

See L<Data::ETL::Extract::File> and L<Data::ETL::Extract::AsHash> for a list
of attributes.

=cut

with 'Data::ETL::Extract::AsHash';
with 'Data::ETL::Extract::File';


=pod

In addition, B<Data::ETL::Extract::DelimitedText> makes available all of the
options for L<Text::CSV>. See L<Text::CSV> for a list.

=cut

sub BUILD {
	my $self= shift;
	my $arguments = shift;

	my %options;
	while (my ($key, $value) = each %$arguments) {
		$options{$key} = $value unless $self->meta->has_attribute( $key );
	}

	$self->csv( Text::CSV->new( \%options ) );
}


=head3 has_field_names

Most CSV files contain a header row that names the columns. By default, this
class assumes that the first row are column names. Set this attribute to
B<false> if that's not the case. Otherwise you will lose the first row of data.

=cut

has '+has_field_names' => (default => 1);


=head2 Automatically called from L<Data::ETL/run>

=head3 next_record

Read one record from the file and populate L<Data::ETL::Extract/record>. The
method returns the number of records loaded. A B<0> means that we reached the
end of the file.

C<next_record> uses the field number as the name. Field numbers start at B<0>.

=cut

sub next_record {
	my ($self, $max_records) = @_;

	my $fields = $self->csv->getline( $self->file );
	if (defined $fields) {
		my %record;
		$record{$_} = $fields->[$_] foreach (0 .. $#$fields);
		$self->record( \%record );
		return 1;
	} else { return 0; }
}


=head3 setup

This method configures the input source. In this object, that means opening
the file and looking for a header record. If the file has a header row, then
I name the fields based on the header row. You can identify data by the
field name or by the column name. See L<Data::ETL::Extract::AsHash/headers>
for more information.

=cut

sub setup {
	my ($self) = @_;

	# Open the new file for reading. Failure = end of file.
	my $path = $self->path;
	my $handle;

	die "Unable to open '$path' for reading"
		unless open( $handle, '<', $path );

	$self->file( $handle );
}


=head3 finished

This method shuts down the input source. In our case, it does nothing.

=cut

sub finished { close shift->file; }


=head2 Internal Attributes and Methods

You should never use these items. They can change at any moment. I documented
them for the module maintainers.

=head3 csv

The L<Text::CSV> object for doing the actual parsing work. Using the module
lets me build on the bug fixes and hard learned lessons of others.

You can set the options in the L<Data::ETL/extract_from> command. The
constructor passes them through when it creates this object.

=cut

has 'csv' => (
	is  => 'rw',
	isa => 'Text::CSV',
);


=head3 file

The Perl file handle for reading data. L<Text::CSV> operates on a handle.

=cut

has 'file' => (
	is  => 'rw',
	isa => 'Maybe[FileHandle]',
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
