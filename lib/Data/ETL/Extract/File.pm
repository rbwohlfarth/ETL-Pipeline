=pod

=head1 NAME

Data::ETL::Extract::File - Role for file based input sources

=head1 SYNOPSIS

  use Moose;
  with 'Data::ETL::Extract';
  with 'Data::ETL::Extract::File';

  ...

=head1 DESCRIPTION

ETL stands for I<Extract>, I<Transform>, I<Load>. The ETL pattern executes
data conversions or uploads. It moves data from one system to another. The
ETL family of classes facilitate these data transfers using Perl.

This role provides attributes for loading files. Basically, this role gives
your input source attributes to identify the input file. It provides a nice,
standard interface for your ETL scripts.

=cut

package Data::ETL::Extract::File;
use Moose::Role;

use File::Find::Rule;
use Regexp::Common;
use String::Util qw/hascontent/;


=head2 Identifying the input file

B<Data::ETL::Extract::File> offers two ways to identify the specific input
file:

=over

=item 1. Specify the exact path to the file.

=item 2. Search the file system for a file whose name matches a given pattern.

=back

Option 1 is the most basic. You specify a full path name to the file using the
L</path> attribute. If you set L</path>, B<Data::ETL::Extract::File> ignores
the search attributes.

Option 2 is useful when you drop the files in the same location, but the exact
file name changes from time to time. B<Data::ETL::Extract::File> searches the
file system looking for the first file that matches a regular expression.
Using the attributes, you can narrow down the search to a particular
subdirectory.

=cut

before 'setup' => sub {
	my $self = shift;

	unless (defined $self->path) {
		if (defined $self->folder_name) {
			foreach my $folder (File::Find::Rule
				->directory
				->name( $self->folder_name )
				->in( $self->root )
			) {
				$self->_find_file( $folder );
				last if defined $self->path;
			}
		} else {
			$self->_find_file( $self->root );
		}
	}

	die "Could not find a matching file" unless defined $self->path;
};

sub _find_file {
	my ($self, $root) = @_;

	my $search = File::Find::Rule->new;
	$search->file;
	$search->name( $self->file_name ) if defined $self->file_name;

	my @files = $search->in( $root );
	$self->path( shift @files );
}


=head1 METHODS & ATTRIBUTES

=head3 path

The full path name of the input file. B<Data::ETL::Extract::File> has two ways
of loading files. First, you can specify the exact file by setting this
attribute in the constructor. The second way is to search the file system. If
you set this attribute, then no search happens.

=cut

has 'path' => (
	is  => 'rw',
	isa => 'Str',
);


=head3 root

When searching for an input file, start in this directory. It defaults to the
current directory.

=cut

has 'root' => (
	default => '.',
	is      => 'rw',
	isa     => 'Str',
);


=head3 folder_name

This attribute holds a regular expression. The search first looks for a
directory that matches, then it looks for the file inside of that directory.

=cut

has 'folder_name' => (
	is  => 'rw',
	isa => 'Maybe[RegexpRef]',
);


=head3 file_name

This attribute also holds a regular expression. The search finds the first
file that matches it.

=cut

has 'file_name' => (
	is  => 'rw',
	isa => 'Maybe[RegexpRef]',
);


=head3 headers

File formats often include a header row. Some places are good about putting
the data in the same order. Others move it around every so often. Headers
allow you to find the data regardless of the actual order of fields.

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

=cut

has 'headers' => (
	is  => 'rw',
	isa => 'HashRef[Str]',
);

after 'setup' => sub {
	my $self = shift;

	# Skip rows in front of the headers. This MUST happen first.
	$self->record_number_add( $self->skip );

	# Process the header row, but only if we're expecting headers. Most often
	# the data begins in the first row. I don't want to miss the first record.
	if (defined( $self->headers ) and $self->next_record) {
		# Copy the headers so that I can remove them as I match them.
		my %headers = %{$self->headers};

		while (my ($field, $text) = each %{$self->record}) {
			if (hascontent( $text )) {
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
}


=head3 skip

The number of rows to skip before the headers or data. Some reporting software
adds page headers. This setting jumps over those rows.

The attribute defaults to zero (do not skip rows). If your column headers
are in the first row, then you want this set to zero.

=cut

has 'skip' => (
	default => 0,
	is      => 'rw',
	isa     => 'Int',
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
