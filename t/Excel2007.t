use Log::Log4perl qw/:easy/;
use Test::More;

# Prevent bogus warning messages in the tests.
Log::Log4perl->easy_init( $ERROR );


BEGIN { use_ok( 'ETL::Extract::File::Excel::2007' ); }
require_ok( 'ETL::Extract::File::Excel::2007' );

my $file = new_ok( 'ETL::Extract::File::Excel::2007' => [
	source => 't/Excel2007.xlsx',
] );

is( $file->end_of_input, 0, 'Not at the end_of_input()' );
is( $file->position    , 0, 'position() at first record'  );

my $record = $file->extract;
isa_ok( $record, 'ETL::Record', 'extract() return value' ); 

my @keys = sort keys( %{$record->raw} );
is( scalar( @keys )     , 5      , 'Three columns of data'       );
is( $keys[0]            , 'A'    , '$record->raw->{A}'           );
is( $keys[1]            , 'B'    , '$record->raw->{B}'           );
is( $keys[2]            , 'C'    , '$record->raw->{C}'           );
is( $keys[3]            , 'D'    , '$record->raw->{D}'           );
is( $keys[4]            , 'E'    , '$record->raw->{E}'           );
is( $file->position     , 1      , 'position == row number'      );
is( $record->raw->{'A'}, 'Field1', '$record->raw->{A} == Field1' );
is( $record->raw->{'B'}, 'Field2', '$record->raw->{B} == Field2' );
is( $record->raw->{'C'}, 'Field3', '$record->raw->{C} == Field3' );
is( $record->raw->{'D'}, 'Field4', '$record->raw->{D} == Field4' );
is( $record->raw->{'E'}, 'Field5', '$record->raw->{E} == Field5' );


done_testing();
