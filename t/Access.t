use Log::Log4perl qw/:easy/;
use DBI qw/:sql_types/;
use ETL::Load::Access;
use ETL::Record;
use Test::More;

# Prevent bogus warning messages in the tests.
Log::Log4perl->easy_init( $ERROR );


BEGIN { use_ok( 'ETL::Load::Access' ); }
require_ok( 'ETL::Load::Access' );

my $output = new_ok( 'ETL::Load::Access' );
$output->destination( 't/Access.accdb' );
$output->table( 'Data' );
$output->fields->{Stuff} = SQL_VARCHAR;

my $record = ETL::Record->new;
$record->fields->{Stuff} = 'abcdefghijk ' . localtime;
is( $output->load( $record ), '', 'Record added to the database' );


done_testing;
