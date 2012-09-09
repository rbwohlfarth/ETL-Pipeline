=pod

=head1 NAME

ETL::Load::DBI - Save data into an SQL database using DBI

=head1 DESCRIPTION

This class loads a record into an SQL database.

=cut

package ETL::Load::DBI;
use Moose;

extends 'ETL::Load';

use DBI;
use String::Util qw/hascontent/;


=head1 METHODS & ATTRIBUTES

=head3 connect()

This method makes a connection with the database. It assumes the 
L<ETL::Load/destination> attribute holds a database connection string.

If you are creating a child class, you can 
L<augment|Moose::Manual::MethodModifiers/INNER AND AUGMENT> this method and
generate a connection string. This lets child classes use more appropriate
values in L<ETL::Load/destination>.

=cut

sub connect {
	my ($self) = @_;

	my $db = inner();
	   $db = $self->destination unless hascontent( $db );

	my $handle = DBI->connect( $db, '', '', {AutoCommit => 1} );
	$self->log->logdie( "Error connecting with '$db'" ) unless defined $handle;

	return $handle;
}


=head3 fields

A hash of database field names and the SQL type:
 $self->fields->{A} = SQL_VARCHAR;
 $self->fields->{B} = SQL_INTEGER;

The L</load( $record )> method puts these fields into the database.

=cut

has 'fields' => (
	default => sub { {} },
	is      => 'ro',
	isa     => 'HashRef[Str]',
);


=head3 load( $record )

This method adds an L<ETL::Record> into the SQL database. It returns null for 
success or an error message.

=cut

augment 'load' => sub { 
	my ($self, $record) = @_;
	
	# Call the child method first. The child may format some of the output
	# fields for its specific database type.
	inner();

	# Make the database connection the first time through.
	unless (defined $self->query) {
		my $dbh   = $self->connect;
		my @names = keys %{$self->fields};
		
		my @values;
		push( @values, '?' ) foreach (@names);

		$self->query( $dbh->prepare( 
			'INSERT INTO ' 
			. $self->table
			. ' (' 
			. join( ', ', @names )
			. ') VALUES ('
			. join( ', ', @values )
			. ')'
		) );
		$self->log->logdie( "Query failed for '" . $self->destination . "'" )
			unless defined $self->query;
	}

	# Insert the fields into the database.
	my @names = keys %{$self->fields};
	my $query = $self->query;

	for (my $index = 0; $index < scalar( @names ); $index++) {
		my $field = $names[$index];
		$query->bind_param( 
			$index + 1, 
			$record->fields->{$field}, 
			$self->fields->{$field}
		);
	}
	$query->execute;
	
	return ($query->err ? $query->errstr : '');
};


=head3 log

This attrbiute provides an access point into the L<Log::Log4perl> logging
system. C<ETL> logs all warning and error messages. Users can run the 
application, and I do not need to ask them for error messages. The log file
always has a copy.

=cut

with 'MooseX::Log::Log4perl';


=head3 query

This attribute holds the statement handle from the DBI query that inserts new
rows. L<load( $record )> automatically generates this value on its first use.

=cut

has 'query' => (
	is  => 'rw',
	isa => 'DBI::st',
);


=head3 table

The data goes into this table in the database.

=cut

has 'table' => (
	is  => 'rw',
	isa => 'Str',
);


=head1 SEE ALSO

L<ETL::Load>, L<ETL::Record>

=head1 LICENSE

Copyright 2011  The Center for Patient and Professional Advocacy, Vanderbilt University Medical Center
Contact Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
