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

=head2 Set with the L<Data::ETL/extract_using> command

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
