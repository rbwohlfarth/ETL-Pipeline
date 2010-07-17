use Log::Log4perl qw/:easy/;
use RawData::Parser::DelimitedText;
use Test::More;

BEGIN { use_ok( 'RawData::File' ); }
require_ok( 'RawData::File' );


# Prevent bogus warning messages in the tests.
Log::Log4perl->easy_init( $ERROR );


# Test object creation - does it compile?
my $file = new_ok( 'RawData::File' => [
	parser => new RawData::Parser::DelimitedText(
		file => 't/DelimitedText.txt',
	),
	primary_key_field => 1,
] );


# Two records
$file->load;
is_deeply( 
	[keys %{$file->records}], 
	[qw/Field1 Field6/], 
	'Two records loaded'
);


# One header
$file = new RawData::File(
	header_rows => 1,
	parser      => new RawData::Parser::DelimitedText(
		file => 't/DelimitedText.txt',
	),
	primary_key_field => 1,
);
$file->load;
is_deeply( 
	[keys %{$file->records}], 
	[qw/Field6/], 
	'One header skipped'
);


# No identifiers
$file = new RawData::File(
	parser      => new RawData::Parser::DelimitedText(
		file => 't/DelimitedText.txt',
	),
	primary_key_field => 100,
);
$file->load;
is( scalar @{$file->no_id}, 2, 'No identifiers' );


done_testing();

