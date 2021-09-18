=pod

=head1 NAME

ETL::Pipeline::Input::Xml - Records from an XML file

=head1 SYNOPSIS

  use ETL::Pipeline;
  ETL::Pipeline->new( {
    input   => ['Xml', iname => 'Data.xml', root => '/Root'],
    mapping => {Name => 'Name', Address => 'Address'},
    output  => ['UnitTest']
  } )->process;

=head1 DESCRIPTION

B<ETL::Pipeline::Input::Xml> defines an input source that reads multiple records
from a single XML file. Individual records are repeating subnodes under
L</root>.

=cut

package ETL::Pipeline::Input::Xml;
use Moose;

use 5.014000;
use warnings;

use Carp;
use XML::Bare;


our $VERSION = '3.00';


=head1 METHODS & ATTRIBUTES

=head2 Arguments for L<ETL::Pipeline/input>

=head3 root

The path to the record nodes, such as C</XMLDATA/Root/Record>. The last item in
the list is the name of the root for each individual record. The code loops over
all of these nodes.

=cut

has 'root' => (
	default => '/',
	is      => 'ro',
	isa     => 'Str',
);


=head2 Methods

=head3 run

This is the main loop. It opens the file, reads records, and closes it when
done. This is the place to look if there are problems.

L<ETL::Pipeline> automatically calls this method.

=cut

sub run {
	my ($self, $pipeline) = @_;

	my $path = $self->file->stringify;

	# Load the XML file and turn it into a Perl hash.
	my $parser = XML::Bare->new( file => $path );
	my $xml = $parser->parse;

	# Find the node that is an array of records. This comes from the "root"
	# attribute.
	my $list = $xml;
	$list = $list->{$_} foreach (split '/', $self->root);

	# Process each record. And that's it.
	foreach my $record (@$list) {
		my $count = $record->{_i};
		my $char  = $record->{_pos};
		$pipeline->record( $record, "XML file '$path', record $count, file character $char" );
	}
}


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Input>, L<ETL::Pipeline::Input::File>,
L<XML::Bare>

=cut

with 'ETL::Pipeline::Input::File';
with 'ETL::Pipeline::Input';


=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vumc.org>

=head1 LICENSE

Copyright 2021 (c) Vanderbilt University Medical Center

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
