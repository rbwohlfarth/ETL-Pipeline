=pod

=head1 NAME

ETL::Pipeline::Input::File - Role for file based input sources

=head1 SYNOPSIS

  # In the input source...
  use Moose;
  with 'ETL::Pipeline::Input';
  with 'ETL::Pipeline::Input::File';
  ...

  # In the ETL::Pipeline script...
  ETL::Pipeline->new( {
    work_in   => {search => 'C:\Data', find => qr/Ficticious/},
    input     => ['Excel', iname => qr/\.xlsx?$/             ],
    mapping   => {Name => 'A', Address => 'B', ID => 'C'     },
    constants => {Type => 1, Information => 'Demographic'    },
    output    => ['SQL', table => 'NewData'                  ],
  } )->process;

  # Or with a specific file...
  ETL::Pipeline->new( {
    work_in   => {search => 'C:\Data', find => qr/Ficticious/},
    input     => ['Excel', iname => 'ExportedData.xlsx'      ],
    mapping   => {Name => 'A', Address => 'B', ID => 'C'     },
    constants => {Type => 1, Information => 'Demographic'    },
    output    => ['SQL', table => 'NewData'                  ],
  } )->process;

=head1 DESCRIPTION

This role adds functionality and attributes common to all file based input
sources. It is a quick and easy way to create new sources with the ability
to search directories. Useful when the file name changes.

B<ETL::Pipeline::Input::File> works with a single source file. To process an
entire directory of files, use L<ETL::Pipeline::Input::FileListing> instead.

=cut

package ETL::Pipeline::Input::File;

use 5.014000;

use Carp;
use Moose::Role;
use MooseX::Types::Path::Class qw/Dir File/;
use Path::Class::Rule;


our $VERSION = '3.00';


=head1 METHODS & ATTRIBUTES

=head2 Arguments for L<ETL::Pipeline/input>

B<ETL::Pipeline::Input::File> accepts any of the tests provided by
L<Path::Iterator::Rule>. The value of the argument is passed directly into the
test. For boolean tests (e.g. readable, exists, etc.), pass an C<undef> value.

B<ETL::Pipeline::Input::File> automatically applies the C<file> filter. Do not
pass C<file> through L<ETL::Pipeline/input>.

C<iname> is the most common one that I use. It matches the file name, supports
wildcards and regular expressions, and is case insensitive.

  # Search using a regular expression...
  $etl->input( 'Excel', iname => qr/\.xlsx$/ );

  # Search using a file glob...
  $etl->input( 'Excel', iname => '*.xlsx' );

B<Warning:> Your input source must account for the case where no file matches
the search criteria. I thought about throwing a fatal error. But I'd rather the
ETL script make that decision.

=cut

sub BUILD {
	my $self = shift;
	my $arguments = shift;

	# Filter out attributes for this class. They are not file search criteria.
	# Except for "file", which is search criteria and an attribute. From here,
	# we treat it as criteria. The "file" attribute is set internally.
	my @criteria = grep {
		$_ ne 'file'
		&& !$self->meta->has_attribute( $_ )
	} keys %$arguments;

	# Configure the file search.
	my $rule = Path::Class::Rule->new;
	$rule->file;
	foreach my $name (@criteria) {
		my $value = $arguments->{$name};
		eval "\$rule->$name( \$value )";
		confess $@ unless $@ eq '';
	}

	# Find the first file that matches all of the criteria.
	my $custom   = $self->matching;
	my $iterator = $rule->iter( $self->data_in );
	my $result   = 0;

	while ($result == 0) {
		my $potential = $iterator->();
		if (defined $potential) {
			if (defined $custom) {
				$result = $custom->( $potential );
			} else {
				$result = 1;
			}
		} else {
			$result = -1;
		}
	}

	if (!defined( $potential )) {
		carp 'No files matched the search criteria';
	} elsif (!-r $potential) {
		carp "You do not have permission to read '$potential'";
	} else {
		$self->_set_file( $potential );
	}
}


=head3 data_in

Path where data files reside. L<ETL::Pipeline> sets this value to
L<ETL::Pipeline/data_in> when it instantiates the input source.

=cut

has 'data_in' => (
	coerce => 1,
	is     => 'ro',
	isa    => Dir,
);


=head3 file

When passed to L<ETL::Pipeline/input>, this file becomes the input source. No
search or matching is performed. If you specify a relative path, it is relative
to L</data_in>.

Once the object has been created, this attribute holds the file that matched
search criteria. It should be used by your input source class as the file name.

  # File inside of "data_in"...
  $etl->input( 'Excel', file => 'Data.xlsx' );

  # Absolute path name...
  $etl->input( 'Excel', file => 'C:\Data.xlsx' );

  # Inside the input source class...
  open my $io, '<', $self->file;

=cut

has 'file' => (
	coerce => 1,
	is     => 'ro',
	isa    => File,
	writer => '_set_file',
);


=head3 matching

B<matching> executes custom code to evaluate possible input files. This code can
apply any logic, including reading the file contents. It returns B<true> if the
file is a valid input source. B<False> skips that file and moves on to the next
one. The first match becomes the file for this input source.

B<matching> is a code reference. It receives one parameter - a
L<Path::Class::File> object.

  # File larger than 2K...
  $etl->input( 'Excel', matching => sub {
    my ($file) = @_;
    return ($file->size > 2048 ? 1 : 0);
  } );

=cut

has 'matching' => (
	is  => 'ro',
	isa => 'Maybe[CodeRef]',
);


=head3 skipping

B<skipping> jumps over a certain number of rows/lines in the beginning of the
file. Report formats often contain extra headers - even before the column
names. B<skipping> ignores those and starts processing at the data.

B<Note:> B<skipping> is applied I<before> reading column names.

B<skipping> accepts either an integer or code reference. An integer represents
the number of rows/records to ignore. For a code reference, the code discards
records until the subroutine returns a I<true> value.

  # Bypass the first three rows.
  $etl->input( 'Excel', skipping => 3 );

  # Bypass until we find something in column 'C'.
  $etl->input( 'Excel', skipping => sub { hascontent( $_->get( 'C' ) ) } );

The exact nature of the I<record> depends on the input file. For example files,
Excel files will send a data row as a hash. But a CSV file would send a single
line of plain text with no parsing. See the input source to find out exactly
what it sends.

=cut

has 'skipping' => (
	default => 0,
	is      => 'ro',
	isa     => 'CodeRef|Int',
);


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Input>, L<ETL::Pipeline::Input::FileList>

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
