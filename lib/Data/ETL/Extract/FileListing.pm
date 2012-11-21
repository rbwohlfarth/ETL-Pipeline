=pod

=head1 NAME

Data::ETL::Extract::FileListing - Process a list of files as an input source

=head1 SYNOPSIS

  use ETL;
  extract_from 'FileListing', root => 'C:\Data', top_level => qr/Client_/;
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

=head3 name

Filter the file list using this regular expression. By default, 
B<Data::ETL::Extract::FileListing> returns every file in the folder.

=cut

has 'name' => (
	is  => 'rw',
	isa => 'Maybe[RegexpRef]',
);


=head3 root

When searching for the L</top_level> folder, only search inside this directory. 

B<root> defaults to the current directory.

=cut

has 'root' => (
	default => '.',
	is      => 'rw',
	isa     => 'Str',
);


=head3 folder

B<Data::ETL::Extract::FileListing> looks for the first folder matching this 
regular expression under the L</root> directory. It recursively returns the 
files underneath the matching directory.

=cut

has 'folder' => (
	is  => 'rw',
	isa => 'Maybe[RegexpRef]',
);


=head3 path

The full path name of the directory to list. Setting this attribute bypasses
the search for L</root> and L</folder>.

=cut

has 'path' => (
	is  => 'rw',
	isa => 'Str',
);


=head2 Automatically called from L<Data::ETL/run>

=head3 next_record

Read one record from the file and populate L<Data::ETL::Extract/record>. The
method returns the number of records loaded. A B<0> means that we reached the
end of the file.

C<next_record> uses the field number as the name. Field numbers start at B<0>.

=cut

sub next_record {
	my ($self) = @_;

	if ($self->no_matches) {
		return 0;
	} else {
		my $path = $self->next_match;
		my (undef, $directory, $file) = splitpath( $path );
		
		my %record;
		$record{Directory} = catpath( $self->path, $directory, '' );
		$record{Extension} = pop [split /\./, $file];
		$record{File}      = $file;
		$record{Path}      = catdir( $self->path, $path );
		$record{Relative}  = $path;
		
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
		if (defined $self->folder) {
			$self->path( shift [File::Find::Rule
				->directory()
				->name( $self->folder )
				->in( $self->root )
			] );
		} else { $self->path( $self->root ); }
	}

	die "Could not find a matching directory" unless defined $self->path;
	
	my $rule = File::Find::Rule->file()->relative();
	$rule->name( $self->name ) if defined $self->name;
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
