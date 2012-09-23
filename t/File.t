use Test::More;

BEGIN { use_ok( 'Data::ETL::Extract::DelimitedText' ); }
require_ok( 'Data::ETL::Extract::DelimitedText' );

subtest 'File search' => sub {
	my $file = new_ok( 'Data::ETL::Extract::DelimitedText' => [
		root      => 't',
		file_name => qr/\.txt$/i
	] );
	$file->setup;
	is( $file->path, 't/DelimitedText.txt', 'Search file name, with root' );
	$file->finished;

	$file = new_ok( 'Data::ETL::Extract::DelimitedText' => [
		folder_name => qr|^t$|i,
		file_name   => qr/\.txt$/i
	] );
	$file->setup;
	is( $file->path, 't/DelimitedText.txt', 'Search folder name, no root' );
	$file->finished;

	$file = new_ok( 'Data::ETL::Extract::DelimitedText' => [
		path => 't/DelimitedText.txt'
	] );
	$file->setup;
	is( $file->path, 't/DelimitedText.txt', 'Fixed path' );
	$file->finished;
};

subtest 'Increment record counter' => sub {
	my $file = new_ok( 'Data::ETL::Extract::DelimitedText' => [
		path => 't/DelimitedText.txt',
	] );
	$file->setup;
	is( $file->record_number, 0, 'Positioned at beginning of file' );

	ok( $file->next_record, 'Record loaded' );
	is( $file->record_number, 1, 'Counter incremented' );
};

subtest 'Header row' => sub {
	my $file = new_ok( 'Data::ETL::Extract::DelimitedText' => [
		path    => 't/DelimitedText.txt',
		headers => {
			qr/head(er)?1/i => 'first' ,
			qr/2/i          => 'second',
			qr/he.*3/i      => 'third' ,
			qr/4/i          => 'fourth',
			qr/5/i          => 'fifth' ,
		},
	] );
	$file->setup;
	is( $file->record_number, 1, 'Positioned at first data row' );

	is( scalar( @{$file->names     } ), 4, 'Field names set'   );
	is( scalar( @{$file->names->[0]} ), 1, 'first: only name'  );
	is( scalar( @{$file->names->[1]} ), 1, 'second: only name' );
	is( scalar( @{$file->names->[2]} ), 1, 'third: only name'  );
	is( scalar( @{$file->names->[3]} ), 1, 'fourth: only name' );
	is( $file->names->[0]->[0], 'first' , 'first: right name'  );
	is( $file->names->[1]->[0], 'second', 'second: right name' );
	is( $file->names->[2]->[0], 'third' , 'third: right name'  );
	is( $file->names->[3]->[0], 'fourth', 'fourth: right name' );

	ok( $file->next_record, 'Record loaded' );
	ok( defined $file->record, 'Record has data' );

	my @keys = keys %{$file->record};
	is( scalar( @keys )        , 9       , 'Numbers and names'      );
	is( $file->record->{0     }, 'Field1', 'Found Field1 by number' );
	is( $file->record->{1     }, 'Field2', 'Found Field2 by number' );
	is( $file->record->{2     }, 'Field3', 'Found Field3 by number' );
	is( $file->record->{3     }, 'Field4', 'Found Field4 by number' );
	is( $file->record->{4     }, 'Field5', 'Found Field5 by number' );
	is( $file->record->{first }, 'Field1', 'Found Field1 by name'   );
	is( $file->record->{second}, 'Field2', 'Found Field2 by name'   );
	is( $file->record->{third }, 'Field3', 'Found Field3 by name'   );
	is( $file->record->{fourth}, 'Field4', 'Found Field4 by name'   );

	$file->finished;
};

subtest 'Skip leading rows' => sub {
	my $file = new_ok( 'Data::ETL::Extract::DelimitedText' => [
		path => 't/DelimitedText.txt',
		skip => 2
	] );
	$file->setup;
	is( $file->record_number, 2, 'Skipped two rows' );
};

done_testing;
