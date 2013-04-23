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


our $VERSION = '1.00';


=head1 METHODS & ATTRIBUTES

=head2 Set with the L<Data::ETL/extract_from> command

=head3 bypass_if

Sometimes you just get bad data. This code reference checks for those times
and skips moves on to the next record.

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
	default => sub { sub { 0 } },
	is      => 'rw',
	isa     => 'CodeRef',
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
	default => sub { sub { 0 } },
	is      => 'rw',
	isa     => 'CodeRef',
);

around 'next_record' => sub {
	my ($original, $self, @arguments) = @_;
	my $count = $original->( $self, @arguments );

	# 0 = stop processing this file.
	local $_;
	$_ = $self;
	return ($self->stop_if->( $self ) ? 0 : $count);
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
	default => sub { sub {} },
	is      => 'rw',
	isa     => 'CodeRef',
);

after 'next_record' => sub {
	my $self = shift @_;

	local $_;
	$_ = $self;

	$self->debug->( $self );
};


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

=head3 add_records

This method increments L</record_number> by the given number. It accepts an
integer as its only parameters.

=cut

has 'record_number' => (
	default => '0',
	handles => {add_records => 'add'},
	is      => 'rw',
	isa     => 'Int',
	traits  => [qw/Number/],
);

around 'next_record' => sub {
	my ($original, $self, @arguments) = @_;
	my $count = $original->( $self, @arguments );

	$self->add_records( $count );
	return $count;
};


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
