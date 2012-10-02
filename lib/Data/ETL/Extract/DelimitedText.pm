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

C<next_record> uses the field number as the name. Field numbers start at B<0>.

=cut

sub next_record {
	my ($self) = @_;

	my $fields = $self->csv->getline( $self->file );
	if (defined $fields) {
		my %record;
		$record{$_} = $fields->[$_] foreach (0 .. $#$fields);
		$self->record( \%record );
		return 1;
	} else { return 0; }
}


=head3 get

Return the value of a field from the current record. The only parameter is a
field name. You can use either the column letter or the field name.

=cut

sub get { $_[0]->record->{$_[1]}; }


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
}


=head3 finished

This method shuts down the input source. In our case, it does nothing.

=cut

sub finished { close shift->file; }


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
