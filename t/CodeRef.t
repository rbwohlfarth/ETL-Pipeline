use Test::More;

BEGIN { use_ok( 'Data::ETL::CodeRef' ); }
require_ok( 'Data::ETL::CodeRef' );

my $x = 0;
Data::ETL::CodeRef::run( sub { $x = $_ }, 2 );
is( $x, 2, '$_ set' );

Data::ETL::CodeRef::run( sub { $x = shift }, 3 );
is( $x, 3, 'Parameters passed' );

ok( Data::ETL::CodeRef::run( sub { 1 } ), 'No parameters' );
is( Data::ETL::CodeRef::run( sub { 4 } ), 4, 'Return value' );
is( Data::ETL::CodeRef::run( 'abc' ), undef, 'Not a code reference' );


use Data::ETL;
use Data::ETL::Load::UnitTest;

working_folder 't';
extract_from 'UnitTest';
set constant => sub { 'String literal' };
transform_as un => sub { $_->get( 0 ) };
load_into 'UnitTest';
run;

subtest 'First record' => sub {
	my $record = shift @Data::ETL::Load::UnitTest::storage;
	is( $record->{un      }, 'Header1'       , 'Found Header1'  );
	is( $record->{constant}, 'String literal', 'Found constant' );
};
subtest 'Second record' => sub {
	my $record = shift @Data::ETL::Load::UnitTest::storage;
	is( $record->{un      }, 'Field1'        , 'Found Field1'   );
	is( $record->{constant}, 'String literal', 'Found constant' );
};

done_testing();
