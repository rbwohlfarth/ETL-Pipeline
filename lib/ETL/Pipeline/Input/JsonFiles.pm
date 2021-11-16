=pod

=head1 NAME

ETL::Pipeline::Input::JsonFiles - Process JSON content from individual files

=head1 SYNOPSIS

  use Data::ETL;
  working_folder search_in => 'C:\Data', find_folder => qr/Ficticious/;
  extract_from 'JsonFiles', records_at => '/json';
  transform_as ExternalID => '/File/A', PatientName => '/File/Patient';
  load_into 'Access', file => 'review.accdb';
  run;

=head1 DESCRIPTION

B<ETL::Pipeline::Input::JsonFiles> defines an input source that reads one or
more records from one or more JSON files. Most of the time, there should be one
record per file. But the class handles multiple records per file too.

=cut

package ETL::Pipeline::Input::JsonFiles;

use 5.014000;
use warnings;

use Carp;
use JSON;
use Moose;


our $VERSION = '2.00';


=head1 METHODS & ATTRIBUTES

=head2 Arguments for L<ETL::Pipeline/input>

=head3 records_at

Optional. The path to the record nodes, such as C</json/Record>. The
last item in the list is the name of the root for each individual record. The
default is B</json> - one record in the file.

You might use this attribute in two cases...

=over

=item 1. Multiple records per file. This is the top of each record, like in L<ETL::Pipeline::Input::Xml>.

=item 2. Shorthand to leave off extra nodes from every path. One record per file, but you don't want extra path parts on the beginning of every field.

=back

=cut

has 'records_at' => (
	default => '/',
	is      => 'ro',
	isa     => 'Str',
);


=head3 skipping

Not used. This attribute is ignored. JSON files must follow specific formatting
rules. Extra rows are parsed as data. There's nothing to skip.

=head2 Methods

=head3 run

This is the main loop. It opens the file, reads records, and closes it when
done. This is the place to look if there are problems.

L<ETL::Pipeline> automatically calls this method.

=cut

sub run {
	my ($self, $etl) = @_;

	my $parser = JSON->new->utf8;
	while (my $path = $self->next_path( $etl )) {
		my $text = $path->slurp;	# Force scalar context, otherwise slurp breaks it into lines.
		my $json = $parser->decode( $text );
		croak "JSON file '$path', unable to parse" unless defined $json;

		# Find the node that is an array of records. This comes from the
		# "records_at" attribute.
		my $list = $json;
		$list = $list->{$_} foreach (grep { $_ ne '' } split '/', $self->records_at);
		$list = [$list] unless ref( $list ) eq 'ARRAY';

		# Process each record. And that's it. The record is a Perl data
		# structure corresponding with the JSON structure.
		foreach my $record (@$list) {
			my $output = $parser->encode( $record );
			$etl->record( $record );
		}
	}
}


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Input>, L<ETL::Pipeline::Input::File::List>,
L<JSON>

=cut

with 'ETL::Pipeline::Input';
with 'ETL::Pipeline::Input::File::List';


=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vumc.org>

=head1 LICENSE

Copyright 2021 (c) Vanderbilt University Medical Center

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
