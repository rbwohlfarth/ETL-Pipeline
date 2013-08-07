use Data::ETL;
use Test::More;

working_folder 't/DataFiles';

BEGIN { use_ok( 'Data::ETL::Extract::FileListing' ); }
require_ok( 'Data::ETL::Extract::FileListing' );

subtest 'Dynamic folder search' => sub {
	my $file = new_ok( 'Data::ETL::Extract::FileListing' => [
		files_in  => qr/FileListing/,
		find_file => qr/Test\s\d\.txt$/,
	] );
	$file->setup;

	subtest 'First match' => sub {
		ok( $file->next_record, 'Record loaded' );
		ok( defined $file->record, 'Record has data' );
		is  ( $file->get( 'Extension' ), 'txt'              , 'Extension'     );
		like( $file->get( 'File'      ), qr/^Test\s\d\.txt$/, 'File name'     );
		is  ( $file->get( 'Inside'    ), ''                 , 'Inside folder' );
		like( $file->get( 'Path'      ), qr|^t\\DataFiles\\FileListing\\Test\s\d\.txt$|, 'Full path' );
		like( $file->get( 'Relative'  ), qr|^Test\s\d\.txt$|, 'Relative path' );
	};

	my $first = $file->record->{File};
	subtest 'Second match' => sub {
		ok( $file->next_record, 'Record loaded' );
		ok( defined $file->record, 'Record has data' );
		isnt( $file->get( 'File' ), $first, 'Different file' );
	};

	is( $file->next_record, 0, 'No more matches' );
	$file->finished;
};

subtest 'Hard coded search path' => sub {
	my $file = new_ok( 'Data::ETL::Extract::FileListing' => [
		path => 't/DataFiles/FileListing',
	] );
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

subtest 'Depth controls' => sub {
	my $file = new_ok( 'Data::ETL::Extract::FileListing' => [
		max_depth => 2,
		min_depth => 2,
		path      => 't/DataFiles/FileListingDepth',
	] );
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
