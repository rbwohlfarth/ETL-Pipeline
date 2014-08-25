=pod

=head1 NAME

Data::ETL::Extract::FileListing - Process a list of files as an input source

=head1 SYNOPSIS

  use ETL;
  working_folder search_in => 'C:\Data', find_folder => qr/Client_/;
  extract_from 'FileListing', find_file => qr/\.pdf/i, files_in => qr/files/;
  transform FileName => 'File', FullPath => 'Path';
  load_into 'Access';
  run;

=head1 DESCRIPTION

B<ETL> stands for I<Extract-Transform-Load>. You often hear this design
pattern associated with Data Warehousing. In fact, ETL works with almost
any type of data conversion. You read the source (I<Extract>), translate the
data for your target (I<Transform>), and store the result (I<Load>).

This class defines an ETL input source that for directory contents. It
recursively returns the files underneath a specific directory, one at a time.
I use it for attaching external files to database records.

You use this class by naming it in the L<Data::ETL/extract_from> call. You
would not normally use it directly.

=cut

package Data::ETL::Extract::FileListing;
use Moose;

use 5.14.0;
use Path::Class::Rule;
use String::Util qw/hascontent/;


our $VERSION = '1.00';


=head1 METHODS & ATTRIBUTES

=head2 Set with the L<Data::ETL/extract_from> command

=head3 files_in

If the files come bundled with other data, they often have their own subfolder.
This regular expression tells B<Data::ETL::Extract::FileListing> to only list
files in the first matching subfolder.

=cut

has 'files_in' => (
	is  => 'rw',
	isa => 'Maybe[RegexpRef]',
);


=head3 find_file

Filter the file list using this regular expression. By default,
B<Data::ETL::Extract::FileListing> returns every file in the folder.

=cut

has 'find_file' => (
	is  => 'rw',
	isa => 'Maybe[RegexpRef]',
);


=head3 path

The full path name of the directory to list. Setting this attribute bypasses
the L<Data::ETL/source_folder>.

=cut

has 'path' => (
	is  => 'rw',
	isa => 'Str',
);


=head3 min_depth

Only return files at least this level deep underneath L</path>. The default is
to return all files under L</path>, regardless of their depth. A value of B<2>
only returns files inside of a subdirectory.

=cut

has 'min_depth' => (
	is  => 'rw',
	isa => 'Maybe[Int]',
);


=head3 max_depth

Only return files this level or higher, underneath L</path>. The default is
to return all files under L</path>, regardless of their depth. A value of B<1>
only returns files in L</path>.

=cut

has 'max_depth' => (
	is  => 'rw',
	isa => 'Maybe[Int]',
);


=head2 Automatically called from L<Data::ETL/run>

=head3 next_record

Read one record from the file and populate L<Data::ETL::Extract/record>. The
method returns the number of records loaded. A B<0> means that we reached the
end of the file.

L</next_record> returns these fields:

=over

=item Extension

The file extension, without a leading period.

=item File

The file name with the extension. No directory information.

=item Folder

The full directory where this file resides.

=item Inside

The relative directory name where this file resides. These are the directories
below L</path> where the file resides. You can use this to re-create the
directory structure.

=item Path

The complete path name of the file (directory, name, and extension). You can
use this to access the file contents.

=item Relative

The relative path name of the file. This is the part that comes after the
L</path>.

=back

=cut

sub next_record {
	my ($self) = @_;

	my $path = $self->iterator->();
	if (defined $path) {
		$self->record( {
			Extension => pop [split /\./, $path->basename],
			File      => $path->basename,
			Folder    => $path->dir->absolute( $self->path )->stringify,
			Inside    => $path->dir->stringify,
			Path      => $path->absolute( $self->path )->stringify,
			Relative  => "$path",
		} );
		return 1;
	} else { return 0; }
}


=head3 setup

This method configures the input source. In this object, that means creating
the iterator. L</next_record> then loops through that selecting each file. The
iterator rules are created based on the attributes from
L<Data::ETL/extract_from>.

=cut

sub setup {
	my ($self) = @_;

	# Search for the directory that has the attachments.
	unless (defined $self->path) {
		if (defined $self->files_in) {
			my $result = Path::Class::Rule->new
				->directory()
				->name( $self->files_in )
				->iter( $Data::ETL::SourceFolder )
				->()
			;
			$self->path( "$result" ) if defined $result;
		} else { $self->path( $Data::ETL::SourceFolder ); }
	}

	die "Could not find a matching folder" unless defined $self->path;

	# Create the filter and iterator for listing files.
	my $rule = Path::Class::Rule->new->file();
	$rule->name( $self->find_file ) if defined $self->find_file;
	$rule->min_depth( $self->min_depth ) if defined $self->min_depth;
	$rule->max_depth( $self->max_depth ) if defined $self->max_depth;

	$self->_set_iterator( $rule->iter( $self->path, {relative => 1} ) );
}


=head3 finished

This method shuts down the input source. In our case, it does nothing.

=cut

sub finished { }


=head2 Internal Attributes and Methods

You should never use these items. They can change at any moment. I documented
them for the module maintainers.

=head3 iterator

L<Path::Class::Rule> creates an iterator for walking over the directory
structure. This attribute holds the iterator reference for L</next_record>. It
is automatically set by L</setup>.

=cut

has 'iterator' => (
	is     => 'ro',
	isa    => 'CodeRef',
	writer => '_set_iterator',
);


=head3 rule

This attribute holds the L<Path::Class::Rule> used in L</setup>.

=cut

has 'rule' => (
	default => sub { Path::Class::Rule->new },
	is      => 'ro',
	isa     => 'Path::Class::Rule',
);


=head1 SEE ALSO

L<Data::ETL>, L<Data::ETL::Extract>, L<Data::ETL::Extract::AsHash>

=cut

with 'Data::ETL::Extract::AsHash';
with 'Data::ETL::Extract';


=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=head1 LICENSE

Copyright 2013 (c) Vanderbilt University

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
