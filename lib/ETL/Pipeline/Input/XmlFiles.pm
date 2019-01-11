=pod

=head1 NAME

ETL::Pipeline::Input::XmlFiles - Records in individual XML files

=head1 SYNOPSIS

  use ETL::Pipeline;
  ETL::Pipeline->new( {
    input   => ['XmlFiles', from => 'Documents'],
    mapping => {Name => '/Root/Name', Address => '/Root/Address'},
    output  => ['UnitTest']
  } )->process;

=head1 DESCRIPTION

B<ETL::Pipeline::Input::XmlFiles> defines an input source that reads multiple
XML files from a directory. Each XML file contains exactly one record. Fields
are accessed with the full XML path.

=cut

package ETL::Pipeline::Input::XmlFiles;
use Moose;

use 5.014000;
use warnings;

use Carp;
use MooseX::Types::Path::Class qw/Dir File/;
use Path::Class qw//;
use Path::Class::Rule;
use XML::XPath;


our $VERSION = '2.03';


=head1 METHODS & ATTRIBUTES

=head2 Arguments for L<ETL::Pipeline/input>

B<ETL::Pipeline::Input::XmlFiles> accepts any of the tests provided by
L<Path::Iterator::Rule>. The value of the argument is passed directly into the
test. For boolean tests (e.g. readable, exists, etc.), pass an C<undef> value.

B<ETL::Pipeline::Input::XmlFiles> automatically applies the C<file> and
C<iname> filters. Do not pass C<file> through L<ETL::Pipeline/input>. You may
pass in C<name> or C<iname> to override the default filter of B<*.xml>.

=cut

sub BUILD {
	my $self = shift;
	my $arguments = shift;

	# Filter out attributes for this class. They are not file search criteria.
	# Except for "file", which is search criteria and an attribute. From the
	# constructor, we treat it as criteria. The "file" attribute is set
	# internally by "next_record".
	my @criteria = grep {
		$_ ne 'file'
		&& !$self->meta->has_attribute( $_ )
	} keys %$arguments;

	# Configure the file search.
	my $search = Path::Class::Rule->new;
	foreach my $name (@criteria) {
		my $value = $arguments->{$name};
		eval "\$search->$name( \$value )";
		croak $@ unless $@ eq '';
	}
	$search->iname( '*.xml' )
		unless exists( $arguments->{name} ) || exists( $arguments->{iname} );
	$search->file;

	# Save the file iterator for "next_record".
	$self->_set_iterator( $search->iter( $self->pipeline->data_in ) );
}


=head2 Called from L<ETL::Pipeline/process>

=head3 get

B<get> returns a single value form a matching node. The field name is an
I<XPath>, relative to L</root>. See
L<http://www.w3schools.com/xpath/xpath_functions.asp> for more information on
XPaths.

XML lends itself to recursive records. That means a single field name can
match multiple nodes. B<get> throws an error with C<die> in this case. Use
L</get_repeating> instead.

  # Return a single value from a single field.
  $etl->get( 'Name' );
  'John Doe'

  # Subnode.
  $etl->get( 'PersonInvolved/Name' );
  'John Doe'

In the L<ETL::Pipeline/mapping>, those examples looks like this...

  # Return a single value from a single field.
  ETL::Pipeline->new( {
    ...
    mapping => {Name => 'Name'},
    ...
  } )->process;

  # Subnode.
  ETL::Pipeline->new( {
    ...
    mapping => {Name => 'PersonInvolved/Name'},
    ...
  } )->process;

=cut

sub get {
	my ($self, $find) = @_;
	my $xpath = $self->xpath;

	my $match = $xpath->find( $find );
	if ($match->isa( 'XML::XPath::NodeSet' )) {
		my @values = map { $_->string_value } $match->get_nodelist;
		if (scalar( @values ) == 0) {
			return undef;
		} elsif (scalar( @values ) == 1) {
			return $values[0];
		} else {
			my $count = scalar( @values );
			confess "$count matches found for \"$find\"";
		}
	} else {
		return $match->value;
	}
}


=head3 next_record

This method parses the next file in the folder.

B<Data::ETL::Extract::XmlFiles> builds a list of file names when it first
starts. B<next_record> iterates over this in-memory list. It will not parse
any new files saved into the folder.

=cut

sub next_record {
	my ($self) = @_;

	my $object = $self->_next_file;
	if (defined $object) {
		$self->_set_file( $object );

		my $parser = XML::XPath->new( filename => "$object" );
		croak "Unable to parse the XML in '$object'" unless defined $parser;
		$self->_set_xpath( $parser );

		return 1;
	} else { return 0; }
}


=head3 configure

B<configure> doesn't actually do anything. But it is required by
L<ETL::Pipeline/process>.

=cut

sub configure { }


=head3 finish

B<finish> doesn't actually do anything. But it is required by
L<ETL::Pipeline/process>.

=cut

sub finish { }


=head2 Other Methods & Attributes

=head3 get_repeating

get_repeating retrieves multiple matching nodes (aka a I<node set>). L</get>
returns a single value. B<get_repeating> works with XML's repeating nodes. It
returns a list of values - even if there is only one match.

Here's an example...

  # Return a list from multiple fields with the same name.
  $etl->get_repeating( 'PersonInvolved/Name' );
  ('John Doe', 'Jane Doe')

  # Throws an error!
  $etl->get( 'PersonInvolved/Name' );

What happens when you need two fields under the same subnode? For example,
a I<person involved> can have both a I<name> and a I<role>. The names and roles
go together. You would call B<get_repeating> with more than one parameter.

The first parameter is the XPath for the root of the repeating nodes. The
rest of the parameters are subnodes under it that you want values from.
B<get_repeating> returns a list of array references. Each reference holds the
values from a single matching node.

  $etl->get_repeating( 'PersonInvolved', 'Name', 'Role' );
  (['John Doe', 'Husband'], ['Jane Doe', 'Wife'])

This is what the examples look like with L<ETL::Pipeline/mapping>...

  # Return a list from multiple fields with the same name.
  ETL::Pipeline->new( {
    ...
    mapping => {Involved => sub { $_->input->get_repeating( 'PersonInvolved/Name' ) },
    ...
  } )->process;
  ('John Doe', 'Jane Doe')

  # Return multiple sub nodes.
  ETL::Pipeline->new( {
    ...
    mapping => {Involved => sub { $_->input->get_repeating(
      'PersonInvolved',
      'Name',
      'Role'
    ) },
    ...
  } )->process;
  (['John Doe', 'Husband'], ['Jane Doe', 'Wife'])

If no nodes match the XPaths, B<get_repeating> reutrns an empty list.

=cut

sub get_repeating {
	my ($self, $top, @subnodes) = @_;
	my $xpath = $self->xpath;

	my $match = $xpath->find( $top );
	if ($match->isa( 'XML::XPath::NodeSet' )) {
		if (scalar( @subnodes ) == 0) {
			return map { $_->string_value } $match->get_nodelist;
		} elsif (scalar( @subnodes ) == 1) {
			my @values;
			foreach my $node ($match->get_nodelist) {
				my $data = $xpath->find( $subnodes[0], $node );
				push @values, $data->string_value;
			}
			return @values;
		} else {
			my @values;
			foreach my $node ($match->get_nodelist) {
				my @current;
				foreach my $path (@subnodes) {
					my $data = $xpath->find( $path, $node );
					push @current, $data->string_value;
				}
				push @values, \@current;
			}
			return @values;
		}
	} else { return $match->value; }
}


=head3 exists

The B<exists> method tells you whether the given path exists or not. It returns
a boolean value. B<True> means that the given node exists in this XML file.
B<False> means that it does not.

B<exists> accepts an XPath string as the only parameter. You can learn more
about XPath here: L<http://www.w3schools.com/xpath/xpath_functions.asp>.

=cut

sub exists {
	my ($self, $xpath_string) = @_;

	my @matches = $self->xpath->findnodes( $xpath_string );
	return (scalar( @matches ) > 0 ? 1 : 0);
}


=head3 file

The B<file> attribute holds a L<Path::Class:File> object for the current XML
file. You can use it for accessing the file name or directory.

B<file> is automatically set by L</next_record>.

=cut

has 'file' => (
	init_arg => undef,
	is       => 'ro',
	isa      => File,
	writer   => '_set_file',
);


=head3 iterator

L<Path::Class::Rule> creates an iterator that returns each file in turn.
B<iterator> holds it for L</next_record>.

=cut

has 'iterator' => (
	handles => {_next_file => 'execute'},
	is      => 'ro',
	isa     => 'CodeRef',
	traits  => [qw/Code/],
	writer  => '_set_iterator',
);


=head3 xpath

The B<xpath> attribute holds the current L<XML::XPath> object. It is
automatically set by the L</next_record> method.

=cut

has 'xpath' => (
	init_arg => undef,
	is       => 'ro',
	isa      => 'XML::XPath',
	writer   => '_set_xpath',
);


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Input>, L<ETL::Pipeline::Input::XML>,
L<Path::Class::File>, L<Path::Class::Rule>, L<Path::Iterator::Rule>,
L<XML::XPath>

=cut

with 'ETL::Pipeline::Input';


=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vumc.org>

=head1 LICENSE

Copyright 2019 (c) Vanderbilt University Medical Center

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
