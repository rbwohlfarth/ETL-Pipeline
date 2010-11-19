=pod

=head1 NAME

ETL::Load - Base class for ETL output destinations

=head1 DESCRIPTION

This class defines the Application Programming Interface (API) for all ETL
output destinations. The API allows applications to interact with the 
destination without worrying about its specific format (file, database, etc.).

The I<load> part of the process blindly moves data from L<ETL::Record/fields>
into a data store. Use the I<transform> process for validation and formatting.

=cut

package ETL::Load;
use Moose;


=head1 METHODS & ATTRIBUTES

=head2 Override in Child Classes

=head3 load( $data_hash_reference )

Saves data into permanent storage such as a database or file. I<load>
provides a generic call for all output methods (database, file, etc.). The
child class defines the actual output code.

=cut

sub load($$) { }


=head3 log

This attrbiute provides an access point into the L<Log::Log4perl> logging
system. Child classes must log all errors messages.

=cut

with 'MooseX::Log::Log4perl';


=head1 SEE ALSO

L<ETL>, L<Log::Log4perl>

=head1 LICENSE

Copyright 2010  The Center for Patient and Professional Advocacy, Vanderbilt University Medical Center
Contact Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=cut

# Perl requires this to load the module.
1;
