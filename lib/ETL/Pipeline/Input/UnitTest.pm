=pod

=head1 NAME

ETL::Pipeline::Input::UnitTest - Input source for unit tests

=head1 SYNOPSIS

  use ETL::Pipeline;
  ETL::Pipeline->new( {
    input   => ['UnitTest'],
    mapping => {First => 'Header1', Second => 'Header2'},
    output  => ['UnitTest']
  } )->process;

=head1 DESCRIPTION

B<ETL::Pipeline::Input::UnitTest> is an input source used by the unit tests.
It proves that the L<ETL::Pipeline::Input> role works.

The I<data> is hard coded.

=cut

package ETL::Pipeline::Input::UnitTest;
use Moose;

use strict;
use warnings;

use 5.014;


our $VERSION = '3.00';


=head1 METHODS & ATTRIBUTES

=head2 Arguments for L<ETL::Pipeline/input>

None - there's no configuration for this source. It's meant to be quick and
light for unit testing.

=head2 Methods

=head3 run

This is the main loop. For unit tests, I use hard coded data. This guarantees
consistent behavior.

L<ETL::Pipeline> automatically calls this method.

=cut

sub run {
	my ($self, $etl) = @_;

	$etl->add_alias( 'Header1'    , 1 );
	$etl->add_alias( 'Header2'    , 2 );
	$etl->add_alias( 'Header3'    , 3 );
	$etl->add_alias( '  Header4  ', 4 );

	$etl->record( {
		1 => 'Field1',
		2 => 'Field2',
		3 => 'Field3',
		4 => 'Field4',
		5 => 'Field5',
	}, 'Row 1' );
	$etl->record( {
		1 => 'Field6',
		2 => 'Field7',
		3 => 'Field8',
		4 => 'Field9',
		5 => 'Field0',
	}, 'Row 2' );
}


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Input>, L<ETL::Pipeline::Output::UnitTest>

=cut

with 'ETL::Pipeline::Input';


=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vumc.org>

=head1 LICENSE

Copyright 2021 (c) Vanderbilt University

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
