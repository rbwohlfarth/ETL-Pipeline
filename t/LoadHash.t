use Test::More;


use_ok( 'Data::ETL::Load::Hash' );

my %data;
my $load = new_ok( 'Data::ETL::Load::Hash' => [hash => \%data] );

sub fill_record {
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
	$load->duplicates( 'keep' );
	$load->setup;

	fill_record;

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
	$load->duplicates( 'overwrite' );
	$load->setup;

	fill_record;

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
	$load->duplicates( 'skip' );
	$load->setup;

	fill_record( 0 );

	my @keys = keys %data;
	is( scalar( @keys ), 2, 'Correct number of records' );
	ok( exists( $data{1} ), 'First record exists' );
	ok( exists( $data{2} ), 'Second record exists' );

	is( ref( $data{1} ), 'HASH', 'One value in list' );
	is( $data{1}{value}, 'a', 'First duplicate correct' );
	is( $data{2}{value}, 'b', 'Second record correct' );

	$load->finished;
};

done_testing;
