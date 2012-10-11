use Test::More;
use Data::ETL::Extract::DelimitedText;

my $file = new_ok( 'Data::ETL::Extract::DelimitedText' => [
	root      => 't',
	file_name => qr/\.txt$/i
] );
$file->setup;
is( $file->path, 't/DelimitedText.txt', 'Search file name, with root' );
$file->finished;

$file = new_ok( 'Data::ETL::Extract::DelimitedText' => [
	folder_name => qr|^t$|i,
	file_name   => qr/\.txt$/i
] );
$file->setup;
is( $file->path, 't/DelimitedText.txt', 'Search folder name, no root' );
$file->finished;

$file = new_ok( 'Data::ETL::Extract::DelimitedText' => [
	path => 't/DelimitedText.txt'
] );
$file->setup;
is( $file->path, 't/DelimitedText.txt', 'Fixed path' );
$file->finished;

done_testing;
