=pod

=head1 SYNOPSIS

 use RawData::DelimitedText;
 my $parser = new RawData::DelimitedText( separator => '|' );
 
 # Open a spreadsheet for reading.
 $parser->file( 'C:\InputData.txt' );

 # Read the file, one record at a time.
 while (my $record = $parser->read_one_record) {
     # Do stuff here...
 }

=head1 DESCRIPTION

This class handles text files with a field separator. The separator is 
anything acceptable to L<Text::CSV> - comma, pipe, tab, whatever. The
L<Text::CSV> module handles separators that appear inside of quotes or after
escape characters. This should cover most delimited files.

=cut

package RawData::DelimitedText;
use Moose;

extends 'RawData::File';

use RawData::Record;
use String::Util qw/hascontent/;
use Text::CSV;


=head2 Attributes & Methods

=head3 file_handle

The Perl file handle for reading data.

=cut

has 'file_handle' => (
	is  => 'rw',
	isa => 'Maybe[FileHandle]',
);


=head3 open( $new_path, $old_path )

Perl automatically triggers this code when the C<file> attribute changes.
It closes any open file, and opens the new one.

=cut

augment 'open' => sub {
	my ($self, $new_path, $old_path) = @_;
	$self->log->debug( __PACKAGE__ . '->open called' );

	# Close the old file, if it's open.
	close $self->file_handle if (defined $self->file_handle);

	# Open the new file for reading.
	open( my $handle, '<', $new_path )
		or $self->log->logdie( "Unable to open '$new_path' for reading" );
	$self->file_handle( $handle );

	return 1;
};


=head3 parser

The L<Text::CSV> object for doing the actual parsing work. Using the module
lets me build on the bug fixes and hard learned lessons of others.

=cut

has 'parser' => (
	default => sub { new Text::CSV; },
	is      => 'ro',
	isa     => 'Text::CSV',
);


=head3 read_one_record()

This method populates a L<PARS::Record> with information from the file.

This code sets the position to the line number last read. Line numbers
begin at 1 - not 0.

=cut

augment 'read_one_record' => sub {
	my ($self) = @_;

	# The last read hit the end of the input file.
	return undef if ($self->parser->eof);

	# Read one line and break it into fields.
	my $fields = $self->parser->getline( $self->file_handle );
	$self->position( $self->position + 1 );

	# Generate a record object...
	if (defined( $fields ) and (scalar( @$fields ) > 0)) {
		return RawData::Record->from_array( $fields );
	} else {
		return new RawData::Record( is_blank => 1 );
	}
};


=head1 SEE ALSO

L<RawData::File>, L<Text::CSV>

=head1 LICENSE

Copyright 2010  The Center for Patient and Professional Advocacy, Vanderbilt University Medical Center

=cut

no Moose;
__PACKAGE__->meta->make_immutable;

