=pod

=head1 NAME

ETL::Load::Access - Save data into an MS Access database

=head1 DESCRIPTION

This class loads a record into an MS Access database.

=cut

package ETL::Load::Access;
use Moose;

extends 'ETL::Load::DBI';

use DBI;
use String::Util qw/hascontent/;


=head1 METHODS & ATTRIBUTES

=head3 augment connect()

Your application sets the L<ETL::Load/destination> attribute to the MS Access 
file path. This method automatically generates a DBI connection string.

=cut

augment 'connect' => sub {
	my ($self) = @_;
	return 'dbi:ODBC:driver=microsoft access driver (*.mdb, *.accdb);dbq='
		. $self->destination;
};


=head3 around connect()

MS Access does not handle Memo fields very well through the ODBC interface. 
This code sets the connection for the longer text. To disable this feature,
see the L</memo_length> attribute. 

=cut

around 'connect' => sub {
	my $original = shift @_;
	my $self     = shift @_;
	
	my $dbh = $original->( $self, @_ );
	if (defined( $dbh ) and defined( $self->memo_length )) {
		$dbh->{LongReadLen} = $self->memo_length;
		$dbh->{LongTruncOk} = 1;
	}
	return $dbh;
};


=head3 memo_length

MS Access does not handle Memo fields very well through the ODBC interface. The 
L</around connect()> code configures DBI for text up to this many characters.
The default value is quite high (262,144). Your application may change it 
B<before> it saves the first record.

To disable memo fields altogether, set this attribute to C<undef>.

=cut

has memo_length => (
	default => 262144,
	is      => 'rw',
	isa     => 'Maybe[Int]',
);


=head1 SEE ALSO

L<ETL::Load>, L<ETL::Load::DBI>, L<ETL::Record>

=head1 LICENSE

Copyright 2011  The Center for Patient and Professional Advocacy, Vanderbilt University Medical Center
Contact Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
