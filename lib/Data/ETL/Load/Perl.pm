=pod

=head1 NAME

Data::ETL::Load::Perl - Execute arbitrary Perl code against every record

=head1 SYNOPSIS

  use ETL;
  extract_using 'DelimitedText', root => 'C:\Data', file_name => qr/\.csv$/;
  transform 1 => ExternalID, Name => PatientName;
  my %data;
  load_into 'Perl', execute => sub { say $_->{Name} };
  run;

=head1 DESCRIPTION

ETL stands for I<Extract>, I<Transform>, I<Load>. The ETL pattern executes
data conversions or uploads. It moves data from one system to another. The
ETL family of classes facilitate these data transfers using Perl.

This class defines a data destination for executing arbitrary Perl code on
each and every record. This makes L<Data::ETL> a poor man's filter.

=cut

package Data::ETL::Load::Perl;
use Moose;

use 5.14.0;
use warnings;
use Data::ETL::CodeRef;


our $VERSION = '1.00';


=head1 METHODS & ATTRIBUTES

=head2 Set with the L<Data::ETL/load_into> command

=head3 execute

A code reference that executes once for every record. This code receives the
record hash reference in C<$_> and as the first parameter. You access fields
by the name you gave them in the C<transform_as> command.

This code should return a boolean value. B<True> counts this record. B<False>
does not.

=cut

has 'execute' => (
	is       => 'rw',
	isa      => 'CodeRef',
	required => 1,
);


=head2 Automatically called from L<Data::ETL/run>

=head3 write_record

Execute the code stored in L</execute>.

The function returns the number of records created. If there is an error, then
return B<0> (nothing saved). Otherwise return a B<1> (the number created).

=cut

sub write_record {
	my $self = shift;
	return Data::ETL::CodeRef::run( $self->execute, $self->record );
}


=head3 new_record

The L<Data::ETL::Load::AsHash> role requires this function. In this case, it
resets to an empty hash. This test class has no defined record structure. So
there are no default values.

=cut

sub new_record { {} }


=head3 setup

This method prepares the data destination. It clears out any previous data.
That way you can test more than one script without them contaminating each
other.

=cut

sub setup {}


=head3 finished

This method shuts down the data destination. In this class, it doesn't do
anything.

=cut

sub finished {}


=head1 SEE ALSO

L<Data::ETL>, L<Data::ETL::Load>, L<Data::ETL::AsHash>

=cut

with 'Data::ETL::Load::AsHash';
with 'Data::ETL::Load';


=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=head1 LICENSE

Copyright 2014 (c) Vanderbilt University

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
