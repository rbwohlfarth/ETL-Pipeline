=pod

=head1 NAME

ETL::Pipeline::Input::File - Role for file based input sources

=head1 SYNOPSIS

  # In the input source...
  use Moose;
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

B<ETL::Pipeline::Input::File> provides methods and attributes common to
file based input sources. It makes file searches available for any file
format using L<Path::Class::Rule>.

=head2 Multiple files

In the simplest case, each L<ETL::Pipeline/input> reads one file. Life isn't
always simple. We can have data in the same format but spread across more than
one file. For example, XML with one record per file.
B<ETL::Pipeline::Input::File> allows for this by iterating over a set of files.

B<ETL::Pipeline::Input::File> reads each file until it reaches the end. It
then transparently moves on to the next file. B<ETL::Pipeline::Input::File>
signals EOF after it finishes the last file in the set.

When you implement your input source class, write the
L<ETL::Pipeline::Input/configure> and L<ETL::Pipeline::Input/finish> methods to
work on one single file. B<ETL::Pipeline::Input::File> calls those methods for
each file as it iterates through the set. The L</file> attribute holds the
current file as a L<Path::Class::File> object.

=cut

package ETL::Pipeline::Input::File;
use Moose::Role;

use 5.014000;
use Carp;
use MooseX::Types::Path::Class qw/Dir File/;
use Path::Class::Rule;


our $VERSION = '2.03';


=head1 METHODS & ATTRIBUTES

=head2 Arguments for L<ETL::Pipeline/input>

B<ETL::Pipeline::Input::File> accepts any of the tests provided by
L<Path::Iterator::Rule>. The value of the argument is passed directly into the
test. For boolean tests (e.g. readable, exists, etc.), pass an C<undef> value.

B<ETL::Pipeline::Input::Files> automatically applies the C<file> filter. Do not
pass C<file> through L<ETL::Pipeline/input>.

C<iname> is the most common one that I use. It matches the file name, supports
wildcards and regular expressions, and is case insensitive.

  # Search using a regular expression...
  $etl->input( 'Excel', iname => qr/\.xlsx$/ );

  # Search using a file glob...
  $etl->input( 'Excel', iname => '*.xlsx' );

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

	# Save the file iterator for "next_record".
	$self->_iterator( $rule->iter( $self->pipeline->data_in ) );
}


=head3 matching

B<matching> executes custom code to evaluate each input file. This code can
apply any logic, including reading the file contents. It returns B<true> if
the file is a valid input source. B<False> skips that file and moves on to the
next one.

B<matching> is a code reference. It passes two parameters into the subroutine...

=over

=item The L<ETL::Pipeline> object

=item The L<Path::Class::File> object

=back

  # File larger than 2K...
  $etl->input( 'Excel', matching => sub {
    my ($etl, $file) = @_;
    return ($file->size > 2048 ? 1 : 0);
  } );

=cut

has 'matching' => (
	is  => 'rw',
	isa => 'Maybe[CodeRef]',
);


=head3 on_new_file

An array reference of code references. L</next_record> executes every code
reference each time it starts a brand new file. These subroutines are called
before L<ETL::Pipeline::Input/configure>. The subroutines receive the current
pipeline object as its one and only parameter. You can access the new file name
through L</file> like this...

  ETL::Pipeline->new( {
	...
	on_new_file => [sub { print shift->input->file->stringify }],
	...
  } )->process;

Why an array reference? Output destinations and scripts may both want a
callback for each new file. An array can call different subroutines added for
different reasons. A single value would cause one to wipe out the other.

If you call the B<on_new_file> method, pass the code reference as a list, not
an array reference. The mthod B<adds> these to the existing callbacks. There
is no mechanism to remove or overwrite existing callbacks.

  $etl->on_new_file( sub { print "Me too!" } );

=cut

has '_new_file_callback' => (
	default  => sub { return [] },
	handles  => {
		_new_file_callback_list => 'elements',
		on_new_file             => 'push',
	},
	init_arg => 'on_new_file',
	is       => 'ro',
	isa      => 'ArrayRef[CodeRef]',
	traits   => [qw/Array/],
);


=head2 Called from L<ETL::Pipeline/process>

=head3 next_record

File input sources can match more than one file. B<ETL::Pipeline::Input::File>
automatically cycles through all L</matching> files. This saves you from coding
the loop yourself.

It does this magic by trapping EOF from B<get> and returning the next file
instead. When it reaches the end of the file list, it returns false, for EOF.

=cut

around 'next_record' => sub {
	my ($original, $self, @arguments) = @_;

	my $have_file = 1;
	my $success   = $original->( $self, @arguments );

	while (!$success && $have_file) {
		my $file = $self->_next_file_match;
		if (defined $file) {
			$self->finish;
			$self->_set_file( $file );
			$self->configure;
			$success = $original->( $self, @arguments );
		} else { $have_file = 0; }
	}

	return $have_file;
};


=head2 Other Methods & Attributes

=head3 file

B<file> holds a L<Path::Class::File> object pointing to the input file.
If L<ETL::Pipeline/input> does not set B<file>, then the L</matching>
attribute searches the file system for a match. If
L<ETL::Pipeline/input> sets B<file>, then L</matching> is ignored.

B<file> is relative to L<ETL::Pipeline/data_in>, unless you set it to an
absolute path name. With L</matching>, the search is always limited to
L<ETL::Pipeline/data_in>.

  # File inside of "data_in"...
  $etl->input( 'Excel', file => 'Data.xlsx' );

  # Absolute path name...
  $etl->input( 'Excel', file => 'C:\Data.xlsx' );

=cut

has 'file' => (
	builder => '_build_file',
	coerce  => 1,
	is      => 'ro',
	isa     => File,
	lazy    => 1,
	trigger => \&_trigger_file,
	writer  => '_set_file',
);


sub _build_file {
	my $self = shift;

	my $file = $self->_next_file_match;
	croak 'No file matched for "input"' unless defined $file;
	return $file;
}


sub _trigger_file {
	my ($self, $old, $new) = @_;

	# The object should already be an absolute path. Path::Iterator::Rule
	# uses absolute paths if the search directroies are absolute. And in this
	# case they are ("work_in" and "data_in").

	# Execute the callbacks when the file changes. This allows us to perform
	# actions based on file paths - like adding database records.
	$self->pipeline->execute_code_ref( $_ )
		foreach ($self->_new_file_callback_list);
}


#-------------------------------------------------------------------------------
# Private attributes and methods...

# "Path::Class::Rule" creates an iterator that returns each file in turn. This
# attribute holds it.
has '_iterator' => (
	handles => {_next_file => 'execute'},
	is      => 'rw',
	isa     => 'CodeRef',
	traits  => [qw/Code/],
);


# Executes the Path::Class::Rule iterator. It sets up a loop if we're using
# custom code to evaluate files. I had this same code in two places. This
# method let me keep it all in one place.
sub _next_file_match {
	my $self = shift;

	my $pattern  = $self->matching;
	my $pipeline = $self->pipeline;

	if (defined $pattern) {
		while (my $file = $self->_next_file) {
			return $file if $pipeline->execute_code_ref( $pattern, $file );
		}
		return undef;
	} else {
		return $self->_next_file;
	}
}


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Input>, L<ETL::Pipeline::Input::TabularFile>

=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vumc.org>

=head1 LICENSE

Copyright 2019 (c) Vanderbilt University Medical Center

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;

# Required by Perl to load the module.
1;
