=pod

=head1 SYNOPSIS

 use Moose;
 with 'RawData::Converter';

=head1 DESCRIPTION

The C<RawData::Converter> role translates a raw data file into a hash with
standard field names. You can then store the hash in a databse, display it
to the user, or whatever else you need. C<RawData::Converter> provides a 
robust mapping system that handles most of your needs.

The conversion methods work on individual records. Your application should
provide temporary storage for the data (aka lists). I tried putting that
inside this role. It made the thing even more complex. For every method, I had
to decide if it works on single records or the entire list. This meant that
you could not adapt it for your needs. It hid too much of the application
design behind the class definition.

=head2 Sample Application

This code shows a very simple example. It takes an Excel spreadsheet and 
loads it into the SQL database. 

 use RawData::Converter::Example;
 my $cnv = new RawData::Converter::Example;

 # Access the data file.
 $cnv->read_from( 'C:\sample_data.xls' );
 
 # Store converted records in a database using DBIx::Class.
 my @new_data;
 while (my $record = $cnv->next_record) {
    $db_schema->create( $record );
 }

Notice that I don't tell the code anywhere about Excel? 
I<RawData::Converter::Example> creates a L<RawData::Parser> parser of the 
correct type. It also defines exactly how the cells map to field names.

I expect most applications have a repetoire of I<RawData::Converter> classes.
Those classes handle the customized portions. Leaving the only common code in
the application itself.

=cut

package RawData::Converter;
use Moose::Role;


=head1 METHODS & ATTRIBUTES

=head2 Define These in the Consuming Class

=head3 build_mapping()

Return a hash reference. The hash links field names with the corresponding 
file field name. This example maps a spreadsheet. Column A goes into the 
I<Name> field, B into I<Date>, etc.

 {
   Name => 'A',
   Date => 'B',
   Age  => 'C',
 }

The keys are your standard field names. The values are the file field names. 
You should read this as saying I<fill the Name field from column A>. This 
layout makes it easy to see where your data originated for a specific field.

You do not need to map every field from the input file. Map only the fields
required by your application. Ignore the rest. 

=cut

requires 'build_mapping';


=head3 build_parser()

Return a L<RawData::Parser> object for reading the input data. This links 
your data with an specific input format.

=cut

requires 'build_parser';


=head2 Standard Attributes & Methods

=head3 error( $message, $record )


Log an error message for the given record. Call this from your validation 
code. It ensures a consistent format in error messages.


=cut

sub error($$$) {
	my ($self, $message, $record) = @_;

	$self->log->error( "$message at " . $record->came_from );
}


=head3 next_record()

Convert the next record from the input file into a standardized hash. Your
application never sees the raw data from the file. It has a nice data
structure in a known format. Makes it very easy to write applications that
handle varied input methods.

L<RawData::Converter> does not perform any formatting or validation on the
file data. Your application should provide that functionality by:

=over

=item 1. Calling validation/formatting code from the application.

=item 2. Or using method modifiers such as L<after and around|Moose::Manual::MethodModifiers/BEFORE, AFTER, AND AROUND> method modifiers.

=back

The L<before|Moose::Manual::MethodModifiers/BEFORE, AFTER, AND AROUND> 
modifier may not work very well. There is no file data until B<after> you
call C<next_record>. 
L<before|Moose::Manual::MethodModifiers/BEFORE, AFTER, AND AROUND> happens
before we read the file.

Instead, use the L<augment|Moose::Manual::MethodModifiers/INNER AND AUGMENT>
modifier. C<next_record> calls C<inner()> B<after> reading the file and 
B<before> converting the data. In this way, your class can manipulate the
raw file data before the mapping.

=cut

sub next_record($) {
	my ($self) = @_;

	# "undef" means no more data in the file!
	my $record = $self->parser->read_one_record;
	return undef unless defined $record;

	# Let the consuming class manipulate the raw file data.
	inner( $record );

	# Convert the data into standard field names.
	my %data    = ();
	my $mapping = $self->mapping;

	while (my ($to, $from) = each %$mapping) {
		$data{$to} = $record->data->{$from} if defined $from;
	}

	return (wantarray ? %data : \%data);
}


=head3 parser

A L<RawData::Parser> object for accessing the input file. The 
L</build_parser()> method creates an object for a specific file format.

=cut

has 'parser' => (
	builder => 'build_file',
	handles => {read_from => 'file'},
	is      => 'ro',
	isa     => 'RawData::Parser',
);


=head3 log

A L<Moose::Log::Log4perl> object for reporting errors.

=cut

with 'Moose::Log::Log4perl';


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


=head3 read_from( $path )

C<read_from> sets the input file name. The converter reads its data from 
this file.

C<read_from> simply calls into L<RawData::Parser/file>.

=head1 SEE ALSO

L<DBIx::Class::ResultSet>, L<RawData::File>, L<RawData::Record>

=head1 LICENSE

Copyright 2010  The Center for Patient and Professional Advocacy,
                Vanderbilt University Medical Center
Contact Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=cut

# Perl requires this to load the module.
1;

