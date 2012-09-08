=pod

=head1 NAME

ETL::Load - Role for ETL data destinations

=head1 DESCRIPTION

ETL stands for I<Extract>, I<Transform>, I<Load>. The ETL pattern executes
data conversions or uploads. It moves data from one system to another. The
ETL family of classes facilitate these data transfers using Perl.

This role defines the Application Programming Interface (API) for both the
I<Transform> and I<Load> parts of the process.

The I<Load> API defines all ETL destinations. A data destination controls
where your data goes to. This role defines the methods common to every
destination. These methods work regardless of the data format - CSV file,
spreadsheet, database, etc.

=head2 Why is the transform stuff in here?

The transform process doesn't really change. Yes, the field names change. The
actual algorithm doesn't. That means that every ETL script has the exact same
transformation process. Including it as part of I<Load> cust down on the
number of modules an ETL script must C<use>.

In my mind, I<Transform> has more in common with I<Load> than I<Extract>.
Extra transformation commands typically have some relation to the destination
format.

=cut

package ETL::Load;
use Moose::Role;


=head1 COMMANDS

Commands are exported into the C<main::> namespace to be called in your ETL
scripts.

=head3 load

This command configures data destination and begins the ETL process. This
command kicks off the data conversion. It should be the last statement in your
ETL script.

This command accepts a hash of setup values. The contents of that hash are
defined by the subclass.

=cut

requires 'load';


=head3 transform

Copy data from the L<ETL::Extract/record|input record> into the
L</record|output record>. This command accepts a hash. The keys name
L<ETL::Extract/record|input fields>. The values name L</record|output fields>.

=cut

sub transform {
}


=head1 METHODS & ATTRIBUTES

The ETL classes access these methods and attributes. An ETL script would
never call these directly. If you're writing a new data destination, then you
must implement this interface.

=head3 record

This hash reference stores the data record that goes to the destination.

=cut

has 'record' => (
	is  => 'rw',
	isa => 'Hashref',
);


=head1 SEE ALSO

L<ETL::Extract>

=head1 AUTHOR

Robert Wohlfarth <rbwohlfarth@gmail.com>

=head1 LICENSE

This module is distributed under the same terms as Perl itself.

=cut

no Moose;

# Required by Perl to load the module.
1;
