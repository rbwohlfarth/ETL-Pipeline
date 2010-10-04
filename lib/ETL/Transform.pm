=pod

=head1 SYNOPSIS

 use Moose;
 with 'ETL::Transform';

=head1 DESCRIPTION

The L<ETL::Transform> role translates raw data into a hash with standard
field names. You can then store the hash in a databse, display it to the
user, or whatever else you need. C<RawData::Converter> provides a robust
mapping system that handles most of your needs.

The conversion methods work on individual records. Your application should
provide temporary storage for the data (aka I<lists>). I tried putting that
inside this role. It made the thing even more complex. For every method, I had
to decide if it works on single records or the entire list. This meant that
you could not adapt it for your needs. It hid too much of the application
design behind the class definition.

=cut

package ETL::Transform;
use Moose::Role;


=head1 METHODS & ATTRIBUTES

=head2 Define These in the Consuming Class

=head3 build_mapping()

Return a hash reference. The hash links field names with the corresponding 
input name. This example maps a spreadsheet. Column A goes into the I<Name>
field, B into I<Date>, etc.

 {
   Name => 'A',
   Date => 'B',
   Age  => 'C',
 }

The keys are your standard field names. The values are the input field names. 
You should read the example as saying I<fill the Name field from column A>. 
This layout makes it easy to see where your data originated.

You do not need to map every field from the input. Map only the fields
required by your application. Ignore the rest. 

=cut

requires 'build_mapping';


=head3 log

You create this attribute with the command C<with 'MooseX::Log::Log4perl>. It
holds a L<Log::Log4perl> instance. L<Log::Log4perl> provides a very robust
logging setup. You can configure the appropriate setup in one place, and
L<ETL::Load> uses it automatically.

Why doesn't L<ETL::Load> define it? L<ETL::Extract>, L<ETL::Transform>, and
L<ETL::Load> all use the same attribute. I expect your application classes 
consume all three of these. Each definition would interfere with the others.
So I require the consuming class to define it once for all three.

=cut

requires 'log';


=head2 Standard Attributes & Methods

=head3 error( $message, $record )

Log an error message for the given record. Call this from your validation 
code. It ensures a consistent format in error messages.

=cut

sub error($$$) {
	my ($self, $message, $record) = @_;

	$self->log->error( "$message at " . $record->came_from );
}


=head3 mapping

Stores a hash linking the database fields to the file fields. This is the
heart of the conversion process.

Key the hash with the database field name. The conversion process pulls data
from the file. This is what you do manually - look at the fields you need, 
then see which file fields correspond.

The L</build_mapping()> method creates this hash.

=cut

has 'mapping' => (
	builder => 'build_mapping',
	is      => 'ro',
	isa     => 'HashRef[Str]',
);


=head3 transform( $record )

Convert an L<ETL::Extract::Record> into a standardized hash.

L<ETL::Transform> does not perform any formatting or validation on the
data. Your application should provide that functionality by:

=over

=item 1. Calling validation/formatting code from the application.

=item 2. Or using method modifiers such as L<before, after, and around|Moose::Manual::MethodModifiers/BEFORE, AFTER, AND AROUND> 
method modifiers.

=back

In a scalar context, C<transform> returns a hash reference. In array context,
it returns the hash contents. 

=cut

sub transform($$) {
	my ($self, $record) = @_;

	my %data    = ();
	my $mapping = $self->mapping;

	while (my ($to, $from) = each %$mapping) {
		$data{$to} = $record->data->{$from} if defined $from;
	}

	return (wantarray ? %data : \%data);
}


=head1 SEE ALSO

L<ETL::Extract>, L<ETL::Extract::Record>

=head1 LICENSE

Copyright 2010  The Center for Patient and Professional Advocacy,
                Vanderbilt University Medical Center
Contact Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=cut

# Perl requires this to load the module.
1;

