=pod

=head1 NAME

ETL - Translating Data

=cut

package ETL;
use Moose;


=head1 DESCRIPTION

B<ETL> stands for I<Extract-Transform-Load>. You often hear this design
pattern associated with Data Warehousing. In fact, ETL works with almost
any type of data conversion. You read the source (I<Extract>), translate the
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

A I<Conversion Class> inherits from C<ETL>. It defines an input format and an 
output format. C<ETL> is format agnostic - abstract if you will. The 
I<Conversion Class> pulls together real, tangilble, formats that physically 
move around the data.

Your application instantiates and uses the I<Conversion Class>.

=head2 How does one create a conversion class?

=over

=item 1. Inherit from I<ETL>.

=item 2. Define a L<BUILD|Moose::Manual::Construction/BUILD> method.

=item 3. Instantiate an L<ETL::Extract> class.

=item 5. Instantiate an L<ETL::Load> class.

=item 6. Override L</is_responsible_for( $source )>.

=item 7. Augment L</process_raw_data( $record )>.

=item 8. Augment L</process_converted_data( $record )>.

=head3 Extract: Input formats

An input format reads individual records. The data can come from all kinds of
different sources - CSV file, Excel spreadsheet, or an Access database. For 
example, the L<ETL::Extract::File::Excel::2003> class extracts data one row
at a time from an Excel spreadsheet.

Each conversion class has exactly one input format. The input format returns
an L<ETL::Record> object.

=head3 Transform: Mappings

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

=head3 Load: Output formats

An output format writes individual records to a data store. The data can go
into all kinds of different stores - CSV file or SQL database. You pass it an
L<ETL::Record> with the data fields. And the output format writes it.

Each conversion class has exactly one output format.

=head2 How does the application use a conversion class?

The L<ETL> class sets up a data pipeline. Each record travels the pipeline from
start to finish:

 extract -> process_raw_data -> transform -> process_converted_data -> load

The most basic application simply kicks off the pipeline, like this...

  use ETL::Example;
  my $etl = ETL::Example->new( source => $input_file );
  $etl->run;

The I<ETL::Example> class handles all of the details about opening the input 
file, connecting to the output database, and validating the information. It 
fits into our diagram this way...

 +-------------------+
 | ETL::Extract      |------------------+-------------+
 +-------------------+ ETL::Example     | Sample code |
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


=head3 process_raw_data( $record )

The ETL pipeline calls this method after L</extract()> and before 
L</transform( $record )>. It allows the child class to manipulate the raw
data before transformation.

Unless absolutely necessary, you should do your formatting and validation in
the L</process_converted_data( $record )> method. The input format can be very
specific - hindering code re-use.

The child class 
L<augments|Moose::Manual::MethodModifiers/INNER AND AUGMENT> this method.

=cut

sub process_raw_data {
	my ($self, $record) = @_;
	inner() if $record->is_valid;
}


=head3 process_converted_data( $record )

The ETL pipeline calls this method after L</transform( $record )> and before 
L</load( $record )>. It allows the child class to manipulate fields before 
writing them to the data store.

This is where client specific formatting and validation occurs. If you find an
error, set the L<ETL::Record/error> attribute.

The child class 
L<augments|Moose::Manual::MethodModifiers/INNER AND AUGMENT> this method.

=cut

sub process_converted_data {
	my ($self, $record) = @_;
	inner() if $record->is_valid;
}


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

=cut

#TODO: Copy "mapping" and "transform" from Transform.pm


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


=head2 Pipeline

=head3 progress

The ETL pipeline calls this subroutine after it extracts each record. This is a
callback for displaying progress. L<ETL> sends one parameter: the number of 
records read from the file.

This attribute is optional.

=cut

has 'progress' => (
	is  => 'rw',
	isa => 'CodeRef',
);


=head3 run()

This method executes an ETL pipeline. It starts the whole thing going.

=cut

sub run {
	my ($self) = @_;
	
	my $count = 0;
	while (my $record = $self->extract) {
		# Let the application display a progress indicator.
		$count++;
		$self->progress->( $count ) if defined $self->progress;
		
		# Execute the ETL pipeline on the data record.
		$self->process_raw_data( $record );
		$self->transform( $record );
		$self->process_converted_data( $record );
		$self->load( $record );
	}
}


=head1 SEE ALSO

L<ETL::Extract>, L<ETL::Load>, L<ETL::Record>, L<ETL::Transform>, 
L<Log::Log4perl>

=head1 LICENSE

Copyright 2011  The Center for Patient and Professional Advocacy, Vanderbilt University Medical Center
Contact Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
