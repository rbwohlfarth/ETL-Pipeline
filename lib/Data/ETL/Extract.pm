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

ETL stands for I<Extract-Transform-Load>. L<Data::ETL> uses
L<bridge classes|Data::ETL/Bridge Classes> for reading and writing files. This
role defines the API for input L<bridge classes|Data::ETL/Bridge Classes> -
those used by the L<Data::ETL/extract_from> command.

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

=head2 Adding a new file format

Out of the box, L<Data::ETL> supports Microsoft Excel and CSV (comma seperated
variable) files. So what happens when you run into something new?

=over

=item 1. Create a Perl module.

=item 2. Make it a Moose object: C<use Moose;>.

=item 3. Include this role: C<with 'Data::ETL::Extract';>.

=item 4. Use a hash for in-memory storage: C<with 'Data::ETL::Extract::AsHash';>.

=item 5. Add the L<next_record> method: C<sub next_record { ... }>.

=item 6. Add the L<setup> method: C<sub setup { ... }>.

=item 7. Add the L<finished> method: C<sub finished { ... }>.

=item 8. In your L<Data::ETL> script, add a line like this: C<load_into 'MyOutput'>. Replace I<MyOutput> with your class name.

=back

=cut

package Data::ETL::Extract;
use Moose::Role;

use 5.14.0;
use Data::ETL::CodeRef;


our $VERSION = '1.00';


=head1 METHODS & ATTRIBUTES

=head2 Set with the L<Data::ETL/extract_from> command

=head3 bypass_if

Sometimes you just get bad data. This code reference checks for those times
and moves on to the next record.

If the code returns B<true>, then L<Data::ETL/run> ignores this record and
moves to the next one. This keeps the record count synchronized with the
input source.

If the code returns B<false>, then L<Data::ETL/run> processes the record
normally.

B<Data::ETL/run> passes in a reference to the L<Data::ETL::Extract> object
two ways...

=over

=item 1. As the one and only parameter to your code.

=item 2. As C<$_>.

=back

By default, the L<Data::ETL/run> processes B<all> records in the file.

I<Note:> The bypass does not work on any headers parsed during setup.
L<Data::ETL/run> only executes this code against data records.

=cut

has 'bypass_if' => (
	is  => 'rw',
	isa => 'Maybe[CodeRef]',
);


=head3 stop_if

Under normal circumstances, the ETL process when you reach the end of the
input. This code reference lets you break out of the processing loop early.
The ETL process stops reading records if this subroutine returns a true value.
Reporting software sometimes puts footer information at the bottom. You can
use this subroutine to look for those footers and stop processing the file.

B<Data::ETL::Extract> passes in a reference to itself two ways...

=over

=item 1. As the one and only parameter to your code.

=item 2. As C<$_>.

=back

By default, the ETL process reads B<all> records in the file.

=cut

has 'stop_if' => (
	is  => 'rw',
	isa => 'Maybe[CodeRef]',
);


=head3 filter

This attribute holds a code reference. The code filters values returned by the
L</get> method. You can define NULL values from databases, blank out
placeholder text like B<< <N/S> >>, or remove invalid characters.
B<Data::ETL::Extract> runs this code every time you retrieve the value from a
field.

The filter code does not have access to the B<Data::ETL::Extract> object. You
can not check the value of other fields inside of your code. It only has
access to the current field's value...

=over

=item 1. In C<$_>.

=item 2. As the one and only parameter to your code.

=back

The default filter trims whitespace from the start and end of the value. To
turn off the trimming, do this: C<filter => sub { $_ }>.

=cut

use String::Util qw/trim/;

has 'filter' => (
	default => sub { \&trim },
	is      => 'rw',
	isa     => 'CodeRef',
);

around 'get' => sub {
	my ($original, $self, @arguments) = @_;
	return Data::ETL::CodeRef::run( $self->filter,
		$original->( $self, @arguments ) );
};


=head3 debug

B<Data::ETL::Extract> executes this code once for every input record -
including report headers. Use this for tracking down data issues. The code can
do anything.

B<Data::ETL::Extract> passes in a reference to itself two ways...

=over

=item 1. As the one and only parameter to your code.

=item 2. As C<$_>.

=back

=cut

has 'debug' => (
	is  => 'rw',
	isa => 'Maybe[CodeRef]',
);


=head2 Automatically called from L<Data::ETL/run>

=head3 next_record

Loads the next record from the input source into the L</record> hash. This
method is automatically called by L<Data::ETL/run>. It takes one optional
parameter: a boolean flag. A B<true> value says to load exactly one record,
regardless of any logic. The code is skipping these records and requires an
exact count. B<False> says to load the record normally.

The function returns the number of records processed. It is conceivable that
a format skips empty records. Count those in the return value. A value of one
or more indicates success. A value of zero means that there are no more
records.

=cut

requires 'next_record';


=head3 get

Return the value of a single field. The only parameter is a field name. Since
the child class implements the actual storage, the I<field name> can really
be anything. For example, and XML file might accept an XPath.

The return value is the data that came from the file.

The L<Data::ETL/transform> process calls this method for each input field that
was mapped to the data destination.

=cut

requires 'get';


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


=head2 Other Methods & Attributes

=head3 record_number

This attribute identifies the last record loaded by L</next_record>. It is for
informational purposes only. Changing this value does not actually skip
records. The count always starts with B<1>, making it equivalent to the
number of records loaded.

The role automatically increments this value after every call to
L</next_record>.

=head3 increment_record_number

This method increments L</record_number> by the given number. It accepts an
integer as its only parameter.

=cut

has 'record_number' => (
	default => '0',
	handles => {increment_record_number => 'inc'},
	is      => 'rw',
	isa     => 'Int',
	traits  => [qw/Counter/],
);

after 'next_record' => sub { shift->increment_record_number };


=head3 set_field_names

This method processes a record with field names. It is called internally, after
L</setup>. This lets the transform stage use friendly names specific to the
input source.

=cut

requires 'set_field_names';


=head1 SEE ALSO

L<Data::ETL>, L<Data::ETL::Load>

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
