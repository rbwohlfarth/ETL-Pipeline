=pod

=head1 NAME

ETL::Extract::File - Input data from any type of file

=head1 DESCRIPTION

L<ETL::Extract::File> adds meat to the bones of the L<ETL::Extract> API. It
provides functionality specifically for files - B<any> type of file. Child 
classes further specify file types (CSV, spreadsheet, etc.).

=cut

package ETL::Extract::File;
use Moose;

extends 'ETL::Extract';


=head1 METHODS & ATTRIBUTES

=head2 Override in the Child Class

=head3 extract()

This method reads the next record and breaks it apart into fields. It returns
an L<ETL::Record> object. C<undef> means that we reached the end of the file.

The child class L<augments|Moose::Manual::MethodModifiers/INNER AND AUGMENT> 
C<extract>. The L<inner|Moose::Manual::MethodModifiers/INNER AND AUGMENT> code 
fills in these L<ETL::Record> attributes...

=over

=item * L<data|ETL::Record/raw>

=item * L<is_blank|ETL::Record/is_blank>

=back

The I<inner> code also sets the L<ETL::Extract/position> attribute.

=cut

augment 'extract' => sub { 
	my ($self) = @_;
	$self->log->debug( __PACKAGE__ . '->extract called...' );

	$self->open unless $self->_opened;

	# Reading the first line lets me put a debug message in the loop.
	my $record = inner();

	# This loop accomplishes three things...
	#   1. It stops reading once we reach the end of the file.
	#   2. It skips completely blank records.
	#   3. Calls the format specific parsing code.
	while (ref( $record ) and $record->is_blank) {
		$self->log->debug( 'Blank record skipped' );
		$record = inner();
	}

	# Set the location information in the record. Error messages can then
	# reference the original file and line number.
	if (ref( $record )) {
		$self->log->debug( '...record loaded' );
		$record->came_from( 
			'record ' 
			. $self->position 
			. ' in ' 
			. $self->source
		);
		return $record;
	} else {
		$self->log->debug( '...end of file reached' );
		return undef;
	}
};


=head3 open()

Open the file for reading. The child class 
L<augments|Moose::Manual::MethodModifiers/INNER AND AUGMENT> this method with
its own specific code. If an error occurs, call C<$self->log->logdie>.

=cut

sub open {
	my ($self) = @_;

	# The child class actually opens the file.
	inner();
	$self->_opened( 1 );
	
	# Skip over the header rows. We simply ignore them.
	for (1 .. $self->headers) {
		unless (defined $self->extract) {
			$self->end_of_input( 1 );
			$self->log->debug( '...end of file reached' );
			last;
		}
	}
}


# Bypass header records from the input source. User code should never set 
# this value. It is internal to the object and will cause data loss.
has '_opened' => (
	default => 0,
	is      => 'rw',
	isa     => 'Bool',
);


=head2 Standard Methods & Attributes

=head3 BUILD

The constructor can automatically search the file system for matching files. 
When calling C<new()>, set the C<pattern> attribute to a glob or regular
expression. This method then looks for a file that matches the pattern. See the
L</find( $pattern[, $directory )> method for more information.

If you would like to search a particular directory, set the C<source> attribute
to the directory name. B<Warning:> C<source> must be a directory name. If you
pass a file name, L<ETL::Extract::File> opens that exact file without 
searching. The C<source> attrbiute overrides the C<pattern> attribute.

=cut

sub BUILD {
	my ($self, $parameters) = @_;

	if (
		defined( $parameters->{source} ) 
		and -d $parameters->{source}
		and defined( $parameters->{pattern} )
	) {
		$self->find( $parameters->{pattern}, $parameters->{source} );
	} elsif (
		not defined( $parameters->{source } )
		and defined( $parameters->{pattern} )
	) {
		$self->find( $parameters->{pattern} );
	}
}


=head3 find( $pattern[, $directory] )

Search the file system for a single file that matches a given criteria. On 
success, the function sets the L<source|ETL::Extract/source> attribute to the
full path name and returns null.

If the search fails, the function returns an error message.

=cut

sub find {
	my ($self, $pattern, $directory) = @_;

	$directory = (defined( $directory ) ? $directory : '.');
	my @matches = File::Find::Rule->file->name( $pattern )->in( $directory );

	return "More than 1 data file in $directory" if scalar( @matches ) > 1;
	return "No data file found in $directory"    if scalar( @matches ) < 1;
	
	$self->source( $matches[0] );
	return '';
}


=head3 headers

The number of header rows. Header rows usually contain meta data - such as 
column names. They are very useful for humans.

C<ETL::Extract::File> ignores header rows. It automatically skips over them. So
L</extract()> always returns actual data.

=cut

has 'headers' => (
	default => 0,
	is      => 'rw',
	isa     => 'Int',
);


=head3 log

This attrbiute provides an access point into the L<Log::Log4perl> logging
system. C<ETL> logs all warning and error messages. Users can run the 
application, and I do not need to ask them for error messages. The log file
always has a copy.

=cut

with 'MooseX::Log::Log4perl';


=head1 SEE ALSO

L<ETL::Extract>, L<ETL::Record>, 
L<Moose::Manual::MethodModifiers/INNER AND AUGMENT>

=head1 LICENSE

Copyright 2011  The Center for Patient and Professional Advocacy, Vanderbilt University Medical Center
Contact Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
