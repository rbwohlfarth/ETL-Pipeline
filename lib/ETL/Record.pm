=pod

=head1 DESCRIPTION

L<ETL::Record> stores an individual record. This is the in-memory 
representation of a record. Applications create instances with the 
L<ETL/extract()> method.

This class knows nothing about the format or content of the records. It
provides a generic API - so that I don't have different code covering every
possible input format.

=cut

package ETL::Record;
use Moose;


=head1 METHODS & ATTRIBUTES

=head3 came_from

This text goes into error messages so that the user can find and fix any
problems with the original data. L<ETL/extract()> sets this value.

=cut

has 'came_from' => (
	is  => 'rw',
	isa => 'Str',
);


=head3 data

This hash holds the actual data. It is keyed by the input field name, 
depending on the input format. For example, a spreadsheet would use the
column. A text file might use a field number.

=cut

has 'data' => (
	default => sub { {} },
	is      => 'ro',
	isa     => 'HashRef',
);


=head3 from_array( @data )

This class method returns a new L<ETL::Record> object with data from a Perl
list - or a reference to a list. L</data>'s hash key is the position number
in the list.

C<from_array> is a convenience method because a lot of input formats load data
into a list.

=cut

sub from_array($@) {
	my ($class, @fields) = @_;

	# The main loop always uses a list reference. That way I can use the
	# same loop, and still accept multiple types if input. If the only
	# parameter is a list reference, then we assume you want the referenced
	# list - not the pointer. Otherwise we copy the list you sent.
	my $list = \@fields;
	   $list = $fields[0] if (
			(@fields == 1) 
			and (ref( $fields[0] ) eq 'ARRAY')
		);

	# Yes - "foreach" is nicer. I need the index to create the key for the
	# hash. "foreach" doesn't offer any advantage in this case. Besides, I
	# want the hash to count from field one - not zero.
	my %data;
	for (my $index = 0; $index < @$list; $index++) {
		$data{$index + 1} = $list->[$index];
	}

	# Create an object that stores this data.
	return $class->new( data => \%data );
}


=head3 is_blank

This boolean flag indicates if the record is blank. I<Blank> may mean 
different things to different file formats. Using a flag gives me a standard
means of checking.

The L<ETL/extract()> normally sets this attribute.

=cut

has 'is_blank' => (
	default => 0,
	is      => 'rw',
	isa     => 'Bool',
);


=head1 SEE ALSO

L<ETL>, L<ETL::Extract::FromFile>

=head1 LICENSE

Copyright 2010  The Center for Patient and Professional Advocacy, Vanderbilt University Medical Center
Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=cut

no Moose;
__PACKAGE__->meta->make_immutable;

