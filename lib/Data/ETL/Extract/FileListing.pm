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

use File::Find::Rule;
use File::Spec::Functions qw/catdir catpath splitpath/;


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
the L<Data::ETL/working_folder>.

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

	if ($self->no_matches) {
		return 0;
	} else {
		my $path = $self->next_match;
		my (undef, $directory, $file) = splitpath( $path );
		
		my %record;
		$record{Extension} = pop [split /\./, $file];
		$record{File     } = $file;
		$record{Folder   } = catdir( $self->path, $directory );
		$record{Inside   } = $directory;
		$record{Path     } = catdir( $self->path, $path );
		$record{Relative } = $path;
		
		$self->record( \%record );
		return 1;
	}
}


=head3 setup

This method configures the input source. In this object, that means opening
the file and looking for a header record. If the file has a header row, then
I name the fields based on the header row. You can identify data by the
field name or by the column name. See L<Data::ETL::Extract::AsHash/headers> 
for more information.

=cut

sub setup {
	my ($self) = @_;

	unless (defined $self->path) {
		if (defined $self->files_in) {
			$self->path( shift [File::Find::Rule
				->directory()
				->name( $self->files_in )
				->in( $Data::ETL::WorkingFolder )
			] );
		} else { $self->path( $Data::ETL::WorkingFolder ); }
	}

	die "Could not find a matching folder" unless defined $self->path;
	
	my $rule = File::Find::Rule->file()->relative();
	$rule->name( $self->find_file ) if defined $self->find_file;
	$rule->mindepth( $self->min_depth ) if defined $self->min_depth;
	$rule->maxdepth( $self->max_depth ) if defined $self->max_depth;
	$self->add_matches( $rule->in( $self->path ) );
}


=head3 finished

This method shuts down the input source. In our case, it does nothing.

=cut

sub finished { }


=head2 Internal Attributes and Methods

You should never use these items. They can change at any moment. I documented
them for the module maintainers.

=head3 matches

The list of files underneath the specified folder. 
B<Data::ETL::Extract::FileListing> returns them one at a time.

=cut

has 'matches' => (
	default => sub { [] },
	handles => {
		add_matches => 'push',
		next_match  => 'shift',
		no_matches  => 'is_empty',
	},
	is      => 'ro',
	isa     => 'ArrayRef',
	traits  => [qw/Array/],
);


=head1 SEE ALSO

L<Data::ETL>, L<Data::ETL::Extract>, L<Data::ETL::Extract::AsHash>

=cut

with 'Data::ETL::Extract::AsHash';
with 'Data::ETL::Extract';


=head1 AUTHOR

Robert Wohlfarth <rbwohlfarth@gmail.com>

=head1 LICENSE

Copyright 2012  Robert Wohlfarth

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
