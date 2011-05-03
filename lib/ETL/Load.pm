=pod

=head1 NAME

ETL::Load - Base class for ETL output destinations

=head1 DESCRIPTION

This class defines the Application Programming Interface (API) for all ETL
output destinations. The API allows applications to interact with the 
destination without worrying about its specific format (file, database, etc.).

The I<load> part of the process validates the output and then moves the data 
from L<ETL::Record/fields> into a data store.

=cut

package ETL::Load;
use Moose;


=head1 METHODS & ATTRIBUTES

=head2 Override in Child Classes

=head3 load( $record )

This method saves the L<ETL::Record> into permanent storage such as a database 
or file. The child class 
L<augments|Moose::Manual::MethodModifiers/INNER AND AUGMENT> C<load>. The 
child class returns null for success, or an error message.

=cut

sub load { 
	my ($self, $record) = @_;
	return ($record->is_valid ? inner() : $record->error); 
}


=head2 Standard Methods & Attributes

=head3 destination

I<destination> tells you where the data comes goes. It might contain a file 
path or a database name. You set the value only once. It may B<not> change 
during execution. That causes all kinds of bugs.

=cut

has 'destination' => (
	is  => 'rw',
	isa => 'Str',
);


=head1 SEE ALSO

L<ETL>, L<ETL::Record>

=head1 LICENSE

Copyright 2010  The Center for Patient and Professional Advocacy, Vanderbilt University Medical Center
Contact Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
