use Test::More;

BEGIN { use_ok( 'Data::ETL::Extract::Excel' ); }
require_ok( 'Data::ETL::Extract::Excel' );

subtest 'XLSX format' => sub {
	my $file = new_ok( 'Data::ETL::Extract::Excel' => [
		path => 't/Excel2007.xlsx',
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

		my @keys = keys %{$file->record};
		is( scalar( @keys )   , 10       , 'Numbers and letters'     );
		is( $file->record->{0}, 'Header1', 'Found Header1'           );
		is( $file->record->{1}, 'Header2', 'Found Header2'           );
		is( $file->record->{2}, 'Header3', 'Found Header3'           );
		is( $file->record->{3}, 'Header4', 'Found Header4'           );
		is( $file->record->{4}, 'Header5', 'Found Header5'           );
		is( $file->record->{A}, 'Header1', 'Found Header1 by letter' );
		is( $file->record->{B}, 'Header2', 'Found Header2 by letter' );
		is( $file->record->{C}, 'Header3', 'Found Header3 by letter' );
		is( $file->record->{D}, 'Header4', 'Found Header4 by letter' );
		is( $file->record->{E}, 'Header5', 'Found Header5 by letter' );
	};
	subtest 'Second record' => sub {
		ok( $file->next_record, 'Record loaded' );
		ok( defined $file->record, 'Record has data' );

		is( $file->record->{0}, 'Field1', 'Found Field1' );
		is( $file->record->{1}, 'Field2', 'Found Field2' );
		is( $file->record->{2}, 'Field3', 'Found Field3' );
		is( $file->record->{3}, 'Field4', 'Found Field4' );
		is( $file->record->{4}, 'Field5', 'Found Field5' );
	};
	is( $file->next_record, 0, 'End of file reached' );

	$file->finished;
};

subtest 'XLS format' => sub {
	my $file = new_ok( 'Data::ETL::Extract::Excel' => [
		path => 't/Excel2003.xls',
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

		my @keys = keys %{$file->record};
		is( scalar( @keys )   , 10       , 'Numbers and letters'    );
		is( $file->record->{0}, 'Header1', 'Found Header1'           );
		is( $file->record->{1}, 'Header2', 'Found Header2'           );
		is( $file->record->{2}, 'Header3', 'Found Header3'           );
		is( $file->record->{3}, 'Header4', 'Found Header4'           );
		is( $file->record->{4}, 'Header5', 'Found Header5'           );
		is( $file->record->{A}, 'Header1', 'Found Header1 by letter' );
		is( $file->record->{B}, 'Header2', 'Found Header2 by letter' );
		is( $file->record->{C}, 'Header3', 'Found Header3 by letter' );
		is( $file->record->{D}, 'Header4', 'Found Header4 by letter' );
		is( $file->record->{E}, 'Header5', 'Found Header5 by letter' );
	};
	subtest 'Second record' => sub {
		ok( $file->next_record, 'Record loaded' );
		ok( defined $file->record, 'Record has data' );

		is( $file->record->{0}, 'Field1', 'Found Field1' );
		is( $file->record->{1}, 'Field2', 'Found Field2' );
		is( $file->record->{2}, 'Field3', 'Found Field3' );
		is( $file->record->{3}, 'Field4', 'Found Field4' );
		is( $file->record->{4}, 'Field5', 'Found Field5' );
	};
	is( $file->next_record, 0, 'End of file reached' );

	$file->finished;
};

done_testing();
