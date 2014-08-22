=pod

=head1 NAME

Data::ETL::Extract::Xml - L<Data::ETL> bridge class for reading an XML file

=head1 SYNOPSIS

  use Data::ETL;
  working_folder search_in => 'C:\Data', find_folder => qr/Ficticious/;
  extract_from 'Xml', find_file => qr/\.xml$/i, root_node => '/File';
  transform_as ExternalID => '/A', PatientName => '/Patient';
  load_into 'Access', file => 'review.accdb';
  run;

=head1 DESCRIPTION

ETL stands for I<Extract-Transform-Load>. L<Data::ETL> uses
L<bridge classes|Data::ETL/Bridge Classes> for reading and writing files. This
role defines the API for input L<bridge classes|Data::ETL/Bridge Classes> -
those used by the L<Data::ETL/extract_from> command.

This class defines an ETL input source that parses a single XML file containing
multiple records. You use this class by naming it in the
L<Data::ETL/extract_from> call. You would not normally use it directly.

B<Data::ETL::Extract::Xml> implements the L<Data::ETL::Extract> and
L<Data::ETL::Extract::File> roles.

=cut

use 5.14.0;
use strict;
use warnings;

package Data::ETL::Extract::Xml;
use Moose;

with 'Data::ETL::Extract';
with 'Data::ETL::Extract::File';

use List::Util qw/first/;
use String::Util qw/hascontent trim/;
use XML::XPath;


our $VERSION = '1.00';


=head1 METHODS & ATTRIBUTES

=head3 attribute

This method returns the value of an attribute of the root node. From some
databases, I see tags with an attribute like C<ACTION="DELETE">. This method
lets me check attributes in the L<Data::ETL::Extract/bypass_if> routine.

  extract_from 'Xml',
      bypass_if => sub { $_->attribute( 'ACTION' ) eq 'DELETE' },
      find_file => qr/\.xml$/i,
      root_node => '/File'
  ;

=cut

sub attribute {
	my ($self, $name) = @_;
	return $self->node->getAttribute( $name );
}


=head2 Set with the L<Data::ETL/extract_from> command

B<Data::ETL::Extract::XML> also supports all of the options from
L<Data::ETL::Extract> and L<Data::ETL::Extract::File>. If you can't find the
option you want here, also check L<Data::ETL::Extract> or
L<Data::ETL::Extract::File>.

=head3 root_node

This attribute holds an XPath to the top node of individual records. The input
source iterates through this node - once for each record. Consider this the top
level (root) of the record.

This XPath starts from the document root.

=cut

has 'root_node' => (
	is  => 'rw',
	isa => 'Str',
);


=head2 Automatically called from L<Data::ETL/run>

=head3 get

This method returns the value of a single field. The only parameter is an XPath
string. The method returns a string representing the nodes found at that
location. You can learn more about XPath here:
L<http://www.w3schools.com/xpath/xpath_functions.asp>.

B<Important Note:> The XPath is relative to the current record - not the
document root.

=head4 Multiple values

So what happens when the XPath returns multiple nodes? C<get> joins the string
values together with a semi-colon between them: C<'; '>. If you want a
different seperator, pass it to C<get> using a list reference.

  # Returns "Line one; Line two"
  transform_as Followup => 'More/Text';

  # Returns "Line one\r\n\r\nLine two" (blank line between)
  transform_as Followup => ['More/Text', "\r\n\r\n"];

The XPath goes into the first list element. The second list element can be...

=over

=item 'first'

Selects just the first occurence. It discards any other occurences.

  # Returns "Line one"
  transform_as Followup => ['More/text', 'first'];

=item 'last'

Selects just the last occurence. It discards any other occurences.

  # Returns "Line two"
  transform_as Followup => ['More/text', 'last'];

=item undef

Like I<first>, it selects just the first occurence. It discards any other
occurences.

  # Returns "Line one"
  transform_as Followup => ['More/text', undef];

=item Any other string

Uses this string as the seperator between multiple values.

  # Returns "Line one\r\n\r\nLine two" (blank line between)
  transform_as Followup => ['More/Text', "\r\n\r\n"];

=back

This means that you cannot use the words B<first> or B<last> as seperators.
They make poor seperators. Find something more suitable.

=cut

sub get {
	my ($self, $xpath) = @_;

	my ($xpath_string, $join_with) = ($xpath, '; ');
	($xpath_string, $join_with) = @$xpath if ref( $xpath ) eq 'ARRAY';

	my $match = $self->xpath->find( $xpath_string, $self->node );
	if ($match->isa( 'XML::XPath::NodeSet' )) {
		my @values = grep { hascontent( $_ ) }
			map { trim( $_->string_value ) }
			$match->get_nodelist
		;
		if    (not defined $join_with     ) { return shift @values; }
		elsif (lc( $join_with ) eq 'first') { return shift @values; }
		elsif (lc( $join_with ) eq 'last' ) { return pop   @values; }
		else                                { return join( $join_with, @values ); }
	} else { return $match->value; }
}


=head3 next_record

This method retrieves the next record from the current node set. Each I<record>
begins at the L</root_node>.

=cut

sub next_record {
	my ($self) = @_;

	my $return = undef;
	until (defined $return) {
		my $next = $self->nodeset->shift();
		if (not defined $next) {
			$return = 0;
		} elsif ($next->isa( 'XML::XPath::Node::Element' )) {
			$self->node( $next );
			$return = 1;
		}
	}
	return $return;
}


=head3 setup

This method opens the XML file and extracts the node set. L</next_record> then
iterates over the node set.

=cut

sub setup {
	my ($self) = @_;

	my $path = $self->path;
	my $root = $self->root_node;

	my $parser = XML::XPath->new( filename => $path );
	my $nodeset = $parser->findnodes( $root );
	die "Cannot find $root in $path" unless defined $nodeset;

	$self->xpath( $parser );
	$self->nodeset( $nodeset );
}


=head3 finished

This method shuts down the input source. In our case, it does nothing.

=cut

sub finished { }


=head3 set_field_names

This method processes a record with field names. In this case, it does nothing.

=cut

sub set_field_names {}


=head2 Internal Attributes and Methods

You should never use these items. They can change at any moment. I documented
them for the module maintainers.

=head3 node

This attribute holds the currently selected node (record).

=cut

has 'node' => (
	is  => 'rw',
	isa => 'XML::XPath::Node::Element',
);


=head3 nodeset

This attribute holds the node set of root elements. It is a list of the records
in this file.

=cut

has 'nodeset' => (
	is  => 'rw',
	isa => 'XML::XPath::NodeSet',
);


=head3 xpath

This attribute holds the current L<XML::XPath> object. It lets the code access
text using standard XPath strings.

=cut

has 'xpath' => (
	is  => 'rw',
	isa => 'XML::XPath',
);


=head1 SEE ALSO

L<Data::ETL>, L<Data::ETL::Extract>, L<Data::ETL::Extract::File>

=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=head1 LICENSE

Copyright 2013 (c) Vanderbilt University

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
