use Test::More;


BEGIN { use_ok( 'Data::ETL' ); }
require_ok( 'Data::ETL' );

ok( defined &extract_from  , 'extract_from command exported'   );
ok( defined &transform_as  , 'transform_as command exported'   );
ok( defined &set           , 'set command exported'            );
ok( defined &load_into     , 'load_into command exported'      );
ok( defined &run           , 'run command exported'            );
ok( defined &source_folder , 'source_folder command exported'  );
ok( defined &working_folder, 'working_folder command exported' );

use Data::ETL::Load::UnitTest;
subtest 'Sample ETL script' => sub {
	working_folder 't';
	extract_from 'UnitTest';
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
	is( $Data::ETL::SourceFolder, 't', 'Set source_folder too' );

	working_folder search_in => 't', find_folder => qr|^DataFiles$|i;
	is( $Data::ETL::WorkingFolder, 't/DataFiles', 'Search for a subfolder' );

	working_folder find_folder => '*', search_in => 't/DataFiles';
	is( $Data::ETL::WorkingFolder, 't/DataFiles/FileListing', 'Alphabetical order' );

	working_folder find_folder => qr|^t$|i;
	is( $Data::ETL::WorkingFolder, 't', 'Search in the current directory' );
};

subtest '"source_folder" command' => sub {
	working_folder 't';

	source_folder 'DataFiles';
	is( $Data::ETL::SourceFolder, 't/DataFiles', 'Fixed root' );

	source_folder qr|^DataFiles$|i;
	is( $Data::ETL::SourceFolder, 't/DataFiles', 'Search for a subfolder' );
};

subtest 'Use modules from a different namespace' => sub {
	unshift @INC, './t';

	my $result = extract_from module => 'MyTestExtract';
	ok( defined( $result ), 'Data::ETL::extract set' );

	$result = load_into module => 'MyTestLoad', option => 1;
	ok( defined( $result ), 'Data::ETL::load set' );
};


done_testing();
