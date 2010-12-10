=pod

=head1 NAME

ETL - Translating Data

=cut

package ETL;
use Moose;

use File::Find::Rule;


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
into all kinds of different stores - CSV file or SQL database. You pass it an
L<ETL::Record> with the data fields. And the output format writes it.

Each conversion class has exactly one output format.

=head3 How does the application use a conversion class?

Here is a very simplified example...

  use ETL::Example;
  my $etl = ETL::Example->new;
  while (my $record = $etl->extract) {
      $etl->transform( $record );
      $etl->load( $record ) if $record->is_valid;
  }

The I<ETL::Example> class handles all of the details about opening the input 
file, connecting to the output database, and validating the information.

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

sub build_input($) { undef }


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

sub build_mapping($) { {} }


=head3 build_output()

This method creates and returns an instance of an L<ETL::Load> subclass. The
conversion class L<overrides|Moose::Manual::MethodModifiers/OVERRIDE AND SUPER> 
C<build_output> and instantiates an object for its specific input format.

=cut

sub build_output($) { undef }


=head3 is_responsible_for( $source )

This class method returns a boolean value. B<True> indicates that this class
handles data from the given folder. B<False> means that it does not.

The ETL process assumes that we have a repeatable and consistent process. 
Client A follows a different naming convention than client B. This method
encapsulates the naming convention inside of the client specific class.

=cut

sub is_responsible_for($$) { 0 }


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
	is      => 'ro',
	isa     => 'ETL::Extract',
	lazy    => 1,
);


=head3 find_file_matching( $pattern )

Returns the first file that matches the given regular expression. This method
searches for files under the L<source> directory.

I found a lot of ETL classes calling L<File::Find::Rule> in exactly the same
manner. This method provides a convenient way of re-using that code.

=cut

sub find_file_matching($$) {
	my ($self, $pattern) = @_;
	
	my @matches = File::Find::Rule->file()
		->name( $pattern )
		->in( $self->source );
	shift @matches;
}


=head3 source

The source folder where this object finds input files. An ETL class normally
covers a repeated process. For example, client A sends data and you load it
into your database. Client A puts their file in the same location every month.
They name the file according to the same pattern every month. This ETL process 
is repeatable and consistent. Rather than have the application get the file 
name, the ETL class finds it inside of this folder.

That is one example of how ETL classes use this attribute. For more details, 
please refer to the documentation of your specific ETL module.

=cut

has 'source' => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
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
	lazy    => 1,
);


=head3 transform( $record )

Transformation maps the input data to the output fields. In pure data terms,
it converts L<ETL::Record/raw> into L<ETL::Record/fields>.

L<ETL::Transform> does not perform any formatting or validation on the
data. Your application should provide that functionality by:

=over

=item 1. Calling validation/formatting code from the application.

=item 2. Or using method modifiers such as L<before, after, and around|Moose::Manual::MethodModifiers/BEFORE, AFTER, AND AROUND>.

=back

=cut

sub transform($$) {
	my ($self, $record) = @_;

	my %data    = ();
	my $mapping = $self->mapping;

	while (my ($to, $from) = each %$mapping) {
		$record->fields->{$to} = $record->raw->{$from} if defined $from;
	}
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
	is      => 'ro',
	isa     => 'ETL::Load',
	lazy    => 1,
);


=head2 Standard Methods & Attributes

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
