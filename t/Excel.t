use Test::More;

BEGIN { use_ok( 'Data::ETL::Extract::Excel' ); }
require_ok( 'Data::ETL::Extract::Excel' );

subtest 'XLSX format' => sub {
	my $file = new_ok( 'Data::ETL::Extract::Excel' => [
		has_header_row => 0,
		path           => 't/Excel2007.xlsx',
	] );
	$file->setup;

	subtest 'Columns list' => sub {
		is( scalar( @{$file->columns} ), 5, 'Five columns in the worksheet' );
		is( $file->columns->[0]        , 0, 'Number 0 = first'              );
		is( $file->columns->[1]        , 1, 'Number 1 = second'             );
		is( $file->columns->[2]        , 2, 'Number 2 = third'              );
		is( $file->columns->[3]        , 3, 'Number 3 = fourth'             );
		is( $file->columns->[4]        , 4, 'Number 4 = fifth'              );
	};

	subtest 'First record' => sub {
		ok( $file->next_record, 'Record loaded' );
		ok( defined $file->record, 'Record has data' );

		is( $file->get( 'A' ), 'Header1', 'Found Header1 by letter' );
		is( $file->get( 'B' ), 'Header2', 'Found Header2 by letter' );
		is( $file->get( 'C' ), 'Header3', 'Found Header3 by letter' );
		is( $file->get( 'D' ), 'Header4', 'Found Header4 by letter' );
		is( $file->get( 'E' ), 'Header5', 'Found Header5 by letter' );
	};
	
	subtest 'Second record' => sub {
		ok( $file->next_record, 'Record loaded' );
		ok( defined $file->record, 'Record has data' );

		is( $file->get( 0 ), 'Field1', 'Found Field1' );
		is( $file->get( 1 ), 'Field2', 'Found Field2' );
		is( $file->get( 2 ), 'Field3', 'Found Field3' );
		is( $file->get( 3 ), 'Field4', 'Found Field4' );
		is( $file->get( 4 ), 'Field5', 'Found Field5' );
	};
	
	is( $file->next_record, 0, 'End of file reached' );

	$file->finished;
};

subtest 'XLS format' => sub {
	my $file = new_ok( 'Data::ETL::Extract::Excel' => [
		has_header_row => 0,
		path           => 't/Excel2003.xls',
	] );
	$file->setup;

	subtest 'Columns list' => sub {
		is( scalar( @{$file->columns} ), 5, 'Five columns in the worksheet' );
		is( $file->columns->[0]        , 0, 'Number 0 = first'              );
		is( $file->columns->[1]        , 1, 'Number 1 = second'             );
		is( $file->columns->[2]        , 2, 'Number 2 = third'              );
		is( $file->columns->[3]        , 3, 'Number 3 = fourth'             );
		is( $file->columns->[4]        , 4, 'Number 4 = fifth'              );
	};

	subtest 'First record' => sub {
		ok( $file->next_record, 'Record loaded' );
		ok( defined $file->record, 'Record has data' );

		is( $file->get( 'A' ), 'Header1', 'Found Header1 by letter' );
		is( $file->get( 'B' ), 'Header2', 'Found Header2 by letter' );
		is( $file->get( 'C' ), 'Header3', 'Found Header3 by letter' );
		is( $file->get( 'D' ), 'Header4', 'Found Header4 by letter' );
		is( $file->get( 'E' ), 'Header5', 'Found Header5 by letter' );
	};
	
	subtest 'Second record' => sub {
		ok( $file->next_record, 'Record loaded' );
		ok( defined $file->record, 'Record has data' );

		is( $file->get( 0 ), 'Field1', 'Found Field1' );
		is( $file->get( 1 ), 'Field2', 'Found Field2' );
		is( $file->get( 2 ), 'Field3', 'Found Field3' );
		is( $file->get( 3 ), 'Field4', 'Found Field4' );
		is( $file->get( 4 ), 'Field5', 'Found Field5' );
	};
	
	is( $file->next_record, 0, 'End of file reached' );

	$file->finished;
};

subtest 'Skip blank rows' => sub {
	my $file = new_ok( 'Data::ETL::Extract::Excel' => [
		has_header_row => 0,
		path           => 't/Excel2007-Skip.xlsx',
		skip           => 1,
	] );
	$file->setup;

	ok( $file->next_record, 'Record loaded' );
	ok( defined $file->record, 'Record has data' );
	is( $file->get( 'A' ), 'Header1', 'First data row' );

	$file->finished;
};

subtest 'Skip page header ending with blank rows' => sub {
	my $file = new_ok( 'Data::ETL::Extract::Excel' => [
		has_header_row => 0,
		path           => 't/Excel2007-Skip.xlsx',
		skip           => 2,
	] );
	$file->setup;

	ok( $file->next_record, 'Record loaded' );
	ok( defined $file->record, 'Record has data' );
	is( $file->get( 'A' ), 'Header1', 'First data row' );

	$file->finished;
};

done_testing();
