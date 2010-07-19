=pod

=head1 SYNOPSIS

 with 'RawData::File';

=head1 DESCRIPTION

L<RawData::Record> holds data from one record in a file. This class reads all
of the records from a file and stores them for later retrieval. Use it with
ancillary files that you will merge with a main record.

=head2 Why not a database?

A database would work like this... Load each file into its own table. Then
extract the data I need using SQL. Of course, it means you need to setup a
database to use these classes. And worse, you may not need it.

I assume a pretty simple setup: a few hundred records at a time, and one key
field. A database is overkill. If you have millions of records or complex
lookup requirements, then use a database. This class will disappoint you.

Simple files that you just need loaded, L<RawData::File> can help.

=cut

package RawData::File;
use Moose;


=head1 METHODS & ATTRIBUTES

=head3 header_rows

The number of header rows before any data. You do not want to load the 
headers. This tells the file parser how many lines it can skip.

=cut

has 'header_rows' => (
	default => 0,
	is      => 'rw',
	isa     => 'Int',
);


=head3 load()

This method reads all of the records from the file into memory. I do not
automatically trigger the load because it might take a while. Your application
should have complete control over something that can pause the system.

The load I<appends> records into memory. It does not erase any previously 
loaded data. You can, technically, use the same L<RawData::File> object for
more than one file. Though it will cause confusion for you in the end.

=cut

sub load($) {
	my ($self) = @_;

	# Only load the file once.
	return $self if $self->parser->end_of_file;

	# Skip the header records...
	for (my $count = 0; $count < $self->header_rows; $count++) {
		$self->parser->read_one_record;
		return $self if $self->parser->end_of_file;
	}

	# Load all of the data records...
	my $count = 0;
	while (my $record = $self->parser->read_one_record) {
		my $id = $record->data->{$self->primary_key_field};

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

A list of records with an undefined primary key. L</load> cannot handle 
records without a key. It simply logs an error and stores them in this list.
Your application should check this list and handle the records appropriately.

=cut

has 'no_id' => (
	default => sub { [] },
	is      => 'ro',
	isa     => 'ArrayRef[RawData::Record]',
);


=head3 parser

A L<RawData::Parser> object for accessing the file. This object physically
reads the file. This lets L<RawData::File> work with many input formats.

L</parser> is required by the constructor.

=cut

has 'parser' => (
	is       => 'ro',
	isa      => 'RawData::Parser',
	required => 1,
);


=head3 primary_key_field

The name of the key field. L</load> reads the identifier from this field.

L<RawData::File> only supports a single key field. If you need multiple 
fields, use an SQL database instead of L<RawData::File>.

=cut

has 'primary_key_field' => (
	is  => 'rw',
	isa => 'Str',
);


=head3 progress

This attribute holds a callback function. L</load> calls this routine for 
every record loaded into memory. The function should display progress to the 
user in a manner consistent with the application's interface (GUI, text, etc).

The function takes one argument: the number of records loaded.

=cut

has 'progress' => (
	is  => 'rw',
	isa => 'CodeRef',
);


=head3 records

This hash stores a list of records, sorted by identifier. It is a hash
reference to an array reference to L<RawData::Record> objects. Confused?

Imagine a file of notes. Each line represents one line of notes. It has an
identifier followed by the text. You can have 50 lines for one identifier.
This structure takes all 50 and stores them in an array - I<preserving file
order>. 

=cut

has 'records' => (
	default => sub { {} },
	is      => 'ro',
	isa     => 'HashRef[ArrayRef[RawData::Record]]',
);


=head1 SEE ALSO

L<RawData::Converter>, L<RawData::Parser>, L<RawData::Record>

=head1 LICENSE

Copyright 2010  The Center for Patient and Professional Advocacy, 
Vanderbilt University Medical Center

Contact Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=cut

no Moose;
__PACKAGE__->meta->make_immutable;

