=pod

=head1 NAME

Data::ETL::Extract::UnitTest - Simulate an input source for testing

=head1 SYNOPSIS

  use ETL;
  working_folder 'C:\Data';
  extract_from 'UnitTest';
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

package Data::ETL::Extract::UnitTest;
use Moose;

use strict;
use warnings;

use 5.014;


our $VERSION = '1.00';


=head1 METHODS & ATTRIBUTES

=head2 Automatically called from L<Data::ETL/run>

=head3 next_record

Read one record from the file and populate L<Data::ETL::Extract/record>. The
method returns the number of records loaded. A B<0> means that we reached the
end of the file.

C<next_record> uses the field number as the name. Field numbers start at B<0>.

=cut

sub next_record {
	my $self = shift;

	my $fields = shift @{$self->data};
	if (defined $fields) {
		my %record;
		$record{$_} = $fields->[$_] foreach (0 .. $#$fields);
		$self->record( \%record );
		return 1;
	} else { return 0; }
}


=head3 setup

This method configures the input source. In this object, that means opening
the file and looking for a header record. If the file has a header row, then
I name the fields based on the header row. You can identify data by the
field name or by the column name. See L<Data::ETL::Extract::AsHash/headers>
for more information.

=cut

sub setup {}


=head3 finished

This method shuts down the input source. In our case, it does nothing.

=cut

sub finished {}


=head2 Internal Attributes and Methods

You should never use these items. They can change at any moment. I documented
them for the module maintainers.

=head3 data

An array of test data returned as the input. Each value is hard coded and
unique. This lets the tests determine which lines it loaded.

=cut

has 'data' => (
	default => sub { [
		[qw/Header1 Header2 Header3 Header4/],
		[qw/Field1 Field2 Field3 Field4 Field5/],
		[qw/Field6 Field7 Field8 Field9 Field0/],
	] },
	is  => 'ro',
	isa => 'ArrayRef[ArrayRef[Str]]',
);


=head1 SEE ALSO

L<Data::ETL>, L<Data::ETL::Extract>, L<Data::ETL::Extract::AsHash>

=cut

with 'Data::ETL::Extract::AsHash';
with 'Data::ETL::Extract';


=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=head1 LICENSE

Copyright 2013 (c) Vanderbilt University

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
