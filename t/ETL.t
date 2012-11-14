use Test::More;

BEGIN { use_ok( 'Data::ETL' ); }
require_ok( 'Data::ETL' );

ok( defined &extract_using, 'extract_using command exported' );
ok( defined &transform_as , 'transform_as command exported'  );
ok( defined &set          , 'set command exported'           );
ok( defined &load_into    , 'load_into command exported'     );
ok( defined &run          , 'run command exported'           );

use Data::ETL::Load::UnitTest;
subtest 'Sample ETL script' => sub {
	extract_using 'DelimitedText', path => 't/DelimitedText.txt';
	set constant => 'String literal';
	transform_as un => 0, deux => 1, trois => 2;
	load_into 'UnitTest';
	run;

	is( scalar( @Data::ETL::Load::UnitTest::storage ), 3, 'Three records' );
	subtest 'First record' => sub {
		my $record = shift @Data::ETL::Load::UnitTest::storage;
		my @keys   = keys %$record;
		is( scalar( @keys )    , 4               , '4 fields'       );
		is( $record->{un      }, 'Header1'       , 'Found Header1'  );
		is( $record->{deux    }, 'Header2'       , 'Found Header2'  );
		is( $record->{trois   }, 'Header3'       , 'Found Header3'  );
		is( $record->{constant}, 'String literal', 'Found constant' );
	};
	subtest 'Second record' => sub {
		my $record = shift @Data::ETL::Load::UnitTest::storage;
		my @keys   = keys %$record;
		is( scalar( @keys )    , 4               , '4 fields'       );
		is( $record->{un      }, 'Field1'        , 'Found Field1'   );
		is( $record->{deux    }, 'Field2'        , 'Found Field2'   );
		is( $record->{trois   }, 'Field3'        , 'Found Field3'   );
		is( $record->{constant}, 'String literal', 'Found constant' );
	};
};

subtest '"run" command clears the settings' => sub {
	is( scalar( keys %ETL::constants ), 0    , 'Cleared ETL::constants' );
	is( scalar( keys %ETL::mapping   ), 0    , 'Cleared ETL::mapping'   );
	is( $ETL::extract                 , undef, 'Cleared ETL::extract'   );
	is( $ETL::load                    , undef, 'Cleared ETL::load'      );
};

done_testing();
