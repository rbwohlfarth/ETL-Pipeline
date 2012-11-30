use Test::More;
use Data::ETL::Extract::DelimitedText;

subtest 'Increment record counter' => sub {
	my $file = Data::ETL::Extract::DelimitedText->new( 
		path        => 't/DelimitedText.txt',
		root_folder => 't',
	);
	$file->setup;
	is( $file->record_number, 0, 'Positioned at beginning of file' );

	ok( $file->next_record, 'Record loaded' );
	is( $file->record_number, 1, 'Counter incremented' );
};

subtest 'Skip leading rows' => sub {
	my $file = new_ok( 'Data::ETL::Extract::DelimitedText' => [
		path        => 't/DelimitedText.txt',
		root_folder => 't',
		skip        => 2,
	] );
	$file->setup;
	is( $file->record_number, 2, 'Skipped two rows' );
};

subtest 'Stop processing' => sub {
	my $file = new_ok( 'Data::ETL::Extract::DelimitedText' => [
		path        => 't/DelimitedText.txt',
		root_folder => 't',
		stop_when   => sub { shift->get( 0 ) eq 'Field1' },
	] );
	$file->setup;

	ok( $file->next_record, 'Header row loaded' );
	is( $file->next_record, 0, 'Stopped at data row' );
};

done_testing;
