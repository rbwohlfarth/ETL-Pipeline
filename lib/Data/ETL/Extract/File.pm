=pod

=head1 NAME

Data::ETL::Extract::File - Role for file based input sources

=head1 SYNOPSIS

  use Moose;
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


use 5.14.0;
use Data::ETL::CodeRef;
use File::Find::Rule;
use List::AllUtils qw/first/;


our $VERSION = '1.00';


# This must come before the "around 'next_record' call. Otherwise the record
# counter will be off and you will lose data records. This role also has an
# "around 'next_record'". With the "use" command up here, that one executes
# first. It is wrapped by the one in this role. For cached records, I never
# call the inner "around" (from Data::ETL::Extract). And that keeps the counter
# synchronized with what we actually loaded.
with 'Data::ETL::Extract';


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
file or folder name changes. B<Data::ETL::Extract::File> searches
L<Data::ETL/WorkingFolder> for the first file that matches the regular
expression in the L</find_file> attribute.

=cut

before 'setup' => sub {
	my $self = shift;

	unless (defined $self->path) {
		my $search = File::Find::Rule->new;
		$search->file;

		my $pattern = $self->find_file;
		if (ref( $pattern ) eq 'CODE') {
			my $path = first { Data::ETL::CodeRef::run( $pattern, $_ ) }
				$search->in( $Data::ETL::WorkingFolder );
			$self->path( $path );
		} else {
			$search->name( $pattern ) if defined $pattern;
			$self->path( shift [$search->in( $Data::ETL::WorkingFolder )] );
		}
	}

	die "'extract_from' could not find a matching file"
		unless defined $self->path;
};


=head1 METHODS & ATTRIBUTES

B<Data::ETL::Extract::File> supports all of the methods and attributes in the
L<Data::ETL::Extract> role.

=head2 Set with the L<Data::ETL/extract_from> command

=head3 path

The full path name of the input file. B<Data::ETL::Extract::File> has two ways
of loading files. First, you can specify the exact file by setting this
attribute in the constructor. The second way is to search the file system. If
you set this attribute, then no search happens.

=cut

has 'path' => (
	is  => 'rw',
	isa => 'Maybe[Str]',
);


=head3 find_file

This attribute finds the first file that matches a pattern. The pattern is
normally a regular expression. The search finds the first file whose name
matches the regular expression.

For very weird cases, you may also use a code reference. The search runs this
code against the file names. It uses the first file where this code returns
B<true>. The search passes the file name to the code as C<$_>.

=cut

has 'find_file' => (
	is  => 'rw',
	isa => 'Maybe[CodeRef|RegexpRef]',
);


=head3 has_field_names

Files can include a row of field names. Some places are good about putting the
data in the same order. Others move it around every so often. Field names let
you find the data regardless of the actual order of fields.

A B<true> value means that the input contains field names. The data begins on
the first row after it.

A B<false> value means that the data starts right here in the first record.
There are no field names. This is the default.

This attribute triggers the call to L<Data::ETL::Extract/set_field_names>.

=cut

has 'has_field_names' => (
	default => 0,
	is      => 'rw',
	isa     => 'Bool',
);


=head3 report_header_until

Some files have report headers before the real data. This moves the column
names down. A lot of software exports data into Microsoft Excel spread sheets.
They will put the date, a report name, and selection criteria in the first 3
rows. B<Data::ETL::Extract::File> should ignore those rows and look for the
column names on row 4.

This option tells B<Data::ETL::Extract::File> how to identify and ignore the
report headers.

A scalar value is the number of rows in the report header.
B<Data::ETL::Extract::File> skips over this many rows. In the example above,
this would be B<3>. The column names start on the very next row.

A code reference gives you greater flexibility in the logic. The code returns a
true value when it finds the column names. At this point,
B<Data::ETL::Extract::File> stops looking for report headers. It processes the
data normally.

If the code returns a false value, then B<Data::ETL::Extract::File> treats the
row like a report header and ignores it.

=cut

has 'report_header_until' => (
	default => 0,
	is      => 'rw',
	isa     => 'CodeRef | Int',
);


# This block of code implements the "report_header_until" and
# "has_field_names" logic.
after 'setup' => sub {
	my $self = shift @_;

	# Ignore report headers. Always end with the column names in memory.
	my $headers = $self->report_header_until;
	if (ref( $headers ) eq 'CODE') {
		do { $self->next_record( 1 ); }
		until Data::ETL::CodeRef::run( $headers, $self );
	} else {
		$self->next_record( 1 ) foreach (1 .. $headers);
		$self->next_record;
	}

	# Process the field names. "next_record" starts with the first data row.
	if ($self->has_field_names) {
		$self->set_field_names;
		$self->_cached( 0 );
	} else { $self->_cached( 1 ); }
};


=head2 Internal Methods & Attributes

You should never use these items. They can change at any moment. I documented
them for the module maintainers.

=head3 _cached

This attribute indicates if the next record has been cached in memory. When
processing variable length report headers, I can't tell they end until I read
the next line. If the next line is where your data starts, then I can't just
throw it away. This attribute tells the code to process the current record in
memory instead of reading one from disk.

The code automatically adjusts the record count down, so that we don't count
this record twice.

=cut

has '_cached' => (
	default => 0,
	is      => 'rw',
	isa     => 'Bool',
);

around 'next_record' => sub {
	my ($original, $self, @arguments) = @_;

	if ($self->_cached) {
		$self->_cached( 0 );
		return 1;
	} else { return $original->( $self, @arguments ); }
};


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
