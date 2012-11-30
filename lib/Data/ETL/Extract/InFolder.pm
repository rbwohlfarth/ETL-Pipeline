=pod

=head1 NAME

Data::ETL::Extract::InFolder - Role for file system based input sources

=head1 SYNOPSIS

  use Moose;
  with 'Data::ETL::Extract';
  with 'Data::ETL::Extract::InFolder';

  ...

=head1 DESCRIPTION

ETL stands for I<Extract>, I<Transform>, I<Load>. The ETL pattern executes
data conversions or uploads. It moves data from one system to another. The
ETL family of classes facilitate these data transfers using Perl.

This role provides attributes for locating information in the file system. It
can be used with files or directory listings. The role establishes a root 
folder for further searches.

=cut

package Data::ETL::Extract::InFolder;
use Moose::Role;

use 5.14.0;
use File::Find::Rule;


our $VERSION = '1.00';


=head2 Identifying the root folder

B<Data::ETL::Extract::InFolder> offers two ways to identify the root folder:

=over

=item 1. Specify the exact path.

=item 2. Search the file system for a folder whose name matches a pattern.

=back

Option 1 is the most basic. You specify a full path name to the folder using
the L</root_folder> attribute. If you set L</root_folder>, 
B<Data::ETL::Extract::InFolder> ignores the search attributes.

Option 2 is useful when you drop data at the same location, but the exact
folder name changes from time to time. B<Data::ETL::Extract::InFolder> searches
the file system looking for the first folder that matches a regular expression.

=cut

before 'setup' => sub {
	my $self = shift;

	unless (defined $self->root_folder) {
		if (defined $self->find_folder) {
			$self->root_folder( shift [
				File::Find::Rule
				->directory
				->maxdepth( 1 )
				->name( $self->find_folder )
				->in( $self->search_in )
			] );
		} else { $self->root_folder( $self->search_in ); }
	}

	die "Could not find a root folder" unless defined $self->root_folder;
};


=head1 METHODS & ATTRIBUTES

=head2 Set with the L<Data::ETL/extract_from> command

=head3 root_folder

The full path name of the top folder. B<Data::ETL::Extract::InFolder> has two 
ways of locating folders. First, you can specify the exact folder by setting 
this attribute in the constructor. The second way is to search the file system.
If you set this attribute, then no search happens.

=cut

has 'root_folder' => (
	is  => 'rw',
	isa => 'Str',
);


=head3 search_in

When searching for the root folder, only search inside this folder. The code
does not search subdirectories. Data directories can be quite large. And a
fully recursive search could take a very long time.

B<search_in> defaults to the current directory.

=cut

has 'search_in' => (
	default => '.',
	is      => 'rw',
	isa     => 'Str',
);


=head3 find_folder

This attribute holds a regular expression. The search looks for a folder that 
matches. If you leave it blank, then it uses L</search_in> as the root.

=cut

has 'find_folder' => (
	is  => 'rw',
	isa => 'Maybe[RegexpRef]',
);


=head1 SEE ALSO

L<Data::ETL>, L<Data::ETL::Extract>, L<Data::ETL::Extract::File>

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
