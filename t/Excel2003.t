use Test::More 'no_plan';

use Log::Log4perl qw/:easy/;
use RawData::Excel2003;


# Prevent bogus warning messages in the tests.
Log::Log4perl->easy_init( $ERROR );

# Test object creation - does it compile?
my $file = new RawData::Excel2003;
ok( defined $file                     , 'Object exists'              );
ok( $file->isa( 'RawData::Excel2003' ), 'Object is the correct type' );

# open()
is( $file->file( 't/Excel2003.xls' ), 't/Excel2003.xls', 'open()'        );
is( $file->end_of_file              , 0                , 'end_of_file()' );
is( $file->position                 , 0                , 'position == 0' );

# read_one_record()
my $record = $file->read_one_record;
ok( defined $record                  , 'read_one_record => object'          );
ok( $record->isa( 'RawData::Record' ), 'read_one_record => RawData::Record' );

my @keys = sort keys( %{$record->data} );
is( scalar( @keys )     , 3       , 'Three columns of data'        );
is( $keys[0]            , 'A'     , '$record->data->{A}'           );
is( $keys[1]            , 'B'     , '$record->data->{B}'           );
is( $keys[2]            , 'C'     , '$record->data->{C}'           );
is( $file->position     , 1       , 'position == row number'       );
is( $record->data->{'A'}, 'Field1', '$record->data->{A} == Field1' );
is( $record->data->{'B'}, 'Field2', '$record->data->{B} == Field2' );
is( $record->data->{'C'}, 'Field3', '$record->data->{C} == Field3' );

