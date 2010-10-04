use Log::Log4perl qw/:easy/;
use Test::More;

BEGIN { use_ok( 'ETL::Extract::FromFile::Excel::2007' ); }
require_ok( 'ETL::Extract::FromFile::Excel::2007' );


# Prevent bogus warning messages in the tests.
Log::Log4perl->easy_init( $ERROR );


# Test object creation - does it compile?
my $file = new_ok( 'ETL::Extract::FromFile::Excel::2007' );


# connect()
ok( $file->input( 't/Excel2007.xlsx' ), 'Opening the file' );
is( $file->end_of_input, 0, 'Not at the end_of_input()' );
is( $file->position    , 0, 'position() at first record'  );


# extract()
my $record = $file->extract;
isa_ok( $record, 'ETL::Extract::Record', 'extract() return value' ); 

my @keys = sort keys( %{$record->data} );
is( scalar( @keys )     , 5       , 'Three columns of data'        );
is( $keys[0]            , 'A'     , '$record->data->{A}'           );
is( $keys[1]            , 'B'     , '$record->data->{B}'           );
is( $keys[2]            , 'C'     , '$record->data->{C}'           );
is( $keys[3]            , 'D'     , '$record->data->{D}'           );
is( $keys[4]            , 'E'     , '$record->data->{E}'           );
is( $file->position     , 1       , 'position == row number'       );
is( $record->data->{'A'}, 'Field1', '$record->data->{A} == Field1' );
is( $record->data->{'B'}, 'Field2', '$record->data->{B} == Field2' );
is( $record->data->{'C'}, 'Field3', '$record->data->{C} == Field3' );
is( $record->data->{'D'}, 'Field4', '$record->data->{D} == Field4' );
is( $record->data->{'E'}, 'Field5', '$record->data->{E} == Field5' );


done_testing();

