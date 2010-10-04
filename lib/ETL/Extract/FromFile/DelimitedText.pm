=pod

=head1 SYNOPSIS

 use ETL::Extract::FromFile::DelimitedText;
 my $parser = new ETL::Extract::FromFile::DelimitedText;
 
 # Open a pipe delimited file for reading.
 $parser->connect( 'C:\InputData.txt', '|' );

 # Read the file, one record at a time.
 while (my $record = $parser->extract) {
     # Do stuff here...
 }

=head1 DESCRIPTION

L<ETL::Extract::FromFile::DelimitedText> handles text files with a field
separator (I<comma separated variable> or I<CSV>). The separator is anything
acceptable to L<Text::CSV> - comma, pipe, tab, whatever. The L<Text::CSV>
module handles separators that appear inside of quotes or after escape
characters. This should cover most delimited files.

=cut

package ETL::Extract::FromFile::DelimitedText;
use Moose;

extends 'ETL::Extract::FromFile';

use ETL::Extract::Record;
use Text::CSV;


=head1 METHODS & ATTRIBUTES

=head3 csv

The L<Text::CSV> object for doing the actual parsing work. Using the module
lets me build on the bug fixes and hard learned lessons of others.

=cut

has 'csv' => (
	default => sub { new Text::CSV; },
	is      => 'ro',
	isa     => 'Text::CSV',
);


=head3 augment extract()

This method populates an L<ETL::Extract::Record> with data from the file.

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
			return ETL::Extract::Record->from_array( $fields );
		} else {
			return new ETL::Extract::Record( is_blank => 1 );
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


=head3 augment input( $path [, $seperator] )

C<input> creates and configures a L<Text::CSV> object for accessing the
data.

=cut

augment 'input' => sub {
	my ($self, $path, $seperator) = @_;
	$self->log->debug( __PACKAGE__ . '->connect called...' );

	# Open the new file for reading. Failure = end of file.
	my $handle;
	unless (open( $handle, '<', $path )) {
		$self->log->fatal( "Unable to open '$path' for reading" );
		return 0;
	}

	$self->handle( $handle );

	# Set the seperator for parsing.
	$self->csv->seperator( $seperator ) if defined $seperator;

	# Tell the surrounding code that we're good to go.
	return 1;
};


=head1 SEE ALSO

L<ETL::Extract::FromFile>, L<ETL::Extract::Record>, L<Text::CSV>

=head1 LICENSE

Copyright 2010  The Center for Patient and Professional Advocacy, 
                Vanderbilt University Medical Center
Contact Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=cut

no Moose;
__PACKAGE__->meta->make_immutable;

