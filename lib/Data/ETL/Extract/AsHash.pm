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
use Regexp::Common;
use String::Util qw/hascontent/;


our $VERSION = '1.00';


=head1 METHODS & ATTRIBUTES

=head2 Set with the L<Data::ETL/extract_using> command

=head3 headers

Files often include a header row. Some places are good about putting the data 
in the same order. Others move it around every so often. Headers allow you to 
find the data regardless of the actual order of fields.

This hash matches field headers with standardized field names. Headers are
always the first record - just before the data. The I<transform> process
can access the data using known field names instead of the column numbers.

It's also possible that the header names change between files. I<My ID> becomes
I<MyID>, then I<MyId>, followed next time by I<My Identifier>. So C<headers>
expects regular expressions as keys. The L</setup> code finds the first regular
expression that matches a column header. When L</next_record> reads the data,
it uses the corresponding value as the field name. This way, when the column
header changes slightly, your code still gets the right data.

You should make sure that each regular expression matches only one column.

Why is this here and not L<Data::ETL::Extract::File>? Because using headers as
column names requires having a hash as the storage structure. And it doesn't
really depend on having a file as the input source.

=cut

has 'headers' => (
	is  => 'rw',
	isa => 'HashRef[Str]',
);

after 'setup' => sub {
	my $self = shift;

	if (defined( $self->headers ) and $self->next_record) {
		# Copy the headers so that I can remove them as I match them.
		my %headers = %{$self->headers};

		while (my ($field, $text) = each %{$self->record}) {
			# Only map field numbers. The mapping uses a list, with the field
			# number as an index. Strings just generate Perl warnings.
			if ($RE{num}{int}->matches( $field ) and hascontent( $text )) {
				# I used "foreach" to break out of the loop early. "each"
				# remembers its position and would start the next loop skipping
				# over some of the patterns.
				foreach my $pattern (keys %headers) {
					if ($text =~ m/$pattern/) {
						$self->add_name( $headers{$pattern}, $field );
						delete $headers{$pattern};
						last;
					}
				}

				# Quit looking when we run out of field names.
				last unless scalar( %headers );
			}
		}
	}
};


=head2 Automatically called from L<Data::ETL/run>

=head3 get

Return the value of a field from the current record. The only parameter is a
field name.

=cut

sub get { $_[0]->record->{$_[1]}; }


=head2 Used by the implementing class

=head3 record

This hash holds the record loaded from the input source.

=cut

has 'record' => (
	default => sub { {} },
	is      => 'rw',
	isa     => 'HashRef[Maybe[Str]]',
);


=head3 names

This list maps field numbers to names. When reading a record, the code uses the
name as a key for L<Data::ETL::Extract/record>. The I<transform> phase then
works with the field names instead of unwieldy numbers.

Each column can have more than one name.

=cut

has 'names' => (
	default => sub { [] },
	is      => 'ro',
	isa     => 'ArrayRef[ArrayRef[Str]]',
);

after 'next_record' => sub {
	my $self = shift;

	if (scalar @{$self->names}) {
		# Build a local hash so that I don't affect the loops by adding fields.
		my %add;
		while (my ($field, $value) = each %{$self->record}) {
			if ($RE{num}{int}->matches( $field )) {
				my $names = $self->names->[$field];
				if (defined $names) { $add{$_} = $value foreach (@$names); }
			}
		}

		# Merge the named fields in with the rest.
		@{$self->record}{keys %add} = values %add;
	}
};


=head3 add_name

This method adds a name for a given field. This convenience method centralizes
the logic for handling names.

It accepts two parameters: the field name and the field number. It assigns the
name to the number.

This method maintains both the L</names> and L</numbers> attributes.

=cut

sub add_name {
	my ($self, $name, $index) = @_;
	my $list = $self->names->[$index];

	# Add a new list reference if we don't have a name for this field yet.
	unless (defined $list) {
		$list = [];
		$self->names->[$index] = $list;
	}

	push @$list, $name;
	
	# Maintain the cross reference of field names to numbers. My helper
	# functions need this to accept field names or numbers and still work. I
	# add the numbers too so that everything just works. I don't need any 
	# special logic to see if it's a field number or name.
	$self->numbers->{$index} = $index;
	$self->numbers->{$name } = $index;
}


=head3 numbers

This hash converts a field name into the corresponding field number. This
allows my helper functions to accept field names or numbers. L</add_name>
automatically maintains this hash.

=cut

has 'numbers' => (
	default => sub{ {} },
	is      => 'ro',
	isa     => 'HashRef[Int]',
);


=head1 SEE ALSO

L<Data::ETL>, L<Data::ETL::Extract>

=head1 AUTHOR

Robert Wohlfarth <rbwohlfarth@gmail.com>

=head1 LICENSE

Copyright 2012  Robert Wohlfarth

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;

# Required by Perl to load the module.
1;
