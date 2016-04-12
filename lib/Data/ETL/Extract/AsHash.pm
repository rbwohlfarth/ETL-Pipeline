=pod

=head1 NAME

Data::ETL::Extract::AsHash - Role for storing input data as a hash

=head1 SYNOPSIS

  use Moose;
  with 'Data::ETL::Extract';
  with 'Data::ETL::Extract::AsHash';

  ...

=head1 DESCRIPTION

ETL stands for I<Extract>, I<Transform>, I<Load>. The ETL pattern executes
data conversions or uploads. It moves data from one system to another. The
ETL family of classes facilitate these data transfers using Perl.

This role provides attributes and methods for storing the input data in a hash
structure. This covers 90% of the use cases while allowing
L<Data::ETL::Extract> to remain flexible enough for the remaining 10%.

=cut

package Data::ETL::Extract::AsHash;
use Moose::Role;

use 5.14.0;
use List::AllUtils qw/first/;
use Regexp::Common;
use String::Util qw/hascontent/;


our $VERSION = '1.00';


=head1 METHODS & ATTRIBUTES

=head2 Automatically called from L<Data::ETL/run>

=head3 get

Return the value of a field from the current record. It accepts a field name
or regular expression as the only parameter.

If you pass in a field name, the code returns the data from that field. If you
pass in a regular expression, the code looks for the column whose header text
matches that expression.

This means that your L<Data::ETL/transform_as> commands can use regular
expressions on the right hand side (as input fields). And the file based input
source automatically finds the correct data column. You do not have to
manually map the regular expressions with field names.

Why not use the column headers as field names? It's quite likely that the
header names change between files. I<My ID> becomes I<MyID>, then I<MyId>,
followed next time by I<My Identifier>. Regular expressions provide a robust
matching language that handles these variants.

L</get> code finds the first column that matches the regular expression. You
should make sure that each regular expression matches only one column.

=cut

sub get {
	my $self  = shift;
	my $field = shift;

	$field = $self->name_for( $field );
	return (defined( $field ) ? $self->record->{$field} : undef);
}


=head3 set_field_names

This method processes the field names. It saves these names into the
L</headers> hash for later reference. The L<Data::ETL::Extract> role requires
this method.

=cut

sub set_field_names {
	my $self = shift;

	while (my ($field, $text) = each %{$self->record}) {
		$self->alias  ->{$text} = $field;
		$self->headers->{$text} = $field;
	}
}


=head2 Used by the implementing class

=head3 record

This hash holds the record loaded from the input source.

=cut

has 'record' => (
	default => sub { {} },
	is      => 'rw',
	isa     => 'HashRef[Maybe[Str]]',
);


=head3 alias

This hash maps an alias name with the underlying field name. If the L</get>
method finds a field name in this hash, it returns the value from the
corresponding column.

One column can have more than one name - or none at all.

=cut

has 'alias' => (
	default => sub { {} },
	is      => 'ro',
	isa     => 'HashRef[Str]',
);


=head3 headers

The L</get> method accepts regular expressions instead of field names. It then
searches for the column whose header text matches the expression. This hash
stores the header text to search later in L</get>.

=cut

has 'headers' => (
	default => sub { {} },
	is      => 'ro',
	isa     => 'HashRef[Str]',
);


=head3

This method returns the name of the field whose header matches a regular
expression. L</get> retrieves the field name using this method. The code returns
C<undef> if no field headers match.

L</name_for> accepts one parameter which can be either a regular expression or
a plain string. A regular expression is matched against the column headers. A
plain string is returned as the field name. 

The code does not check if the current record has a field by this name.

=cut

sub name_for {
	my ($self, $field) = @_;

	if (ref( $field ) eq 'Regexp') {
		if (exists $self->alias->{$field}) {
			# Matched before, so don't bother looking again.
			return $self->alias->{$field};
		} else {
			# Find the first header that matches.
			my $text = first { m/$field/ } keys %{$self->headers};
			if (defined $text) {
				# Save the results for faster lookup next time.
				$self->alias->{$field} = $self->headers->{$text};
				return $self->alias->{$field};
			} else { return undef; }
		}
	} elsif (exists $self->alias->{$field}) {
		# Aliased column name (like the column letter in MS Excel).
		return $self->alias->{$field};
	} else { return $field; }
}


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
