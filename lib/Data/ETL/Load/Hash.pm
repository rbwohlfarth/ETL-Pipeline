=pod

=head1 NAME

Data::ETL::Load::Hash - Store data in memory, accessed by a key

=head1 SYNOPSIS

  use ETL;
  extract_using 'DelimitedText', root => 'C:\Data', file_name => qr/\.csv$/;
  transform 1 => ExternalID, Name => PatientName;
  my %data;
  load_into 'Hash', hash => \%data, key => 'ExternalID';
  run;

=head1 DESCRIPTION

ETL stands for I<Extract>, I<Transform>, I<Load>. The ETL pattern executes
data conversions or uploads. It moves data from one system to another. The
ETL family of classes facilitate these data transfers using Perl.

This class defines a data destination for storing data in memory, as a Perl
hash. It acts as temporary storage for further processing.

=cut

package Data::ETL::Load::Hash;
use Moose;

use 5.14.0;
use warnings;
use Moose::Util::TypeConstraints;


our $VERSION = '1.00';


=head1 METHODS & ATTRIBUTES

=head2 Set with the L<Data::ETL/load_into> command

=head3 hash

A hash reference for storing the data. L<Data::ETL/run> creates and destroys
the instance of this class. So your script never has a chance to access any of
the attributes - like the data storage.

Instead, you pass a hash reference through this attribute. And after
L<Data::ETL/run>, it contains all of your data.

=cut

has 'hash' => (
	is  => 'rw',
	isa => 'HashRef[ArrayRef[HashRef[Str]]|HashRef[Str]]',
);


=head3 key

Field name used as the key into the storage hash. The default value is B<key>.

=cut

has 'key' => (
	default => 'key',
	is      => 'rw',
	isa     => 'Str',
);


=head3 duplicates

How should we handle duplicate L</key> values?

=over

=item keep

Store each matching record in a list. Records are added to the list in the
order that they appear. This is the default.

=item overwrite

Only keep the last matching record (overwrite the earlier ones).

=item skip

Only keep the first matching record, skipping over any later ones.

=back

=cut

has 'duplicates' => (
	default => 'keep',
	is      => 'rw',
	isa     => enum( [qw/keep overwrite skip/] ),
);


=head3 clear

This attribute instructs the L</setup> to empty out the hash. Clearing the hash
at the start prevents you from accidently re-using data.

If you are merging more than one file into the hash, then set C<clear> to
B<false>. Otherwise you will only have data from the last file.

=cut

has 'clear' => (
	default => 1,
	is      => 'rw',
	isa     => 'Bool',
);


=head2 Automatically called from L<Data::ETL/run>

=head3 write_record

Saves the contents of the L<Data::ETL::Load/record> in L</hash>.

This method is automatically called by L<Data::ETL/run>.

The function returns the number of records created. If there is an error, then
return B<0> (nothing saved). Otherwise return a B<1> (the number created).

=cut

sub write_record {
	my $self = shift;

	my $storage = $self->hash;
	my $record  = $self->record;
	my $key     = $record->{$self->key};

	if ($self->duplicates eq 'keep') {
		my $value = $storage->{$key};

		if    (!defined( $value )      ) { $storage->{$key} = [$record]; }
		elsif (ref( $value ) eq 'ARRAY') { push @$value, $record; }
		else { $storage->{$key} = [$value, $record]; }
	} elsif ($self->duplicates eq 'skip' and exists $storage->{$key}) {
		return 0;
	} else { $storage->{$key} = $record; }

	return 1;
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

sub setup { my $self = shift; %{$self->hash} = () if $self->clear; }


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

Copyright 2013 (c) Vanderbilt University

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
