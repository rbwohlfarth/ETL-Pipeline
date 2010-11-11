=pod

=head1 NAME

ETL - Translating Data

=head1 DESCRIPTION

B<ETL> stands for I<Extract-Transform-Load>. You often hear this design
pattern associated with Data Warehousing. In fact, ETL works with almost
any type of data conversion. You read the source (I<extract>), translate the
data for your target (I<Transform>), and store the result (I<Load>).

By dividing a conversion into 3 steps, we isolate the input from the output.
The isolation lets us:

=over

=item * Centralize data formatting and validation.

=item * Add new input formats with ease.

=item * Swap files and databases without changing application code.

=back

=head2 How does the ETL module work?

The C<ETL> module works in layers. 

 +-------------------+
 | Input file format |------------------+-------------+
 +-------------------+ Conversion Class | Application |
 | Output format     |------------------+-------------+
 +-------------------+

The I<Conversion Class> inherits from C<ETL>. It defines an input format and an
output format. C<ETL> is format agnostic - abstract if you will. The 
I<Conversion Class> pulls together real, tangilble, formats that physically
move around the data.

Your application instantiates and uses the I<Conversion Class>.

=head3 How does one create a conversion class?

=over

=item 1. Inherit from I<ETL>.

=item 2. L<Override|Moose::Manual::MethodModifiers/OVERRIDE AND SUPER> L</build_input()>. Returns an instance of a child of L<ETL::Extract>.

=item 3. L<Override|Moose::Manual::MethodModifiers/OVERRIDE AND SUPER> L</build_output()>. Returns an instance of a child of L<ETL::Load>.

=item 4. L<Override|Moose::Manual::MethodModifiers/OVERRIDE AND SUPER> L</build_mapping()>. Returns a hash reference.

That's it - pretty simple? The complexity really comes from instantiating
the L<ETL::Extract> and L<ETL::Load> classes. 


ETL::PARS::Vanderbilt::Complaints
ETL::PARS::Vanderbilt::Physicians


=head4 Extract: Input formats

An input format reads individual records. The data can come from all kinds of
different sources - CSV file, Excel spreadsheet, or an Access database. For 
example, the L<ETL::Extract::FromFile::Excel::2003> class extracts data one 
row at a time from an Excel spreadsheet.

Each conversion class has exactly one input format. The input format returns
an L<ETL::Record> object.

=head4 Transform: Mappings

C<ETL> maps fields using a Perl hash. The keys represent output fields. The 
values identify input fields. Let's look at an example...

 %mapping = {
   Name => 'A',
   Date => 'B',
   Age  => 'C',
 };

This mapping moves data from column A into into the I<Name> field. Data from 
column B goes into the I<Date> field. And column C populates the I<Age> field.

The keys are your B<output> field names. Read the example as saying 
I<fill the Name field from column A>.

=head4 Load: Output formats

An input format writes individual records to a data store. The data can go
into all kinds of different stores - CSV file or SQL database. You pass it a
hash reference with the data fields. And the output format writes it.

Each conversion class has exactly one output format.

=head3 How does the application use a conversion class?

=head2 Why not use Moose roles?

The original design C<ETL> used three distinct roles: extract, transform, and 
load. The input formats consumed the extract role. Output formats consumed the
load role. And the conversion class was a mixture of consuming roles and 
inheritance. Yuck!

This design feels cleaner. Conversion classes inherit from one base and 
instantiate instances of input/output formats.

=head1 METHODS & ATTRIBUTES

=head2 Override in Child Classes

=head3 build_input()

This method creates and returns an instance of an L<ETL::Extract> subclass. 
The conversion class 
L<overrides|Moose::Manual::MethodModifiers/OVERRIDE AND SUPER> C<build_input> 
and instantiates an object for its specific input format.

=cut

sub build_input($) { return undef; }


=head3 build_mapping()

Return a hash reference. The hash links output field names with the 
corresponding input field name. This example maps a spreadsheet. Column A goes 
into the I<Name> field, B into I<Date>, etc.

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

sub build_mapping($) { return {}; }


=head3 build_output()

This method creates and returns an instance of an L<ETL::Load> subclass. The
conversion class L<overrides|Moose::Manual::MethodModifiers/OVERRIDE AND SUPER> 
C<build_output> and instantiates an object for its specific input format.

=cut

sub build_output($) { return undef; }


=head2 E => Extract

=head3 extract()

This method reads a single input record - just like the name implies. Records
are objects of the type L<ETL::Record>.

The method returns C<undef> at the end of the data.

=head3 input

This attribute holds an L<ETL::Extract> object. This object defines the 
conversion class's input format.

=cut

has 'input' => (
	builder => 'build_input',
	handles => [qw/extract/],
	is      => ro,
	isa     => 'ETL::Extract',
);


=head2 T => Transform

=head3 mapping

Stores a hash linking the output fields to the input fields. This is the heart
of the conversion process.

Key the hash with the output field name. The conversion process pulls data
from the input source. This is what you do manually - look at the fields you 
need, then see which input fields correspond.

The L</build_mapping()> method creates this hash.

=cut

has 'mapping' => (
	builder => 'build_mapping',
	is      => 'ro',
	isa     => 'HashRef[Str]',
);


=head3 transform( $record )

Convert an L<ETL::Record> into a standardized hash.

L<ETL::Transform> does not perform any formatting or validation on the
data. Your application should provide that functionality by:

=over

=item 1. Calling validation/formatting code from the application.

=item 2. Or using method modifiers such as L<before, after, and around|Moose::Manual::MethodModifiers/BEFORE, AFTER, AND AROUND>.

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


=head2 L => Load

=head3 load( $data )

This method saves a single record in its final destination. C<$data> is a hash
reference keyed by the output field names. L</transform( $record )> creates 
the hash.

=head3 output

This attribute holds an L<ETL::Load> object. This object defines the conversion 
class's output format.

=cut

has 'output' => (
	builder => 'build_output',
	handles => [qw/load/],
	is      => ro,
	isa     => 'ETL::Load',
);


=head2 Standard Methods & Attributes

=head3 error( $message, $record )

Log an error message for the given record. Call this from your validation 
code. It ensures a consistent format in error messages.

=cut

sub error($$$) {
	my ($self, $message, $record) = @_;

	$self->log->error( "$message at " . $record->came_from );
}


=head3 log

This attrbiute provides an access point into the L<Log::Log4perl> logging
system. C<ETL> logs all warning and error messages. Users can run the 
application, and I do not need to ask them for error messages. The log file
always has a copy.

=cut

with 'MooseX::Log::Log4perl';


=head1 SEE ALSO

L<ETL::Extract>, L<ETL::Load>, L<ETL::Record>, L<Log::Log4perl>

=head1 LICENSE

Copyright 2010  The Center for Patient and Professional Advocacy, Vanderbilt University Medical Center
Contact Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
