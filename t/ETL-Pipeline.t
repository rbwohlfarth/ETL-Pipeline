use Test::More;


use_ok( 'ETL::Pipeline' );

subtest 'Simple pipeline' => sub {
	my $etl = ETL::Pipeline->new( {
		work_in   => 't',
		input     => 'UnitTest',
		constants => {constant => 'String literal'},
		mapping   => {un => 0, deux => 1, trois => 2},
		output    => 'UnitTest',
	} );
	$etl->process;
	pass( 'Script ran' );

	is( $etl->count, 2, 'Two records' );
	subtest 'First record' => sub {
		my $record = $etl->output->get_record( 0 );
		my @keys   = keys %$record;
		is( scalar( @keys )    , 4               , '4 fields'       );
		is( $record->{un      }, 'Field1'        , 'Found Field1'   );
		is( $record->{deux    }, 'Field2'        , 'Found Field2'   );
		is( $record->{trois   }, 'Field3'        , 'Found Field3'   );
		is( $record->{constant}, 'String literal', 'Found constant' );
	};
	subtest 'Second record' => sub {
		my $record = $etl->output->get_record( 1 );
		my @keys   = keys %$record;
		is( scalar( @keys )    , 4               , '4 fields'       );
		is( $record->{un      }, 'Field11'       , 'Found Field11'  );
		is( $record->{deux    }, 'Field12'       , 'Found Field12'  );
		is( $record->{trois   }, 'Field13'       , 'Found Field13'  );
		is( $record->{constant}, 'String literal', 'Found constant' );
	};
};

subtest 'chain' => sub {
	subtest 'Everything' => sub {
		my $one = ETL::Pipeline->new( {
			work_in   => 't',
			data_in   => 'DataFiles',
			input     => 'UnitTest',
			mapping   => {un => 1},
			constants => {deux => 2},
			output    => 'UnitTest'
		} );
		$one->session( good => 1 );
		my $two = $one->chain();
		ok( !$two->is_valid, 'Not valid' );
		is( $two->work_in->basename, 't', 'work_in' );
		is( $two->data_in->basename, 'DataFiles', 'data_in' );
		is( $two->session( 'good' ), 1, 'session' );
	};
	subtest 'No work_in' => sub {
		my $one = ETL::Pipeline->new( {
			input     => 'UnitTest',
			mapping   => {un => 1},
			constants => {deux => 2},
			output    => 'UnitTest'
		} );
		$one->session( good => 1 );
		my $two = $one->chain();
		ok( !$two->is_valid, 'Not valid' );
		is( $two->work_in, undef, 'work_in' );
		is( $two->data_in, undef, 'data_in' );
		is( $two->session( 'good' ), 1, 'session' );
	};
	subtest 'No session' => sub {
		my $one = ETL::Pipeline->new( {
			work_in   => 't',
			data_in   => 'DataFiles',
			input     => 'UnitTest',
			mapping   => {un => 1},
			constants => {deux => 2},
			output    => 'UnitTest'
		} );
		my $two = $one->chain();
		ok( !$two->is_valid, 'Not valid' );
		is( $two->work_in->basename, 't', 'work_in' );
		is( $two->data_in->basename, 'DataFiles', 'data_in' );
		ok( !$two->session_has( 'good' ), 'session' );
	};
};

subtest 'data_in' => sub {
	my $etl = ETL::Pipeline->new( {work_in => 't'} );

	$etl->data_in( 'DataFiles' );
	is( $etl->data_in->basename, 'DataFiles', 'Fixed directory' );

	$etl->data_in( qr/^DataFiles$/i );
	is( $etl->data_in->basename, 'DataFiles', 'Search for subfolder' );
};

subtest 'Fixed module names' => sub {
	unshift @INC, './t/Modules';
	my $etl = ETL::Pipeline->new;

	$etl->input( '+Input' );
	ok( defined( $etl->input ), 'Input' );

	$etl->output( '+Output' );
	ok( defined( $etl->output ), 'Output' );
};

subtest 'is_valid' => sub {
	subtest 'No work_in' => sub {
		my $etl = ETL::Pipeline->new( {
			input   => 'UnitTest',
			mapping => {un => 1},
			output  => 'UnitTest',
		} );
		ok( !$etl->is_valid, 'Boolean return' );

		my @error = $etl->is_valid;
		ok( !$error[0], 'Return code' );
		is( $error[1], 'The working folder was not set' );
	};
	subtest 'No input' => sub {
		my $etl = ETL::Pipeline->new( {
			work_in => 't',
			mapping => {un => 1},
			output  => 'UnitTest',
		} );
		ok( !$etl->is_valid, 'Boolean return' );

		my @error = $etl->is_valid;
		ok( !$error[0], 'Return code' );
		is( $error[1], 'The "input" object was not set' );
	};
	subtest 'No output' => sub {
		my $etl = ETL::Pipeline->new( {
			work_in => 't',
			input   => 'UnitTest',
			mapping => {un => 1},
		} );
		ok( !$etl->is_valid, 'Boolean return' );

		my @error = $etl->is_valid;
		ok( !$error[0], 'Return code' );
		is( $error[1], 'The "output" object was not set' );
	};
	subtest 'No mapping' => sub {
		my $etl = ETL::Pipeline->new( {
			work_in => 't',
			input   => 'UnitTest',
			output  => 'UnitTest',
		} );
		ok( !$etl->is_valid, 'Boolean return' );

		my @error = $etl->is_valid;
		ok( !$error[0], 'Return code' );
		is( $error[1], 'The mapping was not set' );
	};
	subtest 'Valid' => sub {
		my $etl = ETL::Pipeline->new( {
			work_in => 't',
			input   => 'UnitTest',
			mapping => {un => 1},
			output  => 'UnitTest',
		} );
		ok( $etl->is_valid, 'Boolean return' );

		my @error = $etl->is_valid;
		ok( $error[0], 'Return code' );
		is( $error[1], undef );
	};
	subtest 'Constants, no mapping' => sub {
		my $etl = ETL::Pipeline->new( {
			work_in   => 't',
			input     => 'UnitTest',
			constants => {un => 1},
			output    => 'UnitTest',
		} );
		ok( $etl->is_valid, 'Boolean return' );

		my @error = $etl->is_valid;
		ok( $error[0], 'Return code' );
		is( $error[1], undef );
	};
};

subtest 'mapping' => sub {
	my $etl = ETL::Pipeline->new( {
		work_in => 't',
		input   => 'UnitTest',
		mapping => {un => '/*[0]'},
		output  => 'UnitTest',
	} )->process;
	my $output = $etl->output->get_record( 0 );
	is( $output->{un}, 'Field1', 'Data path' );

	my $etl = ETL::Pipeline->new( {
		work_in => 't',
		input   => 'UnitTest',
		mapping => {un => qr/1/},
		output  => 'UnitTest',
	} )->process;
	my $output = $etl->output->get_record( 0 );
	is( $output->{un}, 'Field1', 'Regular expression' );

	my $etl = ETL::Pipeline->new( {
		work_in => 't',
		input   => 'UnitTest',
		mapping => {un => 0},
		output  => 'UnitTest',
	} )->process;
	my $output = $etl->output->get_record( 0 );
	is( $output->{un}, 'Field1', 'Bare field number' );

	my $etl = ETL::Pipeline->new( {
		work_in => 't',
		input   => 'UnitTest',
		mapping => {un => 'Header1'},
		output  => 'UnitTest',
	} )->process;
	my $output = $etl->output->get_record( 0 );
	is( $output->{un}, 'Field1', 'Bare field name' );

	subtest 'Multiple fields' => sub {
		my $etl = ETL::Pipeline->new( {
			work_in => 't',
			input   => 'UnitTest',
			mapping => {un => 'Header6'},
			output  => 'UnitTest',
		} )->process;
		my $output = $etl->output->get_record( 0 );
		is( $output->{un}, 'Field6; Field7', 'Bare field name' );

		my $etl = ETL::Pipeline->new( {
			work_in => 't',
			input   => 'UnitTest',
			mapping => {un => qr/der6/},
			output  => 'UnitTest',
		} )->process;
		my $output = $etl->output->get_record( 0 );
		is( $output->{un}, 'Field6; Field7', 'Regular expression' );
	};

	subtest 'Code reference' => sub {
		my ($pipeline, $record);
		my $etl = ETL::Pipeline->new( {
			work_in => 't',
			input   => 'UnitTest',
			mapping => {un => sub { ($pipeline, $record) = @_; return 'abc'; }},
			output  => 'UnitTest',
		} )->process;

		is( ref( $pipeline ), 'ETL::Pipeline', 'Pipeline in parameters' );
		is( ref( $record   ), 'ARRAY'        , 'Record in parameters'   );

		my $output = $etl->output->get_record( 0 );
		is( $output->{un}, 'abc', 'Return value' );
	};

	my $etl = ETL::Pipeline->new( {
		work_in => 't',
		input   => 'UnitTest',
		mapping => {un => '/invalid'},
		output  => 'UnitTest',
	} )->process;
	my $output = $etl->output->get_record( 0 );
	is( $output->{un}, undef, 'Not found' );
};

subtest 'on_record' => sub {
	subtest 'Skip records' => sub {
		my $etl = ETL::Pipeline->new( {
			work_in   => 't',
			input     => 'UnitTest',
			mapping   => {un => 0},
			on_record => sub { return (shift->count == 1 ? 1 : 0); },
			output    => 'UnitTest',
		} )->process;

		is( $etl->output->number_of_records, 1, 'Loaded 1 of 2 records' );
		is( $etl->count                    , 2, 'Count bypassed record' );

		my $output = $etl->output->get_record( 0 );
		is( $output->{un}, 'Field1', 'Record 1' );
	};
	subtest 'Change record content' => sub {
		my $etl = ETL::Pipeline->new( {
			work_in   => 't',
			input     => 'UnitTest',
			mapping   => {un => 0},
			on_record => sub { my ($p, $r) = @_; $r->[0] = uc( $r->[0] ); },
			output    => 'UnitTest',
		} )->process;

		is( $etl->count, 2, 'Loaded 2 of 2 records' );

		my $output = $etl->output->get_record( 0 );
		is( $output->{un}, 'FIELD1', 'Value changed' );
	};
};

subtest 'session' => sub {
	my $etl = ETL::Pipeline->new;

	subtest 'Not set' => sub {
		ok( !$etl->session_has( 'bad' ), 'exists' );
		is( $etl->session( 'bad' ), undef, 'get' );
	};
	subtest 'Single value' => sub {
		is( $etl->session( good => 3 ), 3, 'set' );
		is( $etl->session( 'good' ), 3, 'get' );
		ok( $etl->session_has( 'good' ), 'exists' );
	};
	subtest 'Multiple values' => sub {
		$etl->session( okay => 4, maybe => 5 );
		ok( $etl->session_has( 'okay' ), 'First exists' );
		is( $etl->session( 'okay' ), 4, 'First value' );
		ok( $etl->session_has( 'maybe' ), 'Second exists' );
		is( $etl->session( 'maybe' ), 5, 'Second value' );
	};
	subtest 'References' => sub {
		$etl->session( many => [7, 8, 9] );
		subtest 'Scalar context' => sub {
			my $scalar = $etl->session( 'many' );
			is( ref( $scalar ), 'ARRAY', 'get' );
			is_deeply( $scalar, [7, 8, 9], 'values' );
		};
		subtest 'List context' => sub {
			my @list = $etl->session( 'many' );
			is_deeply( \@list, [7, 8, 9], 'values' );
		};
	};
	subtest 'Overwrite' => sub {
		is( $etl->session( 'good', 6 ), 6, 'set' );
		is( $etl->session( 'good' ), 6, 'get' );
	};
};

subtest 'work_in' => sub {
	my $etl = ETL::Pipeline->new;

	$etl->work_in( 't' );
	is( $etl->work_in->basename, 't', 'Fixed directory' );
	is( $etl->data_in->basename, 't', 'data_in set' );

	$etl->work_in( iname => 't' );
	is( $etl->work_in->basename, 't', 'Search current directory' );

	$etl->work_in( root => 't', iname => 'DataFiles' );
	is( $etl->work_in->basename, 'DataFiles', 'Search other directory' );

	$etl->work_in( root => 't', iname => 'Data*' );
	is( $etl->work_in->basename, 'DataFiles', 'File glob' );

	$etl->work_in( root => 't', iname => qr/^DataFiles$/i );
	is( $etl->work_in->basename, 'DataFiles', 'Regular expression' );

	$etl->work_in( root => 't/DataFiles', iname => 'F*' );
	is( $etl->work_in->basename, 'FileListing', 'Alphabetical order' );
};

done_testing();
