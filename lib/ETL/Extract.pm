=pod

=head1 SYNOPSIS

 use Moose;
 with'ETL::Extract';

=head1 DESCRIPTION

The I<Extract-Transform-Load> (ETL) pattern typically appears with Data 
Warehousing. Data Warehousing covers a subset of the larger data conversion 
problem space. The difference is one of scope. The ETL B<pattern> applies to 
the entire problem space.

L<ETL::Extract> defines the API for a generic I<extract> part of the pattern 
as a L<Moose Role|Moose::Manual::Roles>. You consume L<ETL::Extract> and
define the actual methods that retrieve real data.

=cut

package ETL::Extract;
use Moose::Role;


=head1 METHODS & ATTRIBUTES

=head2 Defined by the consuming class

=head3 extract()

Returns the next record from input. I<extract> provides a generic call for
all input methods - database, file, etc. The consuming class defines the 
actual extraction code.

Your code should return one of two values:

=over

=item An L<ETL::Extract::Record> object.

=item C<undef> for the end of the input.

=back

Your I<extract> method should set these attributes:

=over

=item * end_of_input

=item * position

=back

=cut

requires 'extract';


=head3 input( $source [, @options ] )

This method connects with the input source. A database may make an actual
network connection. Files are opened and prepped for reading.

The consuming class defines the value of C<$source>.

=cut

require 'input';


=head3 log

You create this attribute with the command C<with 'MooseX::Log::Log4perl>. It
holds a L<Log::Log4perl> instance. L<Log::Log4perl> provides a very robust
logging setup. You can configure the appropriate setup in one place, and
L<ETL::Extract> uses it automatically.

Why doesn't L<ETL::Extract> define it? L<ETL::Extract>, L<ETL::Transform>, and
L<ETL::Load> all use the same attribute. I expect your application classes 
consume all three of these. Each definition would interfere with the others.
So I require the consuming class to define it once for all three.

=cut

require log;


=head2 Standard methods and attributes

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


=head3 position

I<position> identifies the last record loaded by I<extract>. You will find
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

L<Log::Log4perl>, L<ETL::Extract::Record>

=head1 LICENSE

Copyright 2010  The Center for Patient and Professional Advocacy, 
                Vanderbilt University Medical Center
Contact Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=cut

no Moose;
__PACKAGE__->meta->make_immutable;

