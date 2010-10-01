=pod

=head1 SYNOPSIS

 use Moose;
 extends 'RawData::Parser';

=head1 DESCRIPTION

A file parser reads data from an external file. This base class defines 
generic attributes and methods not dependent on the actual file type.

Unlike data models, the parser does not define fields as attributes. It 
creates a hash with the field name as the key. This data structure makes it
very easy to analyze data before mapping it into a real data model.

=head2 Using RawData::Parser

I<RawData::Parser> is an abstract base class. Technically, you can create an
instance. It does nothing useful, though. 

Child classes inherit from I<RawData::Parser>, adding the necessary 
functionality. The child class actually reads a real file and returns data. 
Your application instantiates one of those children.

Why not use a L<role|Moose::Manual::Roles>? The 
L<inner/augment|Moose::Manual::MethodModifiers/INNER AND AUGMENT> relationship
better describes how I<RawData::Parser> interacts with the child class. Roles
do not support 
L<inner/augment|Moose::Manual::MethodModifiers/INNER AND AUGMENT>.

=cut

package RawData::Parser;
use Moose;


=head1 METHODS & ATTRIBUTES

=head2 L<Augment|Moose::Manual::MethodModifiers/INNER AND AUGMENT> in the Child Class

=head3 open( $new_path, $old_path )

This method opens a new file. The object automatically calls this method when
the file name changes. It receives the new and old values as parameters. Refer
to L<Moose::Manual::Attributes/Triggers> for more information.

Your code returns a boolean value. B<True> means the open succeeded - go ahead
and read records. B<False> means that you could not open the file.

=cut

sub open($$$) { 
	my ($self, $new_path, $old_path) = @_;

	$self->log->debug( __PACKAGE__ . '->open called' );
	$self->log->debug( "New file name: $new_path" );

	# Reset the position to a default. The child method may change this to
	# something more suitable for the file type.
	$self->position( 0 );

	# If the child fails, we act like the end of the file.
	if (inner()) {
		$self->end_of_file( 0 );
		return 1;
	} else {
		$self->end_of_file( 1 );
		return 0;
	}
}


=head3 read_one_record()

This method reads the next record from the file and breaks it apart into
fields. It returns a reference to a L<RawData::Record> object. An C<undef>
means that we reached the end of the file and sets the L</end_of_file> 
attribute.

Your code fills in the following attributes of L<RawData::Record>...

=over

=item * L<data|RawData::Record/data>

=item * L<is_blank|RawData::Record/is_blank>

=back

Your code also sets its own L</position> attribute.

=cut

sub read_one_record($) { 
	my ($self) = @_;
	$self->log->debug( __PACKAGE__ . '->read_one_record called' );

	# Don't bother reading past the end of the file. Change the file name
	# to read more data.
	if ($self->end_of_file) {
		$self->log->debug( 'At the end of the file' );
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
		$record->came_from( 
			'record ' 
			. $self->position 
			. ' in ' 
			. $self->file
		);
		return $record;
	} else {
		$self->end_of_file( 1 );
		return undef;
	}
}


=head2 Standard Attributes & Methods

=head3 end_of_file

This attribute indicates when we have reached the end of the input file. 

This attribute does not reset the file when it changes from 1 to 0. You
should set the L</file> attribute instead.

So why bother with L</end_of_file>? Each child class has its own file 
handling code. And I cannot rely on them providing a standard Perl file 
handle. This attribute works regardless of the input file format.

=cut

has 'end_of_file' => (
	default => 0,
	is      => 'rw',
	isa     => 'Bool',
);


=head3 file

This attribute holds the current file path. Setting the file name stops
reading the current file and starts the new one.

=cut

has 'file' => (
	is      => 'rw',
	isa     => 'Str',
	trigger => sub { my $self = shift; $self->open( @_ ); },
);


=head3 log

This attrbiute accesses the logging subsystem. L<Log::Log4perl> provides a
very robust logging setup. Your application can configure the appropriate
setup. And L<RawData::Parser> uses it automatically.

=cut

with 'MooseX::Log::Log4perl';


=head3 position

This attribute records the position of the record just read from the file. 
The exact value depends on the file type. For example, a text file might have
the line number. A spreadsheet would keep the row number. We use this 
information to track down errors.

After calling L</read_one_record>, this attribute holds the position of
that record - not the next one. It's value is undefined before reading the
first record.

Changing this value may or may not have an effect on the actual file 
position. It depends entirely on the actual file format. So B<do not> use
this as a means of skipping records.

=cut

has 'position' => (
	default => 0,
	is      => 'rw',
	isa     => 'Str',
);


=head1 SEE ALSO

L<Log::Log4perl>, 
L<Moose::Manual::MethodModifiers/INNER AND AUGMENT>, 
L<RawData::Record>

=head1 LICENSE

Copyright 2010  The Center for Patient and Professional Advocacy, 
Vanderbilt University Medical Center

Contact Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=cut

no Moose;
__PACKAGE__->meta->make_immutable;

