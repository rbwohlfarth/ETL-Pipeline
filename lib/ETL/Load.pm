=pod

=head1 SYNOPSIS

 use Moose;
 with'ETL::Load';

=head1 DESCRIPTION

The I<Extract-Transform-Load> (ETL) pattern typically appears with Data 
Warehousing. Data Warehousing covers a subset of the larger data conversion 
problem space. The difference is one of scope. The ETL B<pattern> applies to 
the entire problem space.

L<ETL::Load> defines the API for a generic I<load> part of the pattern as a 
L<Moose Role|Moose::Manual::Roles>. You consume L<ETL::Extract> and define
the actual methods that save the data.

=cut

package ETL::Load;
use Moose::Role;


=head1 METHODS & ATTRIBUTES

=head2 Defined by the consuming class

=head3 load( $data_hash_reference )

Saves data into permanent storage such as a database or file. I<load>
provides a generic call for all output methods (database, file, etc.). The
consuming class defines the actual extraction code.

Your code returns a boolean where B<true> indicates success. Error messages
are sent to the log file.

=cut

requires 'load';


=head3 log

You create this attribute with the command C<with 'MooseX::Log::Log4perl>. It
holds a L<Log::Log4perl> instance. L<Log::Log4perl> provides a very robust
logging setup. You can configure the appropriate setup in one place, and
L<ETL::Load> uses it automatically.

Why doesn't L<ETL::Load> define it? L<ETL::Extract>, L<ETL::Transform>, and
L<ETL::Load> all use the same attribute. I expect your application classes 
consume all three of these. Each definition would interfere with the others.
So I require the consuming class to define it once for all three.

=cut

requires 'log';


=head3 output( $target [, @options ] )

This method connects with the permanent storage. A database may make an actual
network connection. Files are opened and prepped for writing.

The consuming class defines the value of C<$target>.

=cut

requires 'output';


=head1 SEE ALSO

L<Log::Log4perl>, L<ETL::Extract::Record>

=head1 LICENSE

Copyright 2010  The Center for Patient and Professional Advocacy, 
                Vanderbilt University Medical Center
Contact Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=cut

# Perl requires this to load the module.
1;
