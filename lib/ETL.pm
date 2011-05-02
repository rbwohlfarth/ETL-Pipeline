=pod

=head1 NAME

ETL - Translating Data

=cut

package ETL;
use Moose;


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
 +-------------------+                  |             |
 | Transformation    | Conversion Class | Application |
 +-------------------+                  |             |
 | Output format     |------------------+-------------+
 +-------------------+

The I<Conversion Class> inherits from C<ETL>. It defines an input format, 
transformation logic, and an output format. C<ETL> is format agnostic - 
abstract if you will. The I<Conversion Class> pulls together real, tangilble, 
formats that physically move around the data.

Your application instantiates and uses the I<Conversion Class>.

=head3 How does one create a conversion class?

=over

=item 1. Inherit from I<ETL>.

=item 2. Define a L<BUILD|Moose::Manual::Construction/BUILD> method.

=item 3. Instantiate an L<ETL::Extract> class.

=item 4. Instantiate an L<ETL::Transform> class.

=item 5. Instantiate an L<ETL::Load> class.

That's it - pretty simple? The complexity really comes from instantiating
the L<ETL::Extract>, L<ETL::Transform>, and L<ETL::Load> classes. 

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
file, connecting to the output database, and validating the information. It 
fits into our diagram this way...

 +-------------------+
 | ETL::Extract      |------------------+-------------+
 +-------------------+                  |             |
 | ETL::Transform    | ETL::Example     | Sample code |
 +-------------------+                  |             |
 | ETL::Load         |------------------+-------------+
 +-------------------+

=head2 Why not use Moose roles?

The original design C<ETL> used three distinct roles: extract, transform, and 
load. The input formats consumed the extract role. Output formats consumed the
load role. And the conversion class was a mixture of consuming roles and 
inheritance. Yuck!

This design feels cleaner. Conversion classes inherit from one base and create 
instances of input/output formats.

=head1 METHODS & ATTRIBUTES

=head2 Override in Child Classes

=head3 is_responsible_for( $source )

This class method returns a boolean value. B<True> indicates that this class
handles data from the given source. B<False> means that it does not.

The ETL process assumes that we have a repeatable and consistent process. 
Client A follows a different naming convention than client B. This method
encapsulates the naming convention inside of the client specific class.

=cut

sub is_responsible_for { 0 }


=head2 E => Extract

=head3 extract()

This method reads a single input record - just like the name implies. Records
are objects of the type L<ETL::Record>.

The method returns C<undef> at the end of the data.

=head3 input

This attribute holds an L<ETL::Extract> object. The L<ETL::Extract> object 
defines the input format.

=head3 source

I<source> tells you where the data comes from. It might contain a file path,
or a database name. The source should B<not> change during execution. That 
causes all kinds of bugs.

=cut

has 'input' => (
	handles => [qw/extract source/],
	is      => 'rw',
	isa     => 'ETL::Extract',
);


=head2 T => Transform

=head3 logic

This attribute holds an L<ETL::Transform> object. The L<ETL::Transform> object 
defines the conversion logic.

=head3 transform( $record )

This method converts a single L<ETL::Record> from raw data into output fields.

=cut

has 'logic' => (
	handles => [qw/transform/],
	is      => 'rw',
	isa     => 'ETL::Transform',
);


=head2 L => Load

=head3 load( $record )

This method saves a single record in its final destination. C<$record> is an 
L<ETL::Record> object.

=head3 output

This attribute holds an L<ETL::Load> object. The L<ETL::Load> object defines 
the output format.

=cut

has 'output' => (
	handles => [qw/load/],
	is      => 'rw',
	isa     => 'ETL::Load',
);


=head1 SEE ALSO

L<ETL::Extract>, L<ETL::Load>, L<ETL::Record>, L<ETL::Transform>, 
L<Log::Log4perl>

=head1 LICENSE

Copyright 2011  The Center for Patient and Professional Advocacy, Vanderbilt University Medical Center
Contact Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
