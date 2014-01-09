=pod

=head1 NAME

MyTestExtract - Simulate an input source for testing

=head1 SYNOPSIS

  use ETL;
  working_folder 'C:\Data';
  extract_from module => 'MyTestExtract';
  transform 0 => ExternalID, 1 => PatientName;
  load_into 'Access';
  run;

=head1 DESCRIPTION

B<ETL> stands for I<Extract-Transform-Load>. You often hear this design
pattern associated with Data Warehousing. In fact, ETL works with almost
any type of data conversion. You read the source (I<Extract>), translate the
data for your target (I<Transform>), and store the result (I<Load>).

This class simulates an input source for unit testing. You would never use
this source for production. It returns hard coded values.

=cut

package MyTestExtract;
use Moose;

use 5.014;
use warnings;


our $VERSION = '1.00';


=head1 METHODS & ATTRIBUTES

This class inherits all of its actions from L<Data::ETL::Extract::UnitTest>.

=cut

extends 'Data::ETL::Extract::UnitTest';


=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=head1 LICENSE

Copyright 2014 (c) Vanderbilt University

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
