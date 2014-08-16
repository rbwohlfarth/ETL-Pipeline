use Data::ETL;
use Data::ETL::Extract::UnitTest;
use Test::More;

working_folder 't';

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
