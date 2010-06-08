=pod

=head1 SYNOPSIS

 use RawData;

 # Try to guess the file type from the extension, and prompt if that fails.
 # This is what you would use in the majority of cases.
 $parser = RawData->get_file_type( $path );

 # Pick a file type based on the file's extension. This is useful for 
 # non-interactive processes.
 $parser = RawData->guess_file_type( $path );

 # Pick a file type from a list of available options. This is for when you
 # don't want to trust the built in guessing.
 $parser = RawData->choose_file_type( $path );

=head1 DESCRIPTION

A file parser reads data from an external data file. This class provides
convenience functions for choosing the correct parser type. This keeps you
from duplicating the same logic in multiple applications.

=cut

package RawData;
use Moose;

use File::Spec::Functions qw/catdir catpath rel2abs splitpath/;
use Win32::GUI qw//;


=head1 METHODS & ATTRIBUTES

=head3 RawData->choose_file_type( $path )

Manually select a file type for a list of available classes. This is useful
when the automatic guess fails.

The function returns a L<RawData::File> object of the correct type.

You can pass the full path name to your data file. The class then points
L<RawData::File> to it. This parameter is optional.

B<Warning:> This method only works on MS Windows.

=cut

sub choose_file_type($;$) {
	my ($class, $path) = @_;

	# Look for modules under the same directory as this package.
	my ($volume, $directory, undef) = splitpath( 
		rel2abs( $INC{__PACKAGE__ . '.pm'} )
	);

	my $inc_directory    = catpath( $volume, $directory, undef );
	my $search_directory = catpath( 
		$volume, 
		catdir( $directory, 'RawData' ), 
		undef 
	);

	# Prompt for the module...
	my $type = Win32::GUI::GetOpenFileName(
		-directory     => $search_directory,
		-filemustexist => 1,
		-owner         => Win32::GUI::GetPerlWindow(),
		-title         => 'Choose a file type',
	);

	# Get the Perl module notation for this file...
	if (defined $type) {
		$inc_directory =~ s/\\/\\\\/g;
		$type          =~ s/^$inc_directory//;
	}

	# Return an object of the correct type. If the user cancels the dialog
	# box, we return "undef".
	return $class->create_file_object( $type, $path );
}


=head3 RawData->create_file_object( $type )

Creates a L<RawData::File> object of the given type. The function returns
C<undef> if there is an error.

=cut

sub create_file_object($$;$) {
	# I normally use "@_". In this case, I wanted to declare $path 
	# differently from the other variables.
	my  $class     = shift;
	my  $file_name = shift;
	our $path      = shift;

	if (defined $file_name) {
		require $file_name;

		# Convert the file name into a Perl package name...
		my $module_name =  $file_name;
		   $module_name =~ s/\.pm$//i;
		   $module_name =~ s/(\\|\/)/::/g;

		# Create the object, with a dynamic class name...
		our $object;
		eval "\$object = new $module_name";

		# Open the data file for reading...
		$object->file( $path ) if (defined $path);

		return $object;
	} else {
		return undef;
	}
}


=head3 RawData->get_file_type( $path )

This function tries L</guess_file_type( $path )>. If that fails, the code 
automatically calls L</choose_file_type( $path )>. For interactive programs,
this is the method you want to use.

C<$path> is the full path name to your data file.

The method returns a L<RawData::File> object.

=cut

sub get_file_type($$) {
	my ($class, $path) = @_;

	my $file = $class->guess_file_type( $path );

	$file = $class->choose_file_type( $path ) 
		unless (defined $file);

	return $file;
}


=head3 RawData->guess_file_type( $path )

Determine a file's type based on its extension. I hope to eventually make this
a bit more generic. For the moment, I have to add each new file type.

The function returns a L<RawData::File> object of the correct type.

Pass the full path name to your data file as the only parameter.

=cut

sub guess_file_type($$) {
	my ($class, $path) = @_;

	# Extract the file extension...
	my (undef, undef, $file) = splitpath( $path );
	my @parts     = split( /\./, $file );
	my $extension = lc( pop( @parts ) );

	# Determine the type from the extension...
	my $type;
	if    ($extension eq 'xls') { $type = 'RawData\Excel2003.pm'    ; }
	elsif ($extension eq 'txt') { $type = 'RawData\DelimitedText.pm'; }

	# Return an object of the correct type...
	return $class->create_file_object( $type, $path );
}


=head1 SEE ALSO

L<RawData::File>

=head1 LICENSE

Copyright 2010  The Center for Patient and Professional Advocacy, 
Vanderbilt University Medical Center

Contact Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=cut

no Moose;
__PACKAGE__->meta->make_immutable;

