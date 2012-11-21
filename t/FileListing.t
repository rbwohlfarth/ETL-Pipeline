use Test::More;

BEGIN { use_ok( 'Data::ETL::Extract::FileListing' ); }
require_ok( 'Data::ETL::Extract::FileListing' );

subtest 'Dynamic folder search' => sub {
	my $file = new_ok( 'Data::ETL::Extract::FileListing' => [
		folder => qr/FileListing/,
		name   => qr/Test\s\d\.txt$/,
		root   => 't'
	] );
	$file->setup;

	subtest 'First match' => sub {
		ok( $file->next_record, 'Record loaded' );
		ok( defined $file->record, 'Record has data' );
		is  ( $file->record->{Extension}, 'txt'                              , 'Extension'     );
		like( $file->record->{File     }, qr/^Test\s\d\.txt$/                , 'File name'     );
		is  ( $file->record->{Inside   }, ''                                 , 'Inside folder' );
		like( $file->record->{Path     }, qr|^t\\FileListing\\Test\s\d\.txt$|, 'Full path'     );
		like( $file->record->{Relative }, qr|^Test\s\d\.txt$|                , 'Relative path' );
	};

	my $first = $file->record->{File};
	subtest 'Second match' => sub {
		ok( $file->next_record, 'Record loaded' );
		ok( defined $file->record, 'Record has data' );
		isnt( $file->record->{File}, $first, 'Different file' );
	};

	is( $file->next_record, 0, 'No more matches' );
	$file->finished;
};

subtest 'Hard coded search path' => sub {
	my $file = new_ok( 'Data::ETL::Extract::FileListing' => [path => 't/FileListing'] );
	$file->setup;
	subtest 'First match' => sub {
		ok( $file->next_record, 'Record loaded' );
		ok( defined $file->record, 'Record has data' );
	};
	subtest 'Second match' => sub {
		ok( $file->next_record, 'Record loaded' );
		ok( defined $file->record, 'Record has data' );
	};
	subtest 'Third match' => sub {
		ok( $file->next_record, 'Record loaded' );
		ok( defined $file->record, 'Record has data' );
	};
	is( $file->next_record, 0, 'No more matches' );
	$file->finished;
};

done_testing();
