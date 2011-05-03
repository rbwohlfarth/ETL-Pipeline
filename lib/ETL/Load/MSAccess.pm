=pod

=head1 NAME

ETL::Load::Staging - Save data into a staging database using MS Access

=head1 DESCRIPTION

SQL handles some aspects of our data load better than Perl. The upload tool
puts its data in an Access database for manual review and SQL processing.

=cut

package ETL::Load::Staging;
use Moose;

extends 'ETL::Load';

use DBI qw/:sql_types/;
use File::Spec::Functions qw/catfile/;


=head1 METHODS & ATTRIBUTES

=head3 load( $record )

This method saves a L<ETL::Record> into MS Access. It returns null for success
or an error message.

=cut

augment 'load' => sub { 
	my ($self, $record) = @_;

	unless (defined $self->query) {
		my $file = catfile( $self->destination, 'Staging.accdb' );
		my $dbh = MSAccess::using( $file );
		$self->log->logdie( "Error connecting with '$file'" ) 
			unless defined $dbh;
		
		$self->query( $dbh->prepare( <<LOAD ) );
INSERT INTO Export (
	ExternalID, 
	[Date], 
	PatientName, 
	[Text], 
	ComplaintType,
	EntityID,
	Advocate
)
VALUES (?, ?, ?, ?, ?, ?)
LOAD
		$self->log->logdie( "Query failed for '$file'" ) 
			unless defined $self->query;
	}

	my $sth = $self->query;
	$sth->bind_param( 1, $record->fields->{ExternalID   }, SQL_VARCHAR  );
	$sth->bind_param( 2, $record->fields->{Date         }, SQL_DATETIME );
	$sth->bind_param( 3, $record->fields->{PatientName  }, SQL_VARCHAR  );
	$sth->bind_param( 4, $record->fields->{Text         }, SQL_VARCHAR  );
	$sth->bind_param( 5, $record->fields->{ComplaintType}, SQL_INTEGER  );
	$sth->bind_param( 6, $record->fields->{EntityID     }, SQL_VARCHAR  );
	$sth->bind_param( 7, $record->fields->{Advocate     }, SQL_VARCHAR  );
	$sth->execute;
}


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
	isa => 'DBI',
);


=head1 SEE ALSO

L<ETL::Load>, L<ETL::Record>

=head1 LICENSE

Copyright 2011  The Center for Patient and Professional Advocacy, Vanderbilt University Medical Center
Contact Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
