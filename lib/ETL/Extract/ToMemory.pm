=pod

=head1 SYNOPSIS

 use ETL::Extract::ToMemory;
 my $input = new ETL::Extract::ToMemory( 
     headers     => 4,
     parser      => new ETL::Extract::FromFile::Excel2003,
	primary_key => 'A',
	progress    => \&display_progress,
 );

 $input->load;

 while (my ($id, $list) = each %{$input->records}) {
     foreach my $record (@$list) {
		print "$id == ", $record->data->{'B'}, "\n";
	 }
 }

=head1 DESCRIPTION

L<ETL::Extract::Record> holds data from one record. This class reads B<all> of
the records and stores them for later retrieval. Use it with ancillary data
that you will merge with a main record.

=head2 Why memory instead of a database?

A database would work like this... Load the data into its own table. Then
extract what I need using SQL. Of course, it means you need to setup a
database to use these classes. And worse, you may not need it.

I assume a pretty simple setup: a few hundred records at a time, and one key
field. A database is overkill. If you have millions of records or complex
lookup requirements, then use a database. This class will disappoint you.

Simple data that you just need loaded, L<ETL::Extract::ToMemory> can help.

=cut

package ETL::Extract::ToMemory;
use Moose;


=head1 METHODS & ATTRIBUTES

=head3 headers

The number of header rows before any data. You do not want to load the 
headers. This tells the file parser how many lines it can skip.

=cut

has 'headers' => (
	default => 0,
	is      => 'rw',
	isa     => 'Int',
);


=head3 input( $path [, @options] )

This convenience method connects the object with an actual file. See 
L<ETL::Extract> for more information about C<input>.

=head3 load()

This method reads all of the records into memory. C<load> B<appends> records
into memory. It does not erase any previously loaded data. You can,
technically, use the same L<ETL::Extract::ToMemory> object for more than one
file. Though it will cause confusion for you in the end.

=cut

sub load($) {
	my ($self) = @_;

	# Only load the file once.
	return $self if $self->parser->end_of_input;

	# Skip the header records...
	for (my $count = 0; $count < $self->headers; $count++) {
		$self->parser->extract;
		return $self if $self->parser->end_of_input;
	}

	# Load all of the data records...
	my $count = 0;
	while (my $record = $self->parser->extract) {
		my $id = $record->data->{$self->primary_key};

		if (not defined $id) {
			push @{$self->no_id}, $record;
			$self->parser->log->error( 
				"Primary key not set at " 
				. $record->came_from
			);
		} else { 
			$self->records->{$id} = [] 
				unless defined $self->records->{$id};
			push @{$self->records->{$id}}, $record; 
		}

		# Update the progress...
		$count++;
		$self->progress->( $count ) if defined $self->progress;
	}

	return $self;
}


=head3 no_id

A list of records with an undefined primary key. The C<load> method cannot
handle records without a key. It simply logs an error and stores them in this
list. Your application should check this list and handle the records 
appropriately.

=cut

has 'no_id' => (
	default => sub { [] },
	is      => 'ro',
	isa     => 'ArrayRef[ETL::Extract::Record]',
);


=head3 parser

An L<ETL::Extract> object for accessing the file. This object physically
reads the file. This lets L<ETL::Extract::ToMemory> work with many input 
formats.

I<parser> is required by the constructor.

=cut

has 'parser' => (
	handles  => [qw/input/],
	is       => 'ro',
	isa      => 'ETL::Extract',
	required => 1,
);


=head3 primary_key

The name of the key field. The C<load> method reads the identifier from this
field.

L<ETL::Extract::ToMemory> only supports a single key field. If you need 
multiple fields, use an SQL database instead.

=cut

has 'primary_key' => (
	is  => 'rw',
	isa => 'Str',
);


=head3 progress

This attribute holds a callback function. The C<load> method calls this
routine for every record loaded into memory. The function should display
progress to the user in a manner consistent with the application's interface
(GUI, text, etc).

Your function takes one argument: the number of records loaded.

=cut

has 'progress' => (
	is  => 'rw',
	isa => 'CodeRef',
);


=head3 records

This hash stores a list of records, sorted by identifier. It is a hash
reference to an array reference to L<ETL::Extract::Record> objects. Confused?

Imagine a file of notes. Each line represents one line of notes. It has an
identifier followed by the text. You can have 50 lines for one identifier.
This structure takes all 50 and stores them in an array - I<preserving file
order>. 

=cut

has 'records' => (
	default => sub { {} },
	is      => 'ro',
	isa     => 'HashRef[ArrayRef[ETL::Extract::Record]]',
);


=head1 SEE ALSO

L<ETL::Extract>, L<ETL::Extract::Record>

=head1 LICENSE

Copyright 2010  The Center for Patient and Professional Advocacy, 
                Vanderbilt University Medical Center
Contact Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=cut

no Moose;
__PACKAGE__->meta->make_immutable;

