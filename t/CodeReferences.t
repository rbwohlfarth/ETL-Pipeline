use Test::More;

BEGIN { use_ok( 'Data::ETL' ); }
require_ok( 'Data::ETL' );

use Data::ETL::Load::UnitTest;

extract_using 'DelimitedText', path => 't/DelimitedText.txt';
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
