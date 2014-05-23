use Test::More;


use_ok( 'Data::ETL::Load::Hash' );

my %data;
my $load = new_ok( 'Data::ETL::Load::Hash' => [hash => \%data] );

sub fill_record {
	my $load                = shift     ;
	my $return_on_duplicate = shift // 1;

	$load->set( key   => 1   );
	$load->set( value => 'a' );
	is( $load->write_record, 1, 'First record saved' );
	$load->set( key   => 2   );
	$load->set( value => 'b' );
	is( $load->write_record, 1, 'Second record saved' );
	$load->set( key   => 1   );
	$load->set( value => 'c' );
	is( $load->write_record, $return_on_duplicate, 'Third record processed' );
}

subtest 'Keep duplicates' => sub {
	my $load = new_ok( 'Data::ETL::Load::Hash' => [
		duplicates => 'keep',
		hash       => \%data,
	] );
	$load->setup;
	fill_record( $load );

	my @keys = keys %data;
	is( scalar( @keys ), 2, 'Correct number of records' );
	ok( exists( $data{1} ), 'First record exists' );
	ok( exists( $data{2} ), 'Second record exists' );

	is( ref( $data{1} ), 'ARRAY', 'Duplicates in list' );
	is( scalar( @{$data{1}} ), 2, 'Two duplicates' );
	is( $data{1}[0]{value}, 'a', 'First duplicate correct' );
	is( $data{1}[1]{value}, 'c', 'Second duplicate correct' );

	is( $data{2}{value}, 'b', 'Second record correct' );

	$load->finished;
};

subtest 'Overwrite duplicates' => sub {
	my $load = new_ok( 'Data::ETL::Load::Hash' => [
		duplicates => 'overwrite',
		hash       => \%data,
	] );
	$load->setup;
	fill_record( $load );

	my @keys = keys %data;
	is( scalar( @keys ), 2, 'Correct number of records' );
	ok( exists( $data{1} ), 'First record exists' );
	ok( exists( $data{2} ), 'Second record exists' );

	is( ref( $data{1} ), 'HASH', 'One value in list' );
	is( $data{1}{value}, 'c', 'Kept last duplicate' );
	is( $data{2}{value}, 'b', 'Second record correct' );

	$load->finished;
};

subtest 'Skip duplicates' => sub {
	my $load = new_ok( 'Data::ETL::Load::Hash' => [
		duplicates => 'skip',
		hash       => \%data,
	] );
	$load->setup;
	fill_record( $load, 0 );

	my @keys = keys %data;
	is( scalar( @keys ), 2, 'Correct number of records' );
	ok( exists( $data{1} ), 'First record exists' );
	ok( exists( $data{2} ), 'Second record exists' );

	is( ref( $data{1} ), 'HASH', 'One value in list' );
	is( $data{1}{value}, 'a', 'First duplicate correct' );
	is( $data{2}{value}, 'b', 'Second record correct' );

	$load->finished;
};

subtest 'Do not clear the hash' => sub {
	my $load = new_ok( 'Data::ETL::Load::Hash' => [
		duplicates => 'overwrite',
		hash       => \%data,
	] );
	$load->setup;
	fill_record( $load );

	$load->clear( 0 );
	$load->setup;
	my @keys = keys %data;
	is( scalar( @keys ), 2, 'Old data still in hash' );

	$load->finished;
};

done_testing;
