use Data::ETL::Extract::UnitTest;
use Data::ETL::Load::UnitTest;
use Test::More;


my $extract = Data::ETL::Extract::UnitTest->new();
my $load = new_ok( 'Data::ETL::Load::UnitTest' );
$load->setup( $extract );
ok( defined( $load->extract ), '"extract" attribute set' );

done_testing;
