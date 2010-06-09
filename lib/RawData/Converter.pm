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

=head2 Sample Application

This code shows a very simple example. It takes an Excel spreadsheet and 
load it into the SQL database. 

 use RawData::Converter::Example;
 my $cnv = new RawData::Converter::Example;

 # Access the data file.
 $cnv->parser->file( 'C:\sample_data.xls' );
 
 # Process records one at a time, skipping blank rows.
 while (my $record = $cnv->parser->read_one_record) {
     unless ($record->is_blank) {
         # Convert from the spreadsheet to the database.
         $cnv->convert( $record );
 
         # Save the new record to the database.
         $cnv->model->update;
     }
 }

Notice that I don't tell the code anywhere about Excel? 
I<RawData::Converter::Example> creates a L<RawData::File> parser of the 
correct type. It also defines exactly how the cells map to database fields.

I expect most applications have a repetoire of I<RawData::Converter> classes.
Those classes handle the customized portions. Leaving the only common code in
the application itself.

=cut

package RawData::Converter;
use Moose::Role;


=head1 METHODS & ATTRIBUTES

=head2 Override These in the Consuming Class

=head3 build_mapping()

Return a hash reference. The hash links database field names with to the
corresponding file field name. This example maps a spreadsheet. Column A goes into the I<Name> field, B into I<Date>, etc.

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

Return a L<RawData::File> object corresponding to the input file format.

=cut

requires 'build_parser';


=head3 number_of_headers

The number of header rows before any data. You do not want to load the 
headers. This tells the file parser how many lines it can skip by setting
the L</header_rows> attribute.

=cut

requires 'number_of_headers';


=head2 Standard Attributes & Methods

=head3 convert( $record )

Map the file fields into the proper database fields. This method applies the
field mapping to an individual record.

Your conversion process may require more. For example, perhaps you L</trigger> 
validation code before the conversion. L<RawData::Converter> provides two ways
to handle this:

=over

=item 1. Put the call in your application.

=item 2. Use the L<before, after, or around|Moose::Manual::MethodModifiers/BEFORE, AFTER, AND AROUND> method modifiers.

=back

=cut

sub convert($$) {
	my ($self, $record) = @_;

	my $mapping = $self->mapping;
	foreach my $database (keys %$mapping) {
		my $file = $mapping->{$database};
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


=head3 header_rows

The number of header rows before any data. You do not want to load the 
headers. This tells the file parser how many lines it can skip.

=cut

has 'header_rows' => (
	builder => 'number_of_headers',
	is      => 'rw',
	isa     => 'Int',
);


=head3 log

A L<Moose::Log::Log4perl> object for reporting errors.

=cut

with 'Moose::Log::Log4perl';


=head3 mapping

Stores a hash linking the database fields to the file fields. This is the
heart of the conversion process.

Key the hash with the database field name. The conversion process pulls data
from the file. This is what you do manually - look at the fields you need, then
see which file fields correspond.

The L</build_mapping()> method creates this hash.

=cut

has 'mapping' => (
	builder => 'build_mapping',
	is      => 'ro',
	isa     => 'HashRef[Str]',
);


=head3 model

A L<DBIx::Class::ResultSet> for the database table. Your class sets this 
through the L</build_model()> method.

=cut

has 'model' => (
	builder => 'build_model',
	is      => 'ro',
	isa     => 'DBIx::Class::ResultSet',
);


=head3 parser

A L<RawData::File> object for accessing the file. The L</build_parser()> 
method creates an object of the for this client's specific file format.

=cut

has 'parser' => (
	builder => 'build_parser',
	is      => 'ro',
	isa     => 'RawData::File',
);


=head1 SEE ALSO

L<DBIx::Class::ResultSet>, L<RawData::File>

=head1 LICENSE

Copyright 2010  The Center for Patient and Professional Advocacy,
Vanderbilt University Medical Center

Contact Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=cut

# Perl requires this to load the module.
1;

