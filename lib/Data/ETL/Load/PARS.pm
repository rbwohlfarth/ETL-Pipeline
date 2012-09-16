=pod

=head1 NAME

Data::ETL::Load::PARS - Data destination for uploads into PARS

=head1 SYNOPSIS

  use ETL;
  extract_using 'Excel', root => 'C:\Data', file_name => qr/\.xls(x|m)?$/;
  transform A => ExternalID, Name => PatientName;
  set ClientID => 50;
  load_into 'PARS', text_headers => [qw/Provider Department/];
  run;

=head1 DESCRIPTION

ETL stands for I<Extract>, I<Transform>, I<Load>. The ETL pattern executes
data conversions or uploads. It moves data from one system to another. The
ETL family of classes facilitate these data transfers using Perl.

This class stores data in an intermediate MS Access database for verification
before uploading into PARS. It provides all of the data formatting and
verification for PARS.

This class is specific to the CPPA. It will not be of any use to anyone else.

=cut

package Data::ETL::Load::PARS;
use Moose;

with 'Data::ETL::Load';

use File::Copy;
use File::Spec::Functions qw/catpath splitpath/;
use MSAccess;
use String::Util qw/define hascontent/;


=head2 Field Names

These are the standard fields that we save into the C<Export> table. Use these
in your script's L<Date::ETL/transform> call. They directly correspond with the
columns in C<tblComplaint>.

=over

=item * ClientID (required)

=item * ExternalID (required)

=item * EntityID (optional, default = "")

=item * Date (required, any format accepted by L<Date::Manip>)

=item * Text (required)

=item * PatientName (optional, default = "")

=item * PatientMRN (optional, default = NULL)

=item * ComplaintTypeID (optional, default = 1)

=item * Advocate (optional, default = "")

=back

Your L<Date::ETL/transform> call should also set the fields named in
L</text_headers> and L</text_fields>. Those names are user defined, so I can't
actually list them here.

=head2 Why use Access?

MS Access gives me chance to eyeball the data. Every so often, a client
changes their format. And we can't tell unless we see a bunch of records that
look funny. This happens without warning. So as a backup measure, I want a
human to scan the data before it goes live.

Secondly, I also put some validation logic in Access queries. So changes to
the database affect code in the database - not your upload scripts. This
class gets the data into Access. Access should make sure the data is okay for
loading into PARS.

=head1 METHODS & ATTRIBUTES

=head3 write_record

Saves the contents of the L</record> hash to the Access database. This method
is automatically called by L<Data::ETL/run>. It takes no parameters.

The function returns the number of records created. If there is an error, then
return B<0> (nothing saved). Otherwise return a B<1> (the number created).

=cut

sub write_record {
	my ($self) = @_;
	my $record = $self->record;
	my @text;

	# Write the text headers to the database.
	my $sth = $self->dbh->prepare( <<SQL );
INSERT INTO Headers (ExternalID, Header, Value)
VALUES (?, ?, ?)
SQL

	foreach my $field (@{$self->text_headers}) {
		my $value = $record->{$field};

		$sth->bind_param( 1, $record->{ExternalID}, SQL_VARCHAR );
		$sth->bind_param( 2, $field               , SQL_VARCHAR );
		$sth->bind_param( 3, $value               , SQL_VARCHAR );

		$sth->execute;
		push @text, "$field: $value";
	}

	push( @text, '*' x 48 ) if scalar( @{$self->text_headers} );

	# Build the text field by combining the input fields.
	push( @text, $record->{Text} ) if exists $record->{Text};
	push( @text, "", "$_:", $record->{$_} ) foreach (@{$self->text_fields});

	# Set default values for fields that rarely change.
	$record->{ComplaintTypeID} = 1 unless exists $record->{ComplaintTypeID};

	# Write the complaint record to the database.
	$sth = $self->dbh->prepare( <<SQL );
INSERT INTO Export (
	ClientID, ExternalID, EntityID,
	[Date], [Text], PatientName, PatientMRN,
	ComplaintTypeID, Advocate
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
SQL

	$sth->bind_param( 1, $record->{ClientID}              , SQL_INTEGER     );
	$sth->bind_param( 2, $record->{ExternalID}            , SQL_VARCHAR     );
	$sth->bind_param( 3, define( $record->{EntityID} )    , SQL_VARCHAR     );
	$sth->bind_param( 4, MSAccess::date( $record->{Date} ), SQL_DATE        );
	$sth->bind_param( 5, join( "\r\n", @text )            , SQL_LONGVARCHAR );
	$sth->bind_param( 6, define( $record->{PatientName} ) , SQL_VARCHAR     );
	$sth->bind_param( 7, $record->{PatientMRN}            , SQL_VARCHAR     );
	$sth->bind_param( 8, $record->{ComplaintTypeID}       , SQL_INTEGER     );
	$sth->bind_param( 9, define( $record->{Advocate} )    , SQL_VARCHAR     );

	# Force the "true" to "1" because it is a count, not a boolean.
	return ($sth->execute ? 1 : 0);
}


=head3 text_headers

A list of fields that we prepend to the text. The field name is added as a
prompt, followed by a colon, then the value. These fields are always added in
this order. That's why I used a list - to preserve the order.

=cut

has 'text_headers' => (
	default => sub { [] },
	is      => 'rw',
	isa     => 'ArrayRef[Str]',
);


=head3 text_fields

A list of fields that we concatenate to make the complaint text. The field
name is put at the top, like a heading. The code adds a blank line before each
section.

L</write_record> puts the C<Text> field in first. Then it appends these fields.
These fields I<add to> the value of C<Text>. They do not replace it.

For example, RL Solutions sends both a C<Description> field and a
C<Resolution> field. C<Description> tranforms into C<Text> field. And I add
I<Resolution> to this list. So L</write_record> appends the C<Resolution>
comments onto the end of the C<Description>.

=cut

has 'text_fields' => (
	default => sub { [] },
	is      => 'rw',
	isa     => 'ArrayRef[Str]',
);


=head3 setup

This method creates and connects with the MS Access database. It copies a
template database. The Access database lets me manually verify the data
before loading it into production.

The database file goes into the same directory as the input file. Consequently,
this class is designed to work with input sources that implement the
L<Data::ETL::Extract::File> role.

The template database is hard coded:
B<H:\Templates\Data Management\Upload.accdb>.

=cut

sub setup {
	my ($self, $extract) = @_;

	# Make sure we have the information to finish.
	die "Your input source does not work with Data::ETL::Load::PARS.\nYou must use a source that implements Data::ETL::Extract::File.\n"
		unless $extract->does( 'Data::ETL::Extract::File' );

	# Copy the template Access database into the data file folder.
	my ($volume, $directory, undef) = splitpath( $extract->path );
	my $target = catpath( $volume, $directory, 'Upload.accdb' );
	copy( 'H:\Templates\Data Management\Upload.accdb', $target );

	# Connect to the database.
	$self->dbh( MSAccess::using_file( $target ) );
}


=head3 finished

This method shuts down the data destination. It cleanly disconnects from the
Access database.

=cut

sub finished { $self->dbh->disconnect; }


=head2 Internal Method and Attributes

You should never use these items. They can change at any moment. I documented
them for the module maintainers.

=head3 dbh

This attribute holds a DBI database handle. DBI interfaces with the Access
database. L</setup> sets this automatically. If you change it, things stop
working. So don't change it.

=cut

has 'dbh' => (is => 'rw');


=head1 SEE ALSO

L<Data::ETL>, L<Data::ETL::Extract>, L<Data::ETL::Extract::File>,
L<Data::ETL::Load>

=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=head1 LICENSE

Copyright 2012  Center for Patient and Professional Advocacy,
                Vanderbilt University Medical Center

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
