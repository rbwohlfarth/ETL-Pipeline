use ETL::Pipeline;
use Test::More;


my $etl = ETL::Pipeline->new( {
	input   => [
		'DelimitedText',
		iname           => 'DelimitedText.txt',
		no_column_names => 1,
	],
	output  => 'UnitTest',
	work_in => 't/DataFiles',
} )->process;
ok( defined( $etl ), 'process' );
is( $etl->output->number_of_records, 2, 'All records processed' );

subtest 'First record' => sub {
	my $record = $etl->output->get_record( 0 );
	ok( defined( $record ), 'Record has data' );

	is( scalar( %$record ), 5, 'Five columns' );
	is( $record->{$_ - 1}, "Field$_", "Found Field$_" ) foreach (1 .. 5);
};

subtest 'Second record' => sub {
	my $record = $etl->output->get_record( 1 );
	ok( defined( $record ), 'Record has data' );

	is( scalar( %$record ), 5, 'Five columns' );
	is( $record->{$_ - 6}, "Field$_", "Found Field$_" ) foreach (6 .. 10);
};

done_testing;
