=pod

=head1 NAME

Data::ETL::Extract - Role for ETL input sources

=head1 SYNOPSIS

  use Moose;
  with 'Data::ETL::Extract';

  sub next_record {
    # Add code to read your data here
    ...
  }

=head1 DESCRIPTION

ETL stands for I<Extract>, I<Transform>, I<Load>. The ETL pattern executes
data conversions or uploads. It moves data from one system to another. The
ETL family of classes facilitate these data transfers using Perl.

This role defines the Application Programming Interface (API) for all ETL
input sources. An input source controls where your data comes from. This role
defines the methods common to every input source. These methods work
regardless of the data format - CSV file, spreadsheet, database, etc.

Every input source class B<must> implement this role. The L<Data::ETL/run>
command calls these methods as part of the ETL process. Most ETL scripts
never access them directly.

=head2 Why use a role instead of inheritance?

Roles let you force the child class to implement certain methods. Plus a role
lets me create other generic types without having a convuluted inheritance
tree.

=cut

package Data::ETL::Extract;
use Moose::Role;


=head1 METHODS & ATTRIBUTES

=head3 next_record

Loads the next record from the input source into the L</record> hash. This
method is automatically called by L<Data::ETL/run>. It takes no parameters.

The function returns the number of records processed. It is conceivable that
a format skips empty records. Count those in the return value. A value of one
or more indicates success. A value of zero means that there are no more
records.

=cut

requires 'next_record';


=head3 record_number

This attribute identifies the last record loaded by L</next_record>. It is for
informational purposes only. Changing this value does not actually skip
records. The count always starts with B<1>, making it equivalent to the
number of records loaded.

The role automatically increments this value after every call to
L</next_record>.

=cut

has 'record_number' => (
	default => '0',
	is      => 'rw',
	isa     => 'Int',
);

around 'next_record' => sub {
	my ($original, $self, @arguments) = @_;
	my $count = $original->( $self, @arguments );
	$self->record_number_add( $count );
	return $count;
};


=head3 record_number_add

Add a number to the current record number. I do this often enough to warrant
this convenience method. The code only checks that the result is an integer
greater than zero.

=cut

sub record_number_add {
	my ($self, $amount) = @_;
	$self->record_number( $self->record_number + $amount );
	$self->record_number( 0 ) if $self->record_number < 0;
	return $self->record_number;
}


=head3 record

This hash reference stores the last data record as read from the input source.
The structure of this hash is defined by the subclass.

=cut

has 'record' => (
	is  => 'rw',
	isa => 'HashRef[Str]',
);


=head3 setup

This method prepares the input source. Use it to open files, make database
connections, or anything else you need before reading the first record.
L<Data::ETL> calls this method just before the process starts.

Why not do this in the constructor? Child classes may want to modify the
behaviour. By having a specific method, you can use all of the usual Moose
method modifiers.

=cut

requires 'setup';


=head3 finished

This method shuts down the input source. Use it to close files, disconnect
from the database, or anything else you need after reading the last record.
L<Data::ETL> calls this method at the end of the process.

Why not do this in the destructor? Child classes may want to modify the
behaviour. By having a specific method, you can use all of the usual Moose
method modifiers.

=cut

requires 'finished';


=head1 SEE ALSO

L<Data::ETL>, L<Data::ETL::Load>

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
