use ETL::Pipeline;
use Test::More;


subtest 'list' => sub {
	my $etl = ETL::Pipeline->new( {output => 'Memory'} );

	subtest 'First record' => sub {
		$etl->output->write( $etl, {value => 1} );
		pass( 'write' );

		is( $etl->output->number_of_records, 1, 'number_of_records' );
		is_deeply( [$etl->output->records], [{value => 1}], 'records' );
	};
	subtest 'Second record' => sub {
		$etl->output->write( $etl, {value => 2} );
		pass( 'write' );

		is( $etl->output->number_of_records, 2, 'number_of_records' );
		is_deeply( [$etl->output->records], [{value => 1}, {value => 2}], 'records' );
	};
};

subtest 'hash' => sub {
	my $etl = ETL::Pipeline->new( {output => ['Memory', key => 'key']} );

	subtest 'First record' => sub {
		$etl->output->write( $etl, {key => 'a', value => 1} );
		pass( 'write' );

		is( $etl->output->number_of_ids, 1, 'number_of_ids' );
		is_deeply( $etl->output->with_id( 'a' ), [{key => 'a', value => 1}], 'with_id' );

		is( $etl->output->number_of_records, 1, 'number_of_records' );
		is_deeply( [$etl->output->records], [{key => 'a', value => 1}], 'records' );
	};
	subtest 'Second record' => sub {
		$etl->output->write( $etl, {key => 'a', value => 2} );
		pass( 'write' );

		is( $etl->output->number_of_ids, 1, 'number_of_ids' );
		is_deeply( $etl->output->with_id( 'a' ), [
			{key => 'a', value => 1},
			{key => 'a', value => 2}
		], 'with_id' );

		is( $etl->output->number_of_records, 2, 'number_of_records' );
		is_deeply( [$etl->output->records], [
			{key => 'a', value => 1},
			{key => 'a', value => 2}
		], 'records' );
	};
	subtest 'Different key' => sub {
		$etl->output->write( $etl, {key => 'b', value => 3} );
		pass( 'write' );

		is( $etl->output->number_of_ids, 2, 'number_of_ids' );
		is_deeply( $etl->output->with_id( 'b' ), [{key => 'b', value => 3}], 'with_id' );
		is_deeply( $etl->output->with_id( 'a' ), [
			{key => 'a', value => 1},
			{key => 'a', value => 2}
		], 'Old id not changed' );

		is( $etl->output->number_of_records, 3, 'number_of_records' );
		is_deeply( [$etl->output->records], [
			{key => 'a', value => 1},
			{key => 'a', value => 2},
			{key => 'b', value => 3}
		], 'records' );
	};
};

done_testing;
