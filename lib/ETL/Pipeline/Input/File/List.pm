=pod

=head1 NAME

ETL::Pipeline::Input::File::List - Role for input sources with multiple files

=head1 SYNOPSIS

  # In the input source...
  use Moose;
  with 'ETL::Pipeline::Input';
  with 'ETL::Pipeline::Input::File::List';
  ...

=head1 DESCRIPTION

This is a role used by input sources. It defines standard attributes and
methods for processing multiple input files of the same format. The role uses
L<Path::Class::Rule> to search for matching files.

=cut

package ETL::Pipeline::Input::File::List;
use Moose;

use 5.014000;
use Carp;
use MooseX::Types::Path::Class qw/Dir/;
use Path::Class;
use Path::Class::Rule;


our $VERSION = '3.00';


=head1 METHODS & ATTRIBUTES

=head2 Arguments for L<ETL::Pipeline/input>

B<ETL::Pipeline::Input::File::List> accepts any of the tests provided by
L<Path::Iterator::Rule>. The value of the argument is passed directly into the
test. For boolean tests (e.g. readable, exists, etc.), pass an C<undef> value.

B<ETL::Pipeline::Input::File> automatically applies the C<file> filter. Do not
pass C<file> through L<ETL::Pipeline/input>.

C<iname> is the most common one that I use. It matches the file name, supports
wildcards and regular expressions, and is case insensitive.

  # Search using a regular expression...
  $etl->input( 'XmlFiles', iname => qr/\.xml$/ );

  # Search using a file glob...
  $etl->input( 'XmlFiles', iname => '*.xml' );

=cut

sub BUILD {
	my $self = shift;
	my $arguments = shift;

	# Configure the file search.
	my @criteria = grep {
		$_ ne 'file'
		&& !$self->meta->has_attribute( $_ )
	} keys %$arguments;
	my $search = Path::Class::Rule->new;
	foreach my $name (@criteria) {
		my $value = $arguments->{$name};
		eval "\$search->$name( \$value )";
		croak $@ unless $@ eq '';
	}
	$search->file;
	$self->_iterator( $search->iter( $self->data_in ) );
}


=head3 data_in

Optional. Path where data files reside. Defaults to L<ETL::Pipeline/data_in>.

The default is actually set inside L<ETL::Pipeline/run> when it instantiates
the input source. If the script doesn't set B<data_in>, then
L<ETL::Pipeline/run> adds it.

=cut

has 'data_in' => (
	coerce => 1,
	is     => 'ro',
	isa    => Dir,
);


=head3 file

L<Path::Class::File> object for the currently selected file. This is first file
that matches the criteria. When you call L</next_file>, it finds the next match
and sets B<file>.

So B<file> always points to the current file. It should be used by your input
source class as the file name.

  # Inside the input source class...
  $self->next_file();
  open my $io, '<', $self->file;

C<undef> means no more matches.

=cut

has 'file' => (
	coerce => 1,
	is     => 'rw',
	isa    => Maybe[File],
);


=head2 Methods

=head3 next_file

Looks for the next match in the list and sets the L</file> attribute. It also
returns the matching file.

Your input source class should call this method when it reaches the end of each
file. This moves to the next file in the list.

=cut

sub next_file {
	my ($self) = @_;
	return $self->file( $self->_iterator->() );
}


#-------------------------------------------------------------------------------
# Internal methods and attributes

# "Path::Class::Rule" creates an iterator that returns each file in turn. This
# attribute holds it for "next_record".
has '_iterator' => (
	is  => 'rw',
	isa => 'CodeRef',
);


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Input>, L<Path::Class::File>,
L<Path::Class::Rule>, L<Path::Iterator::Rule>

=cut

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
