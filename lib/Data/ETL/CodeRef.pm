=pod

=head1 NAME

Data::ETL::CodeRef - Execute a code reference using both parameters and C<$_>

=head1 SYNOPSIS

  use Data::ETL::CodeRef;
  my $return = Data::ETL::CodeRef::run( $etl->stop_if, $etl );
  Data::ETL::CodeRef::run( sub { print 'Hello $_!' }, 'world' );

=cut

package Data::ETL::CodeRef;

use 5.14.0;
use Exporter qw/import/;


our @EXPORT  = ();
our $VERSION = '1.00';


=head1 DESCRIPTION

I found myself calling code references for all sorts of custom work. This
little code bit centralized it, letting me call all of the code references in
a consistent manner - using C<$_>.

Passing parameters can be formal. A lot of the code references are one liners.
Getting elements from C<@_> clouds up the code. Using <$_> is quick, easy, and
takes very little space.

On the other hand, longer code blocks can use C<@_> because they alter C<$_>.
Rather than choose one way or the other, I used both.

=head1 COMMANDS

=head3 run( $code_reference[, ...] )

This subroutine executes a code reference. Pass the code reference as the first
parameter. All of the remaining parameters are passed into the code reference.

C<run> also sets the C<$_> variable. C<$_> holds the same thing as the first
parameter to the code reference. You can use C<$_> or C<$_[0]> interchangeably.

C<run> returns C<undef> if the first parameter is not a code reference.

=cut

sub run {
	my $code = shift @_;

	if (defined( $code ) and ref( $code ) eq 'CODE') {
		local $_;
		$_ = $_[0];
		return $code->( @_ );
	} else { return undef; }
}


=head1 SEE ALSO

L<Data::ETL>

=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=head1 LICENSE

Copyright 2013 (c) Vanderbilt University

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

# Required for Perl to load the module.
1;
