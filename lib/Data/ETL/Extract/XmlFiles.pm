=pod

=head1 NAME

Data::ETL::Extract::XmlFiles - Process XML content from individual files

=head1 SYNOPSIS

  use Data::ETL;
  working_folder search_in => 'C:\Data', find_folder => qr/Ficticious/;
  extract_from 'XmlFiles';
  transform_as ExternalID => '/File/A', PatientName => '/File/Patient';
  load_into 'Access', file => 'review.accdb';
  run;

=head1 DESCRIPTION

ETL stands for I<Extract-Transform-Load>. L<Data::ETL> uses
L<bridge classes|Data::ETL/Bridge Classes> for reading and writing files. This
role defines the API for input L<bridge classes|Data::ETL/Bridge Classes> -
those used by the L<Data::ETL/extract_from> command.

This class defines an ETL input source that parses multiple XML files - one per
record. Unlike L<Data::ETL::Extract::Xml>, this class expects many XML files
with one entire record in each file. You use this class by naming it in the
L<Data::ETL/extract_from> call. You would not normally use it directly.

B<Data::ETL::Extract::Xml> implements the L<Data::ETL::Extract> role.

=cut

package Data::ETL::Extract::XmlFiles;

use 5.14.0;
use File::Find::Rule;
use List::Util qw/first/;
use Moose;
use String::Util qw/hascontent trim/;
use XML::XPath;


our $VERSION = '1.00';


=head1 METHODS & ATTRIBUTES

=head2 Set with the L<Data::ETL/extract_from> command

=head3 find_file

B<Data::ETL::Extract::XmlFiles> searches the
L<working folder|Data::ETL/working_folder> for all file names that match this
regular expression. It loads each file in turn.

The default value finds all files with an B<xml> extension (case insensitive).

=cut

has 'find_file' => (
	default => sub { qr/\.xml$/i },
	is      => 'rw',
	isa     => 'Maybe[RegexpRef]',
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
  transform_as Followup => '/File/More/Text';

  # Returns "Line one\r\n\r\nLine two" (blank line between)
  transform_as Followup => ['/File/More/Text', "\r\n\r\n"];

The XPath goes into the first list element. The second list element can be...

=over

=item 'first'

Selects just the first occurence. It discards any other occurences.

  # Returns "Line one"
  transform_as Followup => ['/File/More/text', 'first'];

=item 'last'

Selects just the last occurence. It discards any other occurences.

  # Returns "Line two"
  transform_as Followup => ['/File/More/text', 'last'];

=item undef

Like I<first>, it selects just the first occurence. It discards any other
occurences.

  # Returns "Line one"
  transform_as Followup => ['/File/More/text', undef];

=item Any other string

Uses this string as the seperator between multiple values.

  # Returns "Line one\r\n\r\nLine two" (blank line between)
  transform_as Followup => ['/File/More/Text', "\r\n\r\n"];

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


=head3 path

Returns the relative path of the current XML file. You can use this method to
get at the file name.

  transform_as File => sub { $_->path };

=cut

has 'path' => (
	is  => 'rw',
	isa => 'Str',
);


=head3 next_record

This method parses the next file in the folder.

B<Data::ETL::Extract::XmlFiles> builds a list of file names when it first
starts. B<next_record> iterates over this in-memory list. It will not parse
any new files saved into the folder.

=cut

sub next_record {
	my ($self) = @_;

	if ($self->no_matches) {
		return 0;
	} else {
		my $file = $self->next_match;
		$self->path( $file );

		my $parser = XML::XPath->new( filename => $file );
		die "Unable to parse the XML in '$file'" unless defined $parser;

		$self->xpath( $parser );
		return 1;
	}
}


=head3 setup

This method finds all of the XML files and saves the path names into a list.
L</next_record> iterates over this list, loading each in turn.

=cut

sub setup {
	my ($self) = @_;

	my $rule = File::Find::Rule->file();
	$rule->name( $self->find_file ) if defined $self->find_file;
	$self->add_matches( $rule->in( $Data::ETL::WorkingFolder ) );
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

=head3 matches

The list of files that matched L</find_file>. L</next_record> iterates over
this list.

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


=head3 xpath

This attribute holds the current L<XML::XPath> object. It lets the code access
text using standard XPath strings.

=cut

has 'xpath' => (
	is  => 'rw',
	isa => 'XML::XPath',
);


=head1 SEE ALSO

L<Data::ETL>, L<Data::ETL::Extract>, L<Data::ETL::Extract::Xml>

=cut

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
