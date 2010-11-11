use Log::Log4perl qw/:easy/;
use Test::More;

# Prevent bogus warning messages in the tests.
Log::Log4perl->easy_init( $ERROR );


BEGIN { use_ok( 'ETL::Extract::FromFile' ); }
require_ok( 'ETL::Extract::FromFile' );

my $file = new_ok( 'ETL::Extract::FromFile' => [
	path => 'test.txt',
] );

is( $file->end_of_input, 1    , 'Failure marks end_of_input()'           );
is( $file->position    , 0    , 'Failure resets position()'              );
is( $file->extract     , undef, 'extract() returned undef with no input' );


done_testing();
