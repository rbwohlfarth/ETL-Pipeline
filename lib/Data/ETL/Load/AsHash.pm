=pod

=head1 NAME

Data::ETL::Load::AsHash - Cache data as a hash for import to the destination

=head1 SYNOPSIS

  with 'Data::ETL::Load::AsHash';
  
  sub new_record {
      # Add you code to reset the record
      ...
  }

=head1 DESCRIPTION

ETL stands for I<Extract>, I<Transform>, I<Load>. The ETL pattern executes
data conversions or uploads. It moves data from one system to another. The
ETL family of classes facilitate these data transfers using Perl.

This role caches data in a hash structure. Your data destination class will
write the data to the actual destination.

Almost any database type destination mimics Perl's hash structure (key-value 
pairs). This role let you quickly implement a hash as the storage mechanism for
your data destinations. 

=cut

package Data::ETL::Load::AsHash;
use Moose::Role;

use 5.14.0;


our $VERSION = '1.00';


=head1 METHODS & ATTRIBUTES

=head2 Automatically called from L<Data::ETL/run>

=head3 set

Sets the value of an individual field. B<set> accepts two parameters:

=over

=item 1. The field destination name.

=item 2. The value for that field.

=back

There is no return value.

=cut

sub set { 
	my ($self, $column, $value) = @_;
	$self->record->{$column} = $value;
}


=head2 Other Methods and Attributes

=head3 record

This is the storage hash. It holds just the current record. The keys are field
names. The values are, well, the values.

=cut

has 'record' => (
	builder => 'new_record',
	is      => 'rw',
	isa     => 'HashRef[Maybe[Str]]',
);


=head3 new_record

Clear the internal storage in preparation for a new record. Your data 
destination class B<must> define this method. It returns a hash reference of
default values.

B<Note:> This method should not set the L</record> attribute. Return a hash
reference. The caller sets L</record> using that reference.

=cut

requires 'new_record';

after 'write_record' => sub {
	my $self = shift;
	$self->record( $self->new_record );
};


=head1 SEE ALSO

L<Data::ETL>, L<Data::ETL::Extract::AsHash>, L<Data::ETL::Load>

=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=head1 LICENSE

Copyright 2012  Center for Patient and Professional Advocacy,
                Vanderbilt University Medical Center

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

# Required for Perl to load the module.
1;