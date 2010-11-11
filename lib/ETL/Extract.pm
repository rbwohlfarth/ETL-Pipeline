=pod

=head1 NAME

ETL::Extract - Base class for ETL input sources

=head1 DESCRIPTION

This class defines the Application Programming Interface (API) for all ETL
input sources. The API allows applications to interact with the source without
worrying about its specific format (CSV file, spreadsheet, database, etc.).

=cut

package ETL::Extract;
use Moose;


=head1 METHODS & ATTRIBUTES

=head2 Override in Child Classes

=head3 extract()

Returns the next record from input. This base method does absolutely nothing.
The child class defines exactly how this works for its input format.

The child class returns one of two values:

=over

=item An L<ETL::Record> object.

=item C<undef> for the end of the input.

=back

The child class also sets these attributes:

=over

=item * end_of_input

=item * position

=back

=cut

sub extract($) { return undef; }


=head2 Standard Methods & Attributes

=head3 end_of_input

I<end_of_input> indicates when we reach the end of the input data. It holds
a boolean flag: B<true> = no more data.

I<extract> uses this flag. When the falg becomes true, I<extract> returns
the C<undef> value.

=cut

has 'end_of_input' => (
	default => 0,
	is      => 'rw',
	isa     => 'Bool',
);


=head3 log

This attrbiute provides an access point into the L<Log::Log4perl> logging
system. Child classes must log all errors messages.

=cut

with 'MooseX::Log::Log4perl';


=head3 position

I<position> identifies the last record loaded by L<extract()>. You will find
this useful for error messages.

The exact value depends on the input type. For example, a text file might have
the line number. A spreadsheet would keep the row number. A database records
the primary key.

B<WARNING:> Changing I<position> has no effect on the actual position. You 
cannot use it to skip records.

=cut

has 'position' => (
	default => '0',
	is      => 'rw',
	isa     => 'Str',
);


=head1 SEE ALSO

L<ETL>, L<ETL::Record>, L<Log::Log4perl>

=head1 LICENSE

Copyright 2010  The Center for Patient and Professional Advocacy, Vanderbilt University Medical Center
Contact Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=cut

# Perl requires this to load the module.
1;

