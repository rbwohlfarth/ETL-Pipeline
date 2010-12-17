use Log::Log4perl qw/:easy/;
use Test::More;

# Prevent bogus warning messages in the tests.
Log::Log4perl->easy_init( $ERROR );


BEGIN { use_ok( 'ETL::Extract::FromFile::DelimitedText' ); }
require_ok( 'ETL::Extract::FromFile::DelimitedText' );

my $file = new_ok( 'ETL::Extract::FromFile::DelimitedText' => [
	path => 't/DelimitedText.txt',
] );

is( $file->end_of_input, 0, 'Not at the end_of_input()' );
is( $file->position    , 0, 'position() at first record' );

my $record = $file->extract;
isa_ok( $record, 'ETL::Record', 'extract() return value' );

my @keys = sort keys( %{$record->raw} );
is( scalar( @keys )  , 5       , 'Five columns of data'        );
is( $keys[0]         , 1       , '$record->raw->{1}'           );
is( $keys[1]         , 2       , '$record->raw->{2}'           );
is( $keys[2]         , 3       , '$record->raw->{3}'           );
is( $keys[3]         , 4       , '$record->raw->{4}'           );
is( $keys[4]         , 5       , '$record->raw->{5}'           );
is( $file->position  , 1       , 'position == row number'      );
is( $record->raw->{1}, 'Field1', '$record->raw->{1} == Field1' );
is( $record->raw->{2}, 'Field2', '$record->raw->{2} == Field2' );
is( $record->raw->{3}, 'Field3', '$record->raw->{3} == Field3' );
is( $record->raw->{4}, 'Field4', '$record->raw->{4} == Field4' );
is( $record->raw->{5}, 'Field5', '$record->raw->{5} == Field5' );

$record = $file->extract;
is( $file->extract, undef, 'No record at the end of file' );
ok( $file->end_of_input, 'End of input flag set' );

$file = new_ok( 'ETL::Extract::FromFile::DelimitedText' => [
	headers => 1,
	path    => 't/DelimitedText.txt',
] );
$record = $file->extract;
is( $file->position  , 2       , 'header row skipped'          );
is( $record->raw->{1}, 'Field6', '$record->raw->{1} == Field6' );
is( $record->raw->{2}, 'Field7', '$record->raw->{2} == Field7' );
is( $record->raw->{3}, 'Field8', '$record->raw->{3} == Field8' );
is( $record->raw->{4}, 'Field9', '$record->raw->{4} == Field9' );
is( $record->raw->{5}, 'Field0', '$record->raw->{5} == Field0' );


done_testing();
