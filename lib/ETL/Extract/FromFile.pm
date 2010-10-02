=pod

=head1 SYNOPSIS

 use Moose;
 extends 'ETL::Extract::FromFile';

=head1 DESCRIPTION

L<ETL::Extract> provides a very generic API for extracting data from a store
(database, file, etc). L<ETL::Extract::FromFile> adds more meat to the bones.
It provides functionality specifically for files.

L<ETL::Extract::FromFile> is an abstract base class. It performs nothing 
useful by itself. The child classes interface with the varied file formats.

=head2 Using ETL::Extract::FromFile

Child classes inherit from L<ETL::Extract::FromFile>, adding the necessary 
functionality. The child class actually reads a real file and returns data. 
Your application instantiates one of those children.

Why not use a L<role|Moose::Manual::Roles>? The 
L<inner/augment|Moose::Manual::MethodModifiers/INNER AND AUGMENT> relationship
better describes how L<ETL::Extract::FromFile> interacts with the child
class. Roles do not support 
L<inner/augment|Moose::Manual::MethodModifiers/INNER AND AUGMENT>.

=cut

package ETL::Extract::FromFile;
use Moose;

with 'ETL::Extract';


=head1 METHODS & ATTRIBUTES

=head2 L<Augment|Moose::Manual::MethodModifiers/INNER AND AUGMENT> in the Child Class

=head3 connect( $path [, @options...] )

I<connect> attaches L<ETL::Extract> with a file. Your augment method 
performs the actual I<open> command. This allows you to read files from Excel
and Word using existing modules.

Your code returns a boolean value. B<True> means the open succeeded - go ahead
and read records. B<False> means that you could not open the file.

I<connect> also returns a boolean:

=over

=item True

The C<open> command succeeded and the file is ready for processing.

=item False

An error prevented the file from opening and no data is available.

=back

=cut

sub connect($$;@) { 
	my ($self, $path, @options) = @_;
	$self->log->debug( __PACKAGE__ . '->connect called...' );

	# Reset the position to a default. The child method may change this to
	# something more suitable for the file type.
	$self->position( 0 );

	# Save the path name for use in error messages.
	$self->path( $path );

	# If the child fails, we act like the end of the file.
	if (inner()) {
		$self->log->debug( '...connect succeeded' );
		$self->end_of_input( 0 );
		return 1;
	} else {
		$self->log->debug( '...connect failed' );
		$self->end_of_input( 1 );
		return 0;
	}
}


=head3 extract()

This method reads the next record and breaks it apart into fields. It returns
an L<ETL::Extract::Record> object. An C<undef> means that we reached the end
of the file.

Your code fills in the following attributes of L<ETL::Extract::Record>...

=over

=item * L<data|ETL::Extract::Record/data>

=item * L<is_blank|ETL::Extract::Record/is_blank>

=back

Your code also sets the L<ETL::Extract/position> attribute.

=cut

sub extract($) { 
	my ($self) = @_;
	$self->log->debug( __PACKAGE__ . '->extract called...' );

	# Don't bother reading past the end of the file. Change the file name
	# to read more data.
	if ($self->end_of_input) {
		$self->log->debug( '...past the end of the file' );
		return undef;
	}

	# Always read the first line, if we're not at the end of the file. This
	# lets me put a debug message in the loop, and doesn't hurt performance
	# all that much.
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
			. $self->path
		);
		return $record;
	} else {
		$self->log->debug( '...end of file reached' );
		$self->end_of_input( 1 );
		return undef;
	}
}


=head2 Standard Attributes & Methods

=head3 log

This attrbiute accesses the logging subsystem. L<Log::Log4perl> provides a
very robust logging setup. Your application can configure the appropriate
setup. And L<RawData::Parser> uses it automatically.

=cut

with 'MooseX::Log::Log4perl';


=head3 path

This attribute holds the current file path. Changing this value has no
effect. Use the I<connect> method to read a new file.

=cut

has 'file' => (
	is      => 'rw',
	isa     => 'Str',
);


=head1 SEE ALSO

L<Log::Log4perl>, 
L<Moose::Manual::MethodModifiers/INNER AND AUGMENT>, 
L<ETL::Extract::Record>

=head1 LICENSE

Copyright 2010  The Center for Patient and Professional Advocacy, 
                Vanderbilt University Medical Center
Contact Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=cut

no Moose;
__PACKAGE__->meta->make_immutable;

