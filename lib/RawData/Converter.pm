=pod

=head1 Description

The C<RawData::Converter> role translates a raw data file into your database
schema. The role handles common, abstract functions of the translation. It
provides a robust mapping system that handles most of your needs.

The consuming class defines a L</build_mapping> method, plus any methods
referenced in the mapping itself.

=cut

package RawData::Converter;
use Moose::Role;


=head1 Attributes & Methods

=over

=item build_mapping()

Return a hash of file fields and their conversion specifications. Your hash 
may look like this...
 {
   A => { data => 'Name' },
   B => { data => 'Date', pre => 'date_convert' },
   C => 'Age',
 }

The I<conversion specification> is itself a hash reference. The keys are
whatever you want. Your L</convert> method accesses this information.

I strongly suggest using the key B<data> as the database field name. 
L<RawData::Converter> automatically sets this key if you use a string
instead of a hash reference. In the example, do you see the C<< C => 'Age' >>?
L<RawData::Converter> changes that to C<< C => { data => 'Age' } >>.

You do not need to map every field from the input file. Map only the fields
required by your application. Ignore the rest. 

=cut

requires 'build_mapping';


=item build_model()

Return an L<DBIx::Class::ResultSet> object for the database table.

=cut

requires 'build_model';


=item build_parser()

Return a L<RawData> object corresponding to the input file format.

=cut

requires 'build_parser';


=item convert()

This abstract method will perform the actual translation. The process seems 
generic enough - until you think about it. Every conversion process has some
custom element. For example, we load one table that has fields always set to
a specific value. Another table needs some special processing before saving.

Rather than try and anticipate all of this, I put the responsibility where it
belongs - in the custom conversion class.

=cut

requires 'convert';


=item header_rows

The number of header rows before any data. You do not want to load the 
headers. This tells the file parser how many lines it can skip.

=cut

has 'header_rows' => (
	default => 0,
	is      => 'ro',
	isa     => 'Int',
);


=item log

A L<Moose::Log::Log4perl> object for reporting errors.

=cut

with 'Moose::Log::Log4perl';


=item mapping

Stores a hash of conversion specifications. You create this hash through the
L</build_mapping> method.

Key the hash with the file field name. This is the field name returned by the
L</parser> object. The data is another hash. See </build_mapping> for more
information.

=cut

subtype 'HashRefOfStr'
	=> as 'HashRef[Maybe[Str]]';

coerce  'HashRefOfStr'
	=> from 'Maybe[Str]',
	=> via { {data => $_} };

has 'mapping' => (
	builder => 'build_mapping',
	coerce  => 1,
	default => sub { {} },
	is      => 'ro',
	isa     => 'HashRef[HashRefOfStr]',
);


=item model

The L<DBIx::Class::ResultSet> for the database table. Your class sets this 
through the L</build_model> method.

=cut

has 'model' => (
	builder => 'build_model',
	is      => 'ro',
	isa     => 'DBIx::Class::ResultSet',
);


=item parser

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


=item records

A list of L<RawData::Record> objects created from the input file.

=cut

has 'records' => (
	default => sub { [] },
	is      => 'ro',
	isa     => 'ArrayRef[RawData::Record]',
);


=item trigger( attribute )

Loop through the field mapping and call the method named in this I<attribute>.
The method receives two parameters:

=over

=item 1 A L<RawData::Record> object.

=item 2 The file field name.

=back

=cut

sub trigger($$) {
	my ($self, $attribute) = @_;
	$self->log->debug( "Entering trigger..." );

	# Make a list of method names to call. The logic evaluates the same for
	# every record. So why do it over and over? I do it once, and then only 
	# fire the methods that pass muster.
	my %call_method;
	while (my ($file_field, $conversion) = each %{$self->mapping}) {
		if (exists $conversion->{$attribute}) {
			# Get the method name from the conversion specification.
			my $method_name = $conversion->{$attribute};

			# Get the method object so that we can execute this method.
			my $method = $self->meta->find_method_by_name( $method_name );

			# Save the method object for use in the next loop.
			if (defined $method) { $call_method{$file_field} = $method; }
			else { $self->log->error( "Missing method $method_name for attribute $attribute of field $file_field" ); }
		}
	}

	# Loop through every record, executing the methods...
	foreach my $record (@{$self->records}) {
		while (my ($file_field, $method) = each %call_method) {
			$method->execute( $self, $record, $file_field );
		}		
	}

	$self->log->debug( "...leaving trigger" );
}


=back

=cut


# Perl requires this to load the module.
1;

