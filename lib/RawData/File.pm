=pod

=head1 Description

A file parser reads data from an external data file. This base class defines 
generic attributes and methods not dependent on the actual file type.

Unlike data models, the parser does not define fields as attributes. It 
creates a hash with the field name as the key. This data structure makes it
very easy to analyze data before mapping it into PARS.

=cut

package RawData::File;
use Moose;


=head1 Define these in the child class

=over

=item open

This method opens a new file. The object automatically calls this method when
the file name changes. It receives the new and old values as parameters. Refer
to L<Moose::Manual::Attributes/Triggers> for more information.

Your code returns a boolean value. B<True> means the open succeeded - go ahead
and read records. B<False> means that you could not open the file.

Child classes (what you're writing) 
L<augment|Moose::Manual::MethodModifiers/INNER AND AUGMENT> this method.

=cut

sub open($$$) { 
	my ($self, $new_path, $old_path) = @_;

	$self->log->debug( __PACKAGE__ . '->open called' );
	$self->log->debug( "New file name: $new_path" );

	# Reset the position to a default. The "open" method may change this
	# to something more suitable for the file type.
	$self->position( 0 );

	# If "open" fails, we act like the end of the file.
	if (inner()) {
		$self->_set_end_of_file( 0 );
	} else {
		$self->_set_end_of_file( 1 );
	}
}


=item read_one_record

This method reads the next record from the file and breaks it apart into
fields. It returns a reference to a L<RawData::Record> object. An C<undef>
means that we reached the end of the file.

Child classes (what you're writing) 
L<augment|Moose::Manual::MethodModifiers/INNER AND AUGMENT> this method. Your 
code fills in the following attributes of L<RawData::Record>...

=over

=item L<data|RawData::Record/data>

=item L<is_blank|RawData::Record/is_blank>

=back

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
		$record->came_from( 'record ' . $self->position . ' in ' . $self->file );
		return $record;
	} else {
		$self->_set_end_of_file( 1 );
		return undef;
	}
}


=back

=head1 Attributes & Methods

=over

=item end_of_file

This attribute indicates when we have reached the end of the input file. The
code sets this flag when L</open> returns B<false>. You cannot set its value.

=cut

has 'end_of_file' => (
	default => 0,
	is      => 'ro',
	isa     => 'Bool',
	writer  => '_set_end_of_file',
);


=item file

This attribute holds the current file path. Setting the file name stops
reading the current file and starts the new one.

=cut

has 'file' => (
	is      => 'rw',
	isa     => 'Str',
	trigger => sub { my $self = shift; $self->open( @_ ); },
);


=item log

This attribute prints debugging messages. I used the logger because it is easy
to later switch from the screen to an actual log file.

=cut

with 'MooseX::Log::Log4perl';


=item position

This attribute records the current record from the file. The exact value
depends on the file type. For example, a text file might have the line
number. A spreadsheet would keep the row number. We use this information
to track down errors.

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


=back

=cut

no Moose;
__PACKAGE__->meta->make_immutable;

