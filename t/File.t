use Data::ETL;
use Data::ETL::Extract::DelimitedText;
use Test::More;

working_folder 't';

my $file = new_ok( 'Data::ETL::Extract::DelimitedText' => [
	find_file => qr/\.txt$/i,
] );
$file->setup;
is( $file->path, 't/DelimitedText.txt', 'Search for file name' );
$file->finished;

$file = new_ok( 'Data::ETL::Extract::DelimitedText' => [
	path => 't/DelimitedText.txt',
] );
$file->setup;
is( $file->path, 't/DelimitedText.txt', 'Fixed path' );
$file->finished;

$file->path( undef );
pass( 'No file found' );

done_testing;
