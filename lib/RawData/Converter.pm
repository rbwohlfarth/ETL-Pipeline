=pod

=head1 SYNOPSIS

 use Moose;
 with 'RawData::Converter';

=head1 DESCRIPTION

The C<RawData::Converter> role translates a raw data file into your database
schema. The role handles common, abstract functions of the translation. It
provides a robust mapping system that handles most of your needs.

The conversion methods work on individual records. Your application should
provide temporary storage for the data (aka lists). I tried putting that
inside this role. It made the thing even more complex. For every method, I had
to decide if it works on single records or the entire list. This meant that
you could not adapt it for your needs. It hid too much of the application
design behind the class definition.

=cut

package RawData::Converter;
use Moose::Role;


=head1 METHODS & ATTRIBUTES

=head2 Override These in the Consuming Class

=head3 build_mapping()

Return a hash of conversion specifications. Your hash may look like this...

 {
   Name => 'A',
   Date => 'B',
   Age  => 'C',
 }

The keys are your database fields. The code copies data from the file into 
these fields. 

The value is the file field name from the L</parser>. The conversion process 
pulls data from this file field and places it into the database field (the 
hash key).

You do not need to map every field from the input file. Map only the fields
required by your application. Ignore the rest. 

=cut

requires 'build_mapping';


=head3 build_model()

Return an L<DBIx::Class::ResultSet> object for the database table.

=cut

requires 'build_model';


=head3 build_parser()

Return a L<RawData> object corresponding to the input file format.

=cut

requires 'build_parser';


=head3 header_rows

The number of header rows before any data. You do not want to load the 
headers. This tells the file parser how many lines it can skip.

=cut

has 'header_rows' => (
	default => 0,
	is      => 'ro',
	isa     => 'Int',
);


=head2 Standard Attributes & Methods

=head3 convert( $record )

Map the file fields into the proper database fields. This method applies the
field mapping to an individual record.

Your conversion process may require more. For example, perhaps you L</trigger> 
validation code before the conversion. L<RawData::Converter> provides two ways
to handle this:

=over

=item 1. Put the call in your application.

=item 2. Override this class

You can use the 
L<before, after, or around|Moose::Manual::MethodModifiers/BEFORE, AFTER, AND AROUND>
method modifiers.

=back

=cut

sub convert($$) {
	my ($self, $record) = @_;

	my $mapping = $self->mapping;
	foreach my $database (keys %$mapping) {
		my $file = $mapping->{$database}->{'file'};
		$self->model->set_field( $database, $record->data->{$file} )
			if (defined $file);
	}
}


=head3 error( $message, $record )

Log an error message for the given record. Call this from your validation code.
It ensures a consistent format in error messages.

=cut

sub error($$$) {
	my ($self, $message, $record) = @_;
	$self->log->error( "$message at " . $record->came_from );
}


=head3 log

A L<Moose::Log::Log4perl> object for reporting errors.

=cut

with 'Moose::Log::Log4perl';


=head3 mapping

Stores a hash of conversion specifications. You create this hash through the
L</build_mapping> method.

Key the hash with the database field name. The conversion process pulls data
from the file. This is what you do manually - look at the fields you need, then
see which file fields correspond.

=cut

has 'mapping' => (
	builder => 'build_mapping',
	is      => 'ro',
	isa     => 'HashRef[Str]',
);


=head3 model

The L<DBIx::Class::ResultSet> for the database table. Your class sets this 
through the L</build_model> method.

=cut

has 'model' => (
	builder => 'build_model',
	is      => 'ro',
	isa     => 'DBIx::Class::ResultSet',
);


=head3 parser

A L<RawData::File> object for parsing the file. Create an object of the
correct type for this client's data.

Your class creates this object through the 
L<default|Moose::Manual::Attributes/Default and builder methods> attribute
modifier.
=cut

has 'parser' => (
	builder => 'build_parser',
	is      => 'ro',
	isa     => 'RawData::File',
);


=head1 SEE ALSO

L<DBIx::Class::ResultSet>, L<RawData>, L<RawData::File>

=head1 LICENSE

Copyright 2010  The Center for Patient and Professional Advocacy,
Vanderbilt University Medical Center

Contact Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=cut

# Perl requires this to load the module.
1;

