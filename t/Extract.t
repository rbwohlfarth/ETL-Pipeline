use Data::ETL;
use Data::ETL::Extract::UnitTest;
use Test::More;

working_folder 't';

subtest 'Increment record counter' => sub {
	my $file = new_ok( 'Data::ETL::Extract::UnitTest' );
	$file->setup;
	is( $file->record_number, 0, 'Positioned at beginning of file' );

	ok( $file->next_record, 'Record loaded' );
	is( $file->record_number, 1, 'Counter incremented' );
};

subtest 'Stop processing' => sub {
	my $file = new_ok( 'Data::ETL::Extract::UnitTest' => [
		stop_if => sub { shift->get( 0 ) eq 'Field1' },
	] );
	$file->setup;

	ok( $file->next_record, 'Header row loaded' );
	is( $file->next_record, 0, 'Stopped at data row' );
};

subtest 'Skip records' => sub {
	working_folder 't';
	extract_from 'UnitTest', bypass_if => sub { $_->get( 0 ) eq 'Field1' };
	transform_as un => 0, deux => 1, trois => 2;
	load_into 'UnitTest';
	run;

	is( scalar( @Data::ETL::Load::UnitTest::storage ), 2, 'Two records' );

	my $record = shift @Data::ETL::Load::UnitTest::storage;
	is( $record->{un}, 'Header1', 'Header row found' );

	$record = shift @Data::ETL::Load::UnitTest::storage;
	is( $record->{un}, 'Field6', 'Skipped first row' );
};

subtest 'Standard data filter' => sub {
	my $file = new_ok( 'Data::ETL::Extract::UnitTest' );
	$file->setup;

	ok( $file->next_record, 'Header row loaded' );
	is( $file->get( 3 ), 'Header4', 'Spaces trimmed value' );
};

subtest 'Custom data filter' => sub {
	my $file = new_ok( 'Data::ETL::Extract::UnitTest' => [
		filter => sub { y/a//d; $_ }
	] );
	$file->setup;

	ok( $file->next_record, 'Header row loaded' );
	is( $file->get( 0 ), 'Heder1', 'Filtered value' );
};

done_testing;
