use Data::ETL::Extract::DelimitedText;
use Test::More;

$file = new_ok( 'Data::ETL::Extract::DelimitedText' => [
	find_file   => qr/\.txt$/i,
	find_folder => qr|^FileListing$|i,
	search_in   => 't',
] );
$file->setup;
is( $file->root_folder, 't/FileListing', 'Search for a subfolder' );
$file->finished;
use feature qw/say/;

$file = new_ok( 'Data::ETL::Extract::DelimitedText' => [
	find_file   => qr/\.txt$/i,
	find_folder => qr|^t$|i,
] );
$file->setup;
is( $file->root_folder, 't', 'Search in the current directory' );
$file->finished;

$file = new_ok( 'Data::ETL::Extract::DelimitedText' => [
	find_file   => qr/\.txt$/i,
	root_folder => 't',
] );
$file->setup;
is( $file->root_folder, 't', 'Fixed root' );
$file->finished;

done_testing;
