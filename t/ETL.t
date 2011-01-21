use Log::Log4perl qw/:easy/;
use Test::More;

# Prevent bogus warning messages in the tests.
Log::Log4perl->easy_init( $ERROR );


BEGIN { use_ok( 'ETL' ); }
require_ok( 'ETL' );


done_testing();
