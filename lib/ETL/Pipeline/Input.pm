=pod

=head1 NAME

ETL::Pipeline::Input - Role for ETL::Pipeline input sources

=head1 SYNOPSIS

  use Moose;
  with 'ETL::Pipeline::Input';

  sub next_record {
    # Add code to read your data here
    ...
  }

=head1 DESCRIPTION

L<ETL::Pipeline> reads data from an input source, transforms it, and writes
the information to an output destination. This role defines the required
methods and attributes for input sources. Every input source B<must> implement
B<ETL::Pipeline::Input>.

L<ETL::Pipeline> works by calling the methods defined in this role. The role
presents a common interface. It works as a shim, tying file parsing modules
with L<ETL::Pipeline>. For example, CSV files are parsed with the L<Text::CSV>
module. L<ETL::Pipeline::Input::DelimitedText> wraps around L<Text::CSV>.
L<ETL::Pipeline::Input::DelimitedText> implements this role by calling
L<Text::CSV>.

=head2 Adding a new input source

Out of the box, L<ETL::Pipeline> provides input sources for Microsoft Excel and
CSV (comma seperated variable) files. To add your own formats...

=over

=item 1. Create a Perl module. Name it C<ETL::Pipeline::Input::...>.

=item 2. Make it a Moose object: C<use Moose;>.

=item 3. Include the role: C<with 'ETL::Pipeline::Input';>.

=item 4. Add the L</next_record> method: C<sub next_record { ... }>.

=item 5. Add the L</configure> method: C<sub configure { ... }>.

=item 6. Add the L</finish> method: C<sub finish { ... }>.

=back

Ta-da! Your input source is ready to use:

  $etl->input( 'YourNewSource' );

=head2 Does B<ETL::Pipeline::Input> only work with files?

No. B<ETL::Pipeline::Input> works for any source of data, such as SQL queries,
CSV files, or network sockets. Write a L</next_record> method using whatever
method suits your needs.

This documentation refers to files because that is what I use the most. Don't
let that fool you! B<ETL::Pipeline::Input> was designed to work seamlessly with
files and non-files alike.

=cut

package ETL::Pipeline::Input;
use Moose::Role;

use 5.014000;
use String::Util qw/trim/;


our $VERSION = '2.03';


=head1 METHODS & ATTRIBUTES

=head3 pipeline

B<pipeline> returns the L<ETL::Pipeline> object using this input source. You
can access information about the pipeline inside the methods.

L<ETL::Pipeline/input> automatically sets this attribute.

=cut

has 'pipeline' => (
	is       => 'ro',
	isa      => 'ETL::Pipeline',
	required => 1,
);


=head2 Arguments for L<ETL::Pipeline/input>

=head3 leave_whitespace

B<ETL::Pipeline::Input> automatically removes leading and trailing whitespace
on all fields. 99.9% of the time, this is what you want.

B<leave_whitespace> is a boolean flag to override that behaviour. When set to
I<TRUE>, B<ETL::Pipeline::Input> leaves the white space alone. Your ETL scripts
should take this into account.

  ETL::Pipeline->new( {
    input => ['Excel', leave_whitespace => 1],
    ...
  } )->process;

=cut

has 'leave_whitespace' => (
	default => 0,
	is      => 'rw',
	isa     => 'Bool',
);


=head2 Called from L<ETL::Pipeline/process>

=head3 next_record

B<next_record> reads the next single record from the input source.
L<ETL::Pipeline/process> calls this method inside of a loop. B<next_record>
returns a boolean flag. A I<true> value means success getting the record. A
I<false> value indicates the end of the input - no more records.

The implmenting class must define this method.

  while ($input->next_record) {
    ...
  }

=cut

requires 'next_record';


=head3 get

B<get> returns a single value from the current record.

B<ETL::Pipeline::Input> does not define how L</next_record> stores its data
internally. You should use the format that best suits your needs. For example,
L<ETL::Pipeline::Input::Excel> uses an L<Spreadsheet::XLSX> object. The B<get>
method accesses the L<Spreadsheet::XLSX> object methods to retrieve fields.

B<get> is defined by your input source. L<ETL::Pipeline/process> passes in the
value from the L<ETL::Pipeline/mapping> hash. It would normally be something
like a scalar value (string), regular expression, or array reference. B<get>
macthes that against its knowledge of the input fields and returns the
corresponding data value.

The implmenting class must define this method. If your code finds multiple
fields that match the given name, it should throw an error with C<die>.

  # Retrieve one field named 'A'.
  $etl->get( 'A' );

  # Retrieve the field from the column 'ID Num'.
  $etl->get( qr/id\s*num/i );

  # A list is used to build composite field names.
  $etl->get( ['/root', '/first'] );

B<ETL::Pipeline::Input> automatically trims leading and trailing white space.
You do not need to do this inside your B<get> method.

=cut

requires 'get';


around 'get' => sub {
	my ($original, $self, @arguments) = @_;

	if ($self->leave_whitespace) {
		return $original->( $self, @arguments );
	} else {
		return trim( $original->( $self, @arguments ) );
	}
};


=head3 configure

B<configure> prepares the input source. It can open files, make database
connections, or anything else required before reading the first record.

Why not do this in the class constructor? Some roles add automatic
configuration. Those roles use the usual Moose method modifiers, which would
not work with the constructor.

This B<configure> - for the input source - is called I<before> the
L<ETL::Pipeline::Output/configure> of the output destination. This method
should not rely on the configuration of the output destination.

The implmenting class must define this method.

  $input->configure;

=cut

requires 'configure';


=head3 finish

B<finish> shuts down the input source. It can close files, disconnect
from the database, or anything else required to cleanly terminate the input.

Why not do this in the class destructor? Some roles add automatic functionality
via Moose method modifiers. This would not work with a destructor.

This B<finish> - for the input source - is called I<after> the
L<ETL::Pipeline::Output/finish> of the output destination. This method should
not rely on the configuration of the output destination.

The implmenting class must define this method.

  $input->finish;

=cut

requires 'finish';


=head2 Other Methods & Attributes

=head3 record_number

The B<record_number> attribute tells you how many total records have been read
by L</next_record>. The count includes headers and L</skip_if> records.

The first record is always B<1>.

B<ETL::Pipeline::Input> automatically increments the counter after
L</next_record>. The L</next_record> method should not change B<record_number>.

=head3 decrement_record_number

This method decreases L</record_number> by one. It can be used to I<back out>
header records from the count.

  $input->decrement_record_number;

=head3 increment_record_number

This method increases L</record_number> by one.

  $input->increment_record_number;

=cut

has 'record_number' => (
	default => '0',
	handles => {
		decrement_record_number => 'dec',
		increment_record_number => 'inc',
	},
	is      => 'ro',
	isa     => 'Int',
	traits  => [qw/Counter/],
);

around 'next_record' => sub {
	my $original = shift;
	my $self     = shift;

	my $result = $self->$original( @_ );
	$self->increment_record_number if $result;
	return $result;
};


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Output>

=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vumc.org>

=head1 LICENSE

Copyright 2019 (c) Vanderbilt University Medical Center

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;

# Required by Perl to load the module.
1;
