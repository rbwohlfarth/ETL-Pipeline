=pod

=head1 NAME

ETL::Extract - Base class for ETL input sources

=head1 DESCRIPTION

This class defines the Application Programming Interface (API) for all ETL
input sources. The API allows applications to interact with the source without
worrying about its specific format (CSV file, spreadsheet, database, etc.).

=cut

package ETL::Extract;
use Moose;


=head1 METHODS & ATTRIBUTES

=head2 Override in Child Classes

=head3 extract()

This method returns the next record from input. The child class 
L<augments|Moose::Manual::MethodModifiers/INNER AND AUGMENT> C<extract>. The 
child class returns one of two values:

=over

=item An L<ETL::Record> object.

=item C<undef> for the end of the input.

=back

The child class should set the L</position> attribute to something that makes
sense for its format.

=cut

sub extract { 
	my ($self) = @_;

	# If we reached the end of the input, then I want to return undef. This
	# effectively stops reading and prevents errors from the source.
	if ($self->end_of_input) { return undef; }
	else {
		my $record = inner();
		if (defined $record) { return $record; }
		else {
			$self->end_of_input( 1 );
			return undef;
		}
	}
}


=head2 Standard Methods & Attributes

=head3 end_of_input

I<end_of_input> indicates when we reach the end of the input data. It holds
a boolean flag: B<true> = no more data.

I<extract> uses this flag. When the flag becomes true, I<extract> returns
the C<undef> value.

=cut

has 'end_of_input' => (
	default => 0,
	is      => 'rw',
	isa     => 'Bool',
);


=head3 position

I<position> identifies the last record loaded by L<extract()>. You will find
this useful for error messages.

The exact value depends on the input type. For example, a text file might have
the line number. A spreadsheet would keep the row number. A database records
the primary key.

B<WARNING:> Changing I<position> has no effect on the actual position. You 
cannot use it to skip records.

=cut

has 'position' => (
	default => '0',
	is      => 'rw',
	isa     => 'Str',
);


=head3 source

I<source> tells you where the data comes from. It might contain a file path,
or a database name. You set the value only once. It may B<not> change during 
execution. That causes all kinds of bugs.

=cut

has 'source' => (
	is  => 'rw',
	isa => 'Str',
);


=head1 SEE ALSO

L<ETL>, L<ETL::Record>

=head1 LICENSE

Copyright 2011  The Center for Patient and Professional Advocacy, Vanderbilt University Medical Center
Contact Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
