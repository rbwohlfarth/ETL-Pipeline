use Data::ETL;
use Path::Class;
use Test::More;

my $root = dir( qw/t DataFiles/ );
my $from = $root->subdir( 'FileListing' );

working_folder "$root";

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
		is  ( $file->get( 'Inside'    ), '.'                , 'Inside folder' );
		like( $file->get( 'Relative'  ), qr|^Test\s\d\.txt$|, 'Relative path' );
		subtest 'Full path' => sub {
			my $path = file( $file->get( 'Path' ) );
			ok( $path->parent->subsumes( $from ), 'Correct directory' );
			like( $path->basename, qr/^Test\s\d\.txt$/, 'Correct file' );
		};
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
		path => "$from",
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
		path      => $root->subdir( 'FileListingDepth' )->stringify,
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
