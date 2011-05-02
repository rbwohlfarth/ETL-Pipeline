use Log::Log4perl qw/:easy/;
use Test::More;

# Prevent bogus warning messages in the tests.
Log::Log4perl->easy_init( $ERROR );


BEGIN { use_ok( 'ETL::Extract::FromFile' ); }
require_ok( 'ETL::Extract::FromFile' );

my $file = new_ok( 'ETL::Extract::FromFile' => [source => 't/test.txt'] );

is( $file->extract     , undef, 'extract() returned undef with no input' );
is( $file->end_of_input, 1    , 'end_of_input() set correctly'           );
is( $file->position    , 0    , 'position() only changes with data'      );


done_testing();
