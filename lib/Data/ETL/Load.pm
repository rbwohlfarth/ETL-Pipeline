=pod

=head1 NAME

Data::ETL::Load - Role for ETL data destinations

=head1 SYNOPSIS

  use Moose;
  with 'Data::ETL::Load';

  sub write_record {
    # Add code to save your data here
    ...
  }

=head1 DESCRIPTION

ETL stands for I<Extract>, I<Transform>, I<Load>. The ETL pattern executes
data conversions or uploads. It moves data from one system to another. The
ETL family of classes facilitate these data transfers using Perl.

This role defines the Application Programming Interface (API) for all ETL
data destinations. A data destination controls where your data goes. This role
defines the methods common to every destination. These methods work regardless
of the data format - CSV file, spreadsheet, database, etc.

Every data destination class B<must> implement this role. The L<Data::ETL/run>
command calls these methods as part of the ETL process. Most ETL scripts
never access them directly.

=head2 Why use a role instead of inheritance?

Roles let you force the child class to implement certain methods. Plus a role
lets me create other generic types without having a convuluted inheritance
tree.

=cut

package Data::ETL::Load;
use Moose::Role;


=head1 METHODS & ATTRIBUTES

=head3 set

Set the value of a single field in the intermediate storage. L</write_record>
takes these values and saves them to their final destination.

B<set> accepts two parameters:

=over

=item 1. The field destination name.

=item 2. The value for that field.

=back

There is no return value.

=cut

requires 'set';


=head3 write_record

Saves the contents of the L</record> hash to storage. This method is
automatically called by L<Data::ETL/run>. It takes one parameter - the current
record number.

The function returns the number of records created. If there is an error, then
return B<0> (nothing saved). Otherwise return a B<1> (the number created).

=cut

requires 'write_record';


=head3 record_number

This attribute is the number of records saved in this session. It is for
informational purposes only. Changing this value has no effect.

The role automatically increments this value B<after> every call to
L</write_record>.

=cut

has 'record_number' => (
	default => '0',
	is      => 'rw',
	isa     => 'Int',
);

around 'write_record' => sub {
	my ($original, $self, @arguments) = @_;
	my $count = $original->( $self, @arguments );
	$self->record_number_add( $count );
	return $count;
};


=head3 record_number_add

Add a number to the record count. I do this often enough to warrant this
convenience method. The code only checks that the result is an integer greater
than zero.

=cut

sub record_number_add {
	my ($self, $amount) = @_;
	$self->record_number( $self->record_number + $amount );
	$self->record_number( 0 ) if $self->record_number < 0;
	return $self->record_number;
}


=head3 setup

This method prepares the data destination. Use it to open files, make database
connections, or anything else you need before writing the first record.
L<Data::ETL> calls this method just before the process starts.

Why not do this in the constructor? Child classes may want to modify the
behaviour. By having a specific method, you can use all of the usual Moose
method modifiers.

=cut

requires 'setup';


=head3 finished

This method shuts down the data destination. Use it to close files, disconnect
from the database, or anything else you need after writing the last record.
L<Data::ETL> calls this method at the end of the process.

Why not do this in the destructor? Child classes may want to modify the
behaviour. By having a specific method, you can use all of the usual Moose
method modifiers.

=cut

requires 'finished';


=head1 SEE ALSO

L<Data::ETL>, L<Data::ETL::Extract>

=head1 AUTHOR

Robert Wohlfarth <rbwohlfarth@gmail.com>

=head1 LICENSE

Copyright 2012  Robert Wohlfarth

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;

# Required by Perl to load the module.
1;
