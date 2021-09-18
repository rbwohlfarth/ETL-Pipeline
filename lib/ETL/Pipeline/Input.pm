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

An I<input source> is a Moose object with at least one method - C<run>. This
role basically defines the requirement for the B<run> method. It should be
consumed by B<all> input source classes. L<ETL::Pipeline> relies on the input
source having this role.

How do you create an I<input source>? Create a Moose class. Add any attributes
that your source needs. Define the C<run> method. C<run> receives one
parameter - the L<ETL::Pipeline> object. C<run> should call the
L<ETL::Pipeline/record> method after it loads each input record. This triggers
the B<Transform> and B<Load> parts of B<ETL>.

L<ETL::Pipeline> provides several other utility methods for your input source.
See the L<ETL::Pipeline> documentation for a complete list.

=head2 Why this way?

Input sources mostly follow the basic algorithm of open, read, process, and
close. I originally had the role define methods for each of these steps. That
was a lot of work, and kind of confusing. This way, the input source only
I<needs> one code block that does all of these steps - in one place. So it's
easier to troubleshoot and much simpler.

=head2 Adding a new input source

Out of the box, L<ETL::Pipeline> provides a few input sources such as Microsoft
Excel and CSV (comma seperated variable) files. To add your own formats...

=over

=item 1. Create a Perl module. Name it C<ETL::Pipeline::Input::...>.

=item 2. Make it a Moose object: C<use Moose;>.

=item 3. Include this role: C<with 'ETL::Pipeline::Input';>.

=item 4. Define the C<run> method.

=item 5. Add any attributes needed by your source.

=back

Ta-da! Your input source is ready to use:

  $etl->input( 'YourNewSource' );

Some important things to remember about C<run>...

=over

=item C<run> receives one parameter - the L<ETL::Pipeline> object.

=item Should include all the code to open, read, and close the input source.

=item After reading a record, call L<ETL::Pipeline/record>.

=item L<ETL::Pipeline> provides a few helper methods for input sources.

=back

=head2 Does B<ETL::Pipeline::Input> only work with files?

No. B<ETL::Pipeline::Input> works for any source of data, such as SQL queries,
CSV files, or network sockets. Tailor the C<run> method for whatever suits your
needs.

The B<ETL::Pipeline> distribution comes with a helpful role for file inputs -
L<ETL::Pipeline::Input::File>. Consume L<ETL::Pipeline::Input::File> in your
inpiut source class to have access to some standardized attributes.

=cut

package ETL::Pipeline::Input;

use 5.014000;

use Moose::Role;


our $VERSION = '3.00';


=head1 METHODS & ATTRIBUTES

=head3 run

You define this method in the consuming class. It should open the file, read
each record, call L<ETL::Pipeline/record> after each record, and close the file.
This method is the workhorse. It defines the main ETL loop.
L<ETL::Pipeline/record> acts as a callback.

I say I<file>. It really means I<input source> - whatever that might be.

=cut

requires 'run';


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Input::File>, L<ETL::Pipeline::Output>

=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vumc.org>

=head1 LICENSE

Copyright 2021 (c) Vanderbilt University Medical Center

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;

# Required by Perl to load the module.
1;
