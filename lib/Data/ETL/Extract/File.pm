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

use 5.14.0;
use File::Find::Rule;


our $VERSION = '1.00';


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
		$search->name( $self->find_file ) if defined $self->find_file;
		$self->path( shift [$search->in( $Data::ETL::WorkingFolder )] );
	}

	die "'extract_from' could not find a matching file" 
		unless defined $self->path;
};


=head1 METHODS & ATTRIBUTES

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

This attribute also holds a regular expression. The search finds the first
file that matches it.

=cut

has 'find_file' => (
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
