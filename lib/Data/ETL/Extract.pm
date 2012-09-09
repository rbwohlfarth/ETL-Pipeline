=pod

=head1 NAME

ETL::Extract - Role for ETL input sources

=head1 DESCRIPTION

ETL stands for I<Extract>, I<Transform>, I<Load>. The ETL pattern executes
data conversions or uploads. It moves data from one system to another. The
ETL family of classes facilitate these data transfers using Perl.

This role defines the Application Programming Interface (API) for all ETL
input sources. An input source controls where your data comes from. This role
defines the methods common to every input source. These methods work
regardless of the data format - CSV file, spreadsheet, database, etc.

=cut

package ETL::Extract;
use Moose::Role;


=head1 COMMANDS

Commands are exported into the C<main::> namespace to be called in your ETL
scripts.

=head3 extract

This command configures the input source. It accepts a hash of setup values.
The contents of that hash are defined by the subclass.

=cut

requires 'extract';


=head1 METHODS & ATTRIBUTES

The ETL classes access these methods and attributes. An ETL script would
never call these directly. If you're writing a new input source, then you
must implement this interface.

=head3 next_record

Loads the next record from the input source into the L</record> hash. This
method is automatically called by L<ETL::Load/load>.

=cut

requires 'next_record';


=head3 record_number

This attribute identifies the last record loaded by L</next_record>. It is for
informational purposes only. Changing this value does not actually skip
records. The count always starts with B<1>, making it equivalent to the
number of records loaded.

=cut

has 'record_number' => (
	default => '0',
	is      => 'rw',
	isa     => 'Int',
);


=head3 record

This hash reference stores the last data record as read from the input source.
The structure of this hash is defined by the subclass.

=cut

has 'record' => (
	is  => 'rw',
	isa => 'Hashref',
);


=head1 SEE ALSO

L<ETL::Load>

=head1 AUTHOR

Robert Wohlfarth <rbwohlfarth@gmail.com>

=head1 LICENSE

This module is distributed under the same terms as Perl itself.

=cut

no Moose;

# Required by Perl to load the module.
1;
