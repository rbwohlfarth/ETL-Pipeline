use ETL::Pipeline;
use Test::More;

my $etl = ETL::Pipeline->new( {input => 'UnitTest'} );
ok( defined( $etl->input ), 'Object created' );

$etl->input->configure;
pass( 'configure' );

is( $etl->input->record_number, 0, 'No records loaded' );
$etl->input->next_record;
is( $etl->input->record_number, 1, 'Record count incremented' );

done_testing;
