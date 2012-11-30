use Test::More;
use Data::ETL::Extract::DelimitedText;

my $file = new_ok( 'Data::ETL::Extract::DelimitedText' => [
	find_file   => qr/\.txt$/i,
	root_folder => 't',
] );
$file->setup;
is( $file->path, 't/DelimitedText.txt', 'Search for file name' );
$file->finished;

$file = new_ok( 'Data::ETL::Extract::DelimitedText' => [
	path        => 't/DelimitedText.txt',
	root_folder => 't',
] );
$file->setup;
is( $file->path, 't/DelimitedText.txt', 'Fixed path' );
$file->finished;

done_testing;
