use Log::Log4perl qw/:easy/;
use Test::More;

BEGIN { use_ok( 'ETL::Extract::FromFile::DelimitedText' ); }
require_ok( 'ETL::Extract::FromFile::DelimitedText' );


# Prevent bogus warning messages in the tests.
Log::Log4perl->easy_init( $ERROR );


# Test object creation - does it compile?
my $file = new_ok( 'ETL::Extract::FromFile::DelimitedText' );


# open()
ok( $file->connect( 't/DelimitedText.txt' ), 'open()' );
is( $file->end_of_input, 0, 'end_of_input()' );
is( $file->position    , 0, 'position == 0' );


# read_one_record()
my $record = $file->extract;
ok( defined $record, 'extract => object' );
ok( 
	$record->isa( 'ETL::Extract::Record' ), 
	'extract => ETL::Extract::Record'
);

my @keys = sort keys( %{$record->data} );
is( scalar( @keys )   , 5       , 'Five columns of data'         );
is( $keys[0]          , 1       , '$record->data->{1}'           );
is( $keys[1]          , 2       , '$record->data->{2}'           );
is( $keys[2]          , 3       , '$record->data->{3}'           );
is( $keys[3]          , 4       , '$record->data->{4}'           );
is( $keys[4]          , 5       , '$record->data->{5}'           );
is( $file->position   , 1       , 'position == row number'       );
is( $record->data->{1}, 'Field1', '$record->data->{1} == Field1' );
is( $record->data->{2}, 'Field2', '$record->data->{2} == Field2' );
is( $record->data->{3}, 'Field3', '$record->data->{3} == Field3' );
is( $record->data->{4}, 'Field4', '$record->data->{4} == Field4' );
is( $record->data->{5}, 'Field5', '$record->data->{5} == Field5' );


# end_of_file()
$record = $file->extract;
is( $file->extract, undef, 'No record at the end of file' );
ok( $file->end_of_input, 'End of input flag' );

done_testing();

