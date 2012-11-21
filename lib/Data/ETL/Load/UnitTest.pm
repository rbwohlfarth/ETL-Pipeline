=pod

=head1 NAME

Data::ETL::Load::UnitTest - Data destination for unit testing L<Data::ETL>

=head1 SYNOPSIS

  use ETL;
  extract_using 'DelimitedText', root => 'C:\Data', file_name => qr/\.csv$/;
  transform 1 => ExternalID, Name => PatientName;
  load_into 'UnitTest';
  run;

=head1 DESCRIPTION

ETL stands for I<Extract>, I<Transform>, I<Load>. The ETL pattern executes
data conversions or uploads. It moves data from one system to another. The
ETL family of classes facilitate these data transfers using Perl.

This class defines a data destination for the L<Data::ETL> unit tests.
B<DO NOT use this class in production.> It is only meant for the unit tests.
I took a lot of shortcuts.

=cut

package Data::ETL::Load::UnitTest;
use Moose;


our $VERSION = '1.00';


=head1 METHODS & ATTRIBUTES

=head3 storage

This is a package level variable, not an attribute. This list holds all of
the hash references in the same order that they are processed. The unit tests
can check it after running a test script.

=cut

our @storage;


=head3 write_record

Saves the contents of the L<Data::ETL::Load/record> hash to storage. "Storage"
being nothing more than a list of hashes in memory. It's enough for the unit
tests to confirm that everything worked.

This method is automatically called by L<Data::ETL/run>. It takes no
parameters.

The function returns the number of records created. If there is an error, then
return B<0> (nothing saved). Otherwise return a B<1> (the number created).

=cut

sub write_record { push @storage, shift->record; }


=head3 new_record

The L<Data::ETL::Load::AsHash> role requires this function. In thsi case, it 
resets to an empty hash. This test class has no defined record structure. So 
there are no default values.

=cut

sub new_record { {} }


=head3 setup

This method prepares the data destination. It clears out any previous data.
That way you can test more than one script without them contaminating each
other.

=cut

sub setup { @storage = (); }


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

Robert Wohlfarth <rbwohlfarth@gmail.com>

=head1 LICENSE

Copyright 2012  Robert Wohlfarth

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
