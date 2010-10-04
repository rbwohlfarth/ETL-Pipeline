use Log::Log4perl qw/:easy/;
use ETL::Extract::FromFile::DelimitedText;
use Test::More;

BEGIN { use_ok( 'ETL::Extract::ToMemory' ); }
require_ok( 'ETL::Extract::ToMemory' );


# Prevent bogus warning messages in the tests.
Log::Log4perl->easy_init( $ERROR );


# Test object creation - does it compile?
my $file = new_ok( 'ETL::Extract::ToMemory' => [
	parser      => new ETL::Extract::FromFile::DelimitedText,
	primary_key => 1,
] );


# See if these crash.
ok( $file->input( 't/DelimitedText.txt' ), 'Opened the file' );
$file->load;


done_testing;

