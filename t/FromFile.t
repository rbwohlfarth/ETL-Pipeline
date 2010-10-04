use Log::Log4perl qw/:easy/;
use Test::More;

BEGIN { use_ok( 'ETL::Extract::FromFile' ); }
require_ok( 'ETL::Extract::FromFile' );


# Prevent bogus warning messages in the tests.
Log::Log4perl->easy_init( $ERROR );


# Test object creation - does it compile?
my $file = new_ok( 'ETL::Extract::FromFile' );


# Non-existent file...
ok( $file->input( 'test.txt' ) == 0, 'Cannot use a non-existent file'    );
is( $file->end_of_input, 1    , 'Failure marks end_of_input()'           );
is( $file->position    , 0    , 'Failure resets position()'              );
is( $file->extract     , undef, 'extract() returned undef with no input' );


done_testing();

