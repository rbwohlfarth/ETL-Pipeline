use Test::More 'no_plan';

use Log::Log4perl qw/:easy/;
use RawData::File;


# Prevent bogus warning messages in the tests.
Log::Log4perl->easy_init( $ERROR );

# Test object creation - does it compile?
my $file = new RawData::File;
ok( defined $file                , 'Object exists'              );
ok( $file->isa( 'RawData::File' ), 'Object is the correct type' );

# open()
is( $file->file( 'test.txt' ), 'test.txt', 'open()'        );
is( $file->end_of_file       , 1         , 'end_of_file()' );
is( $file->position          , 0         , 'position( 0 )' );

# read_one_record()
is( $file->read_one_record, undef, "read_one_record => undef" );

