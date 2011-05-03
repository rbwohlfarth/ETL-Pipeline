=pod

=head1 NAME

ETL::Extract::File::DelimitedText - Read data from CSV files

=head1 DESCRIPTION

L<ETL::Extract::File::DelimitedText> handles text files with a field
separator (I<comma separated variable> or I<CSV>). The separator is anything
acceptable to L<Text::CSV> - comma, pipe, tab, whatever. The L<Text::CSV>
module handles separators that appear inside of quotes or after escape
characters. This should cover most delimited files.

=cut

package ETL::Extract::File::DelimitedText;
use Moose;

extends 'ETL::Extract::File';

use ETL::Record;
use Text::CSV;


=head1 METHODS & ATTRIBUTES

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


=head3 handle

The Perl file handle for reading data.

=cut

has 'handle' => (
	is  => 'rw',
	isa => 'Maybe[FileHandle]',
);


=head3 open()

This code opens the file for reading.

=cut

augment 'open' => sub {
	my ($self) = @_;

	# Open the new file for reading. Failure = end of file.
	my $path = $self->source;
	my $handle;

	$self->log->logdie( "Unable to open '$path' for reading" )
		unless open( $handle, '<', $path );

	$self->handle( $handle );
};


=head1 SEE ALSO

L<ETL::Extract::File>, L<ETL::Record>, L<Text::CSV>

=head1 LICENSE

Copyright 2010  The Center for Patient and Professional Advocacy, Vanderbilt University Medical Center
Contact Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=cut

no Moose;
__PACKAGE__->meta->make_immutable;