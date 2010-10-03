use Log::Log4perl qw/:easy/;
use Test::More;

BEGIN { use_ok( 'ETL::Extract::FromFile' ); }
require_ok( 'ETL::Extract::FromFile' );


# Prevent bogus warning messages in the tests.
Log::Log4perl->easy_init( $ERROR );


# Test object creation - does it compile?
my $file = new_ok( 'ETL::Extract::FromFile' );


# connect()
not_ok( $file->connect( 'test.txt' ), 'connect()' );
is( $file->end_of_input, 1, 'end_of_input()' );
is( $file->position    , 0, 'position( 0 )'  );


# extract()
is( $file->extract, undef, "extract => undef" );


done_testing();

