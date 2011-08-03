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

Your application sets this attribute to the MS Access file path. The class
automatically generates a DBI connection string.

=cut

augment 'connect' => sub {
	my ($self) = @_;
	return 'dbi:ODBC:driver=microsoft access driver (*.mdb, *.accdb);dbq='
		. $self->destination;
};


=head1 SEE ALSO

L<ETL::Load>, L<ETL::Load::DBI>, L<ETL::Record>

=head1 LICENSE

Copyright 2011  The Center for Patient and Professional Advocacy, Vanderbilt University Medical Center
Contact Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
