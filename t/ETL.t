use Test::More;

BEGIN { use_ok( 'Data::ETL' ); }
require_ok( 'Data::ETL' );

ok( defined &extract_from  , 'extract_from command exported'   );
ok( defined &transform_as  , 'transform_as command exported'   );
ok( defined &set           , 'set command exported'            );
ok( defined &load_into     , 'load_into command exported'      );
ok( defined &run           , 'run command exported'            );
ok( defined &working_folder, 'working_folder command exported' );
ok( defined &skip_if       , 'skip_if command exported'        );

use Data::ETL::Load::UnitTest;
subtest 'Sample ETL script' => sub {
	working_folder 't';
	extract_from 'DelimitedText', path => 't/DelimitedText.txt';
	set constant => 'String literal';
	transform_as un => 0, deux => 1, trois => 2;
	load_into 'UnitTest';
	run;

	pass( 'Basic settings are okay' );
	
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
	is( scalar( keys %Data::ETL::constants ), 0    , 'Cleared Data::ETL::constants' );
	is( scalar( keys %Data::ETL::mapping   ), 0    , 'Cleared Data::ETL::mapping'   );
	is( $Data::ETL::extract                 , undef, 'Cleared Data::ETL::extract'   );
	is( $Data::ETL::load                    , undef, 'Cleared Data::ETL::load'      );
};

subtest '"working_folder" command' => sub {
	working_folder 't';
	is( $Data::ETL::WorkingFolder, 't', 'Fixed root' );

	working_folder search_in => 't', find_folder => qr|^FileListing$|i;
	is( $Data::ETL::WorkingFolder, 't/FileListing', 'Search for a subfolder' );

	working_folder find_folder => qr|^t$|i;
	is( $Data::ETL::WorkingFolder, 't', 'Search in the current directory' );
};

subtest '"skip_if" command' => sub {
	skip_if sub { 1 };
	pass( 'skip_if sets code ref' );
};

done_testing();
