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

=head3 run

This is the main loop. For unit tests, I use hard coded data. This guarantees
consistent behavior.

L<ETL::Pipeline> automatically calls this method.

=cut

sub run {
	my ($self, $pipeline) = @_;

	$pipeline->add_alias( 'Header1'    , 1 );
	$pipeline->add_alias( 'Header2'    , 2 );
	$pipeline->add_alias( 'Header3'    , 3 );
	$pipeline->add_alias( '  Header4  ', 4 );

	$pipeline->record( {
		1 => 'Field1',
		2 => 'Field2',
		3 => 'Field3',
		4 => 'Field4',
		5 => 'Field5',
	}, 'Row 1' );
	$pipeline->record( {
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
