use Log::Log4perl qw/:easy/;
use ETL::Extract::FromFile::DelimitedText;
use Test::More;

# Prevent bogus warning messages in the tests.
Log::Log4perl->easy_init( $ERROR );


BEGIN { use_ok( 'ETL::Extract::ToMemory' ); }
require_ok( 'ETL::Extract::ToMemory' );

# Test object creation - does it compile?
my $file = new_ok( 'ETL::Extract::ToMemory' => [
	parser => new ETL::Extract::FromFile::DelimitedText(
		path => 't/DelimitedText.txt',
	),
	primary_key => 1,
] );

# See if these crash.
$file->slurp;
is( scalar( keys %{$file->records} ), 2, 'slurp() all records' );


done_testing;
