=pod

=head1 DESCRIPTION

L<ETL::Record> stores an individual record. This is the in-memory 
representation of a record. Applications create instances with the 
L<ETL/extract()> method.

The class helps track a record through the entire ETL pipeline. Inidvidual
records carry their state as they move from extract to transform to load.

=cut

package ETL::Record;
use Moose;

use Log::Log4perl;


=head1 METHODS & ATTRIBUTES

=head3 came_from

This text goes into error messages so that the user can find and fix any
problems with the original data. L<ETL/extract()> sets this value.

=cut

has 'came_from' => (
	is  => 'rw',
	isa => 'Str',
);


=head3 error

The last error message regarding this data. C<undef> indicates no error. The 
class automatically logs error messages along with the origin of the record.
That way you can trace errors back to the raw data.

=cut

has 'error' => (
	is      => 'rw',
	isa     => 'Str',
	trigger => \&_log_error,
);


sub _log_error($$$) {
	my ($self, $new, $old) = @_;
	Log::Log4perl->get_logger->error( "$new at " . $self->came_from )
		if hascontent( $new );
}


=head3 fields

This hash holds the processed data formatted for loading. The L<ETL/transform>
method converts L</raw> into L</fields>.

=cut

has 'fields' => (
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
	return $class->new( raw => \%data );
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


=head3 is_valid()

Invalid records have an error of some kind. The error prevents us from loading
the data to its final destination.

=cut

sub is_valid($) {
	my ($self) = @_;
	return (not defined( $self->error ));
}


=head3 raw

This hash holds the raw data as extracted from the input stream. It is keyed 
by the input field name, depending on the input format. For example, a 
spreadsheet would use the column. A text file might use a field number.

=cut

has 'raw' => (
	default => sub { {} },
	is      => 'ro',
	isa     => 'HashRef',
);


=head1 SEE ALSO

L<ETL>, L<ETL::Extract::FromFile>

=head1 LICENSE

Copyright 2010  The Center for Patient and Professional Advocacy, Vanderbilt University Medical Center
Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
