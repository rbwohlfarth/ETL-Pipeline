=pod

=head1 NAME

Data::ETL::Load - This role defines an ETL destination bridge class

=head1 SYNOPSIS

  use Moose;
  with 'Data::ETL::Load';

  sub write_record {
    # Add code to save your data here
    ...
  }

=head1 DESCRIPTION

ETL stands for I<Extract-Transform-Load>. L<Data::ETL> uses
L<bridge classes|Data::ETL/Bridge Classes> for reading and writing files. This
role defines the API for output L<bridge classes|Data::ETL/Bridge Classes> -
those used by the L<Data::ETL/load_into> command.

This role defines the Application Programming Interface (API) for all ETL
output sources. An output source controls where your data comes from. This role
defines the methods common to every output source. These methods work
regardless of the data format - CSV file, spreadsheet, database, etc.

Every output source class B<must> implement this role. The L<Data::ETL/run>
command calls these methods as part of the ETL process. Most ETL scripts
never access them directly.

=head2 Writing Your Own Output Class

=over

=item 1. Create a Perl module.

=item 2. Make it a Moose object: C<use Moose;>.

=item 3. Include this role: C<with 'Data::ETL::Load';>.

=item 4. Use a hash for in-memory storage: C<with 'Data::ETL::Load::AsHash';>.

=item 5. Add the L<write_record> method: C<sub write_record { ... }>.

=item 6. Add the L<setup> method: C<sub setup { ... }>.

=item 7. Add the L<finished> method: C<sub finished { ... }>.

=item 8. In your L<Data::ETL> script, add a line like this: C<load_into 'MyOutput'>. Replace I<MyOutput> with your class name.

=back

=cut

package Data::ETL::Load;
use Moose::Role;


our $VERSION = '1.00';


=head1 METHODS & ATTRIBUTES

B<Note:> This role defines no attributes that are set with the
L<Data::ETL/load_into> command. Each child class defines its own options.

=head2 Implemented by your output class

Your output L<bridge class|Data::ETL/Bridge Classes> must implement all of the
following methods...

=head3 set

It's expensive writing each field individually onto disk. For performance, I
recommend that you save the current record in memory and write it all at once
in L</write_record>. B<set> does this for you.

L<Data::ETL/run> calls B<set> inside of a loop - once for each field. Your
B<set> code plops the values into memory. Then L<write_record> sends it to the
disk.

B<set> accepts two parameters:

=over

=item 1. The output field name.

=item 2. The value for that field.

=back

There is no return value.

=cut

requires 'set';


=head3 write_record

B<write_record> outputs the current record to the file or database. It saves
the current record. This method is called by L<Data::ETL/run> once for each
record.

B<write_record> takes one parameter - the current record number.

B<write_record> returns the number of records created. If there is an error,
then return B<0> (nothing saved). Otherwise return a B<1> (the number created).

=cut

requires 'write_record';


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


=head2 Other methods and attributes

=head3 record_number

This attribute holds the total number of records already saved. It is for
informational purposes only. Changing this value has no effect.

L<Data::ETL/run> automatically increments this value B<after> every call to
L</write_record>.

=cut

has 'record_number' => (
	default => '0',
	is      => 'rw',
	isa     => 'Int',
);

around 'write_record' => sub {
	my ($original, $self, @arguments) = @_;

	# Call "write_record"...
	my $count = $original->( $self, @arguments );

	# Include the new record in the count. Do not let them decrement the count
	# below zero. That's absurd.
	$self->record_number( $self->record_number + $count );
	$self->record_number( 0 ) if $self->record_number < 0;

	# Send the count back to the caller, as if they called "write_record".
	return $count;
};


=head3 extract

This attribute holds a reference to the extract object. This gives your load
classes direct access to information about the source. For example, I put the
file name in error messages.

This attribute has no type check because I build the classes using roles. There
is no base type.

=cut

has 'extract' => (is => 'rw');


=head1 SEE ALSO

L<Data::ETL>, L<Data::ETL::Extract>

=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=head1 LICENSE

Copyright 2013 (c) Vanderbilt University

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;

# Required by Perl to load the module.
1;
