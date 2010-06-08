use Log::Log4perl qw/:easy/;
use Test::More;

BEGIN { use_ok( 'RawData::File' ); }
require_ok( 'RawData::File' );


# Prevent bogus warning messages in the tests.
Log::Log4perl->easy_init( $ERROR );


# Test object creation - does it compile?
my $file = new_ok( 'RawData::File' );


# open()
is( $file->file( 'test.txt' ), 'test.txt', 'open()'        );
is( $file->end_of_file       , 1         , 'end_of_file()' );
is( $file->position          , 0         , 'position( 0 )' );


# read_one_record()
is( $file->read_one_record, undef, "read_one_record => undef" );


done_testing();

