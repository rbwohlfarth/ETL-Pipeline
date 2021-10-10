use ETL::Pipeline;
use Test::More;

subtest 'XLSX format' => sub {
	subtest 'Retrieving data' => sub {
		sub retrievingData {
			my ($etl, $record) = @_;

			return unless $etl->count == 1;

			subtest '$record' => sub {
				is( $record{1}, 'Field1', 'Field 1' );
				is( $record{2}, 'Field2', 'Field 2' );
				is( $record{3}, 'Field3', 'Field 3' );
				is( $record{4}, 'Field4', 'Field 4' );
				is( $record{5}, 'Field5', 'Field 5' );
			};
			subtest 'get' => sub {
				is( $etl->get( 1 ), 'Field1', 'Field 1' );
				is( $etl->get( 2 ), 'Field2', 'Field 2' );
				is( $etl->get( 3 ), 'Field3', 'Field 3' );
				is( $etl->get( 4 ), 'Field4', 'Field 4' );
				is( $etl->get( 5 ), 'Field5', 'Field 5' );
			};
			subtest 'By column letter' => sub  {
				is( $etl->get( 'A' ), 'Field1', 'Column A' );
				is( $etl->get( 'B' ), 'Field2', 'Column B' );
				is( $etl->get( 'C' ), 'Field3', 'Column C' );
				is( $etl->get( 'D' ), 'Field4', 'Column D' );
				is( $etl->get( 'E' ), 'Field5', 'Column E' );
			};
			subtest 'By header' => sub {
				is( $etl->get( 'Header1' ), 'Field1', 'Header 1' );
				is( $etl->get( 'Header2' ), 'Field2', 'Header 2' );
				is( $etl->get( 'Header3' ), 'Field3', 'Header 3' );
				is( $etl->get( 'Header4' ), 'Field4', 'Header 4' );
				is( $etl->get( 'Header5' ), 'Field5', 'Header 5' );
			};
		}
		my $etl = ETL::Pipeline->new( {
			constants => {un => 1},
			input     => ['Excel', iname => 'Excel2007.xlsx'],
			on_record => \&retievingData,
			output    => 'UnitTest',
			work_in   => 't/DataFiles',
		} )->process;
		is( $etl->output->number_of_records, 1, 'All records processed' );
	};
	subtest 'worksheet' => sub {
		subtest 'By name' => sub {
			my $etl = ETL::Pipeline->new( {
				constants => {un => 1},
				input     => [
					'Excel',
					iname           => 'Excel2007.xlsx',
					no_column_names => 1,
					worksheet       => 'Sheet2',
				],
				output    => 'UnitTest',
				work_in   => 't/DataFiles',
			} )->process;
			my $record = $etl->output->get_record;
			is( $record{1}, 'Sheet2', 'Correct sheet' );
		};
		subtest 'By regular expression' => sub {
			my $etl = ETL::Pipeline->new( {
				constants => {un => 1},
				input     => [
					'Excel',
					iname           => 'Excel2007.xlsx',
					no_column_names => 1,
					worksheet       => qr/t2$/,
				],
				output    => 'UnitTest',
				work_in   => 't/DataFiles',
			} )->process;
			my $record = $etl->output->get_record;
			is( $record{1}, 'Sheet2', 'Correct sheet' );
		};
	};
	subtest 'ETL::Pipeline::Input::File::Table' => sub {
		subtest 'no_column_names' => sub {
			sub noColumnNames {
				my ($etl, $record) = @_;

				return unless $etl->count == 1;

				subtest '$record' => sub {
					is( $record{1}, 'Field1', 'Field 1' );
					is( $record{2}, 'Field2', 'Field 2' );
					is( $record{3}, 'Field3', 'Field 3' );
					is( $record{4}, 'Field4', 'Field 4' );
					is( $record{5}, 'Field5', 'Field 5' );
				};
				subtest 'get' => sub {
					is( $etl->get( 1 ), 'Field1', 'Field 1' );
					is( $etl->get( 2 ), 'Field2', 'Field 2' );
					is( $etl->get( 3 ), 'Field3', 'Field 3' );
					is( $etl->get( 4 ), 'Field4', 'Field 4' );
					is( $etl->get( 5 ), 'Field5', 'Field 5' );
				};
				subtest 'By column letter' => sub  {
					is( $etl->get( 'A' ), 'Field1', 'Column A' );
					is( $etl->get( 'B' ), 'Field2', 'Column B' );
					is( $etl->get( 'C' ), 'Field3', 'Column C' );
					is( $etl->get( 'D' ), 'Field4', 'Column D' );
					is( $etl->get( 'E' ), 'Field5', 'Column E' );
				};
				subtest 'By header' => sub {
					ok( !defined( $etl->get( 'Header1' ) ), 'Header 1' );
					ok( !defined( $etl->get( 'Header2' ) ), 'Header 2' );
					ok( !defined( $etl->get( 'Header3' ) ), 'Header 3' );
					ok( !defined( $etl->get( 'Header4' ) ), 'Header 4' );
					ok( !defined( $etl->get( 'Header5' ) ), 'Header 5' );
				};
			}
			my $etl = ETL::Pipeline->new( {
				constants => {un => 1},
				input     => ['Excel', iname => 'Excel2007.xlsx', no_column_names => 1],
				on_record => \&noColumnNames,
				output    => 'UnitTest',
				work_in   => 't/DataFiles',
			} )->process;
			is( scalar( @{$etl->_alias} ), 0, 'No aliases' );
		};
	};
	subtest 'ETL::Pipeline::Input::File' => sub {
		subtest 'skipping' => sub {
			my $etl = ETL::Pipeline->new( {
				constants => {un => 1},
				input     => ['Excel', iname => 'Excel2007.xlsx', no_column_names => 1],
				output    => 'UnitTest',
				skipping  => 1,
				work_in   => 't/DataFiles',
			} )->process;
			is( $etl->output->number_of_records, 1, 'One row skipped' );

			$etl = ETL::Pipeline->new( {
				constants => {un => 1},
				input     => ['Excel', iname => 'Excel2007.xlsx', no_column_names => 1],
				output    => 'UnitTest',
				skipping  => sub { my ($etl $record) = @_; return ($record{1} =~ m/^Header/ ? 1 : 0); },
				work_in   => 't/DataFiles',
			} )->process;
			is( $etl->output->number_of_records, 1, 'Code skipped headers' );
		};
		subtest 'file' => sub {
			my $etl = ETL::Pipeline->new( {
				constants => {un => 1},
				input     => ['Excel', iname => 'Excel2007.xlsx'],
				output    => 'UnitTest',
				work_in   => 't/DataFiles',
			} )->process;
			is( $etl->input->file->basename, 'Excel2007.xlsx', 'File path set' );
		};
	};
};

subtest 'XLS format' => sub {
	subtest 'Retrieving data' => sub {
		sub retrievingData {
			my ($etl, $record) = @_;

			return unless $etl->count == 1;

			subtest '$record' => sub {
				is( $record{1}, 'Field1', 'Field 1' );
				is( $record{2}, 'Field2', 'Field 2' );
				is( $record{3}, 'Field3', 'Field 3' );
				is( $record{4}, 'Field4', 'Field 4' );
				is( $record{5}, 'Field5', 'Field 5' );
			};
			subtest 'get' => sub {
				is( $etl->get( 1 ), 'Field1', 'Field 1' );
				is( $etl->get( 2 ), 'Field2', 'Field 2' );
				is( $etl->get( 3 ), 'Field3', 'Field 3' );
				is( $etl->get( 4 ), 'Field4', 'Field 4' );
				is( $etl->get( 5 ), 'Field5', 'Field 5' );
			};
			subtest 'By column letter' => sub  {
				is( $etl->get( 'A' ), 'Field1', 'Column A' );
				is( $etl->get( 'B' ), 'Field2', 'Column B' );
				is( $etl->get( 'C' ), 'Field3', 'Column C' );
				is( $etl->get( 'D' ), 'Field4', 'Column D' );
				is( $etl->get( 'E' ), 'Field5', 'Column E' );
			};
			subtest 'By header' => sub {
				is( $etl->get( 'Header1' ), 'Field1', 'Header 1' );
				is( $etl->get( 'Header2' ), 'Field2', 'Header 2' );
				is( $etl->get( 'Header3' ), 'Field3', 'Header 3' );
				is( $etl->get( 'Header4' ), 'Field4', 'Header 4' );
				is( $etl->get( 'Header5' ), 'Field5', 'Header 5' );
			};
		}
		my $etl = ETL::Pipeline->new( {
			constants => {un => 1},
			input     => ['Excel', iname => 'Excel2003.xls'],
			on_record => \&retievingData,
			output    => 'UnitTest',
			work_in   => 't/DataFiles',
		} )->process;
		is( $etl->output->number_of_records, 1, 'All records processed' );
	};
	subtest 'worksheet' => sub {
		subtest 'By name' => sub {
			my $etl = ETL::Pipeline->new( {
				constants => {un => 1},
				input     => [
					'Excel',
					iname           => 'Excel2003.xls',
					no_column_names => 1,
					worksheet       => 'Sheet2',
				],
				output    => 'UnitTest',
				work_in   => 't/DataFiles',
			} )->process;
			my $record = $etl->output->get_record;
			is( $record{1}, 'Sheet2', 'Correct sheet' );
		};
		subtest 'By regular expression' => sub {
			my $etl = ETL::Pipeline->new( {
				constants => {un => 1},
				input     => [
					'Excel',
					iname           => 'Excel2003.xls',
					no_column_names => 1,
					worksheet       => qr/t2$/,
				],
				output    => 'UnitTest',
				work_in   => 't/DataFiles',
			} )->process;
			my $record = $etl->output->get_record;
			is( $record{1}, 'Sheet2', 'Correct sheet' );
		};
	};
	subtest 'ETL::Pipeline::Input::File::Table' => sub {
		subtest 'no_column_names' => sub {
			sub noColumnNames {
				my ($etl, $record) = @_;

				return unless $etl->count == 1;

				subtest '$record' => sub {
					is( $record{1}, 'Field1', 'Field 1' );
					is( $record{2}, 'Field2', 'Field 2' );
					is( $record{3}, 'Field3', 'Field 3' );
					is( $record{4}, 'Field4', 'Field 4' );
					is( $record{5}, 'Field5', 'Field 5' );
				};
				subtest 'get' => sub {
					is( $etl->get( 1 ), 'Field1', 'Field 1' );
					is( $etl->get( 2 ), 'Field2', 'Field 2' );
					is( $etl->get( 3 ), 'Field3', 'Field 3' );
					is( $etl->get( 4 ), 'Field4', 'Field 4' );
					is( $etl->get( 5 ), 'Field5', 'Field 5' );
				};
				subtest 'By column letter' => sub  {
					is( $etl->get( 'A' ), 'Field1', 'Column A' );
					is( $etl->get( 'B' ), 'Field2', 'Column B' );
					is( $etl->get( 'C' ), 'Field3', 'Column C' );
					is( $etl->get( 'D' ), 'Field4', 'Column D' );
					is( $etl->get( 'E' ), 'Field5', 'Column E' );
				};
				subtest 'By header' => sub {
					ok( !defined( $etl->get( 'Header1' ) ), 'Header 1' );
					ok( !defined( $etl->get( 'Header2' ) ), 'Header 2' );
					ok( !defined( $etl->get( 'Header3' ) ), 'Header 3' );
					ok( !defined( $etl->get( 'Header4' ) ), 'Header 4' );
					ok( !defined( $etl->get( 'Header5' ) ), 'Header 5' );
				};
			}
			my $etl = ETL::Pipeline->new( {
				constants => {un => 1},
				input     => ['Excel', iname => 'Excel2003.xls', no_column_names => 1],
				on_record => \&noColumnNames,
				output    => 'UnitTest',
				work_in   => 't/DataFiles',
			} )->process;
			is( scalar( @{$etl->_alias} ), 0, 'No aliases' );
		};
	};
	subtest 'ETL::Pipeline::Input::File' => sub {
		subtest 'skipping' => sub {
			my $etl = ETL::Pipeline->new( {
				constants => {un => 1},
				input     => ['Excel', iname => 'Excel2003.xls', no_column_names => 1],
				output    => 'UnitTest',
				skipping  => 1,
				work_in   => 't/DataFiles',
			} )->process;
			is( $etl->output->number_of_records, 1, 'One row skipped' );

			$etl = ETL::Pipeline->new( {
				constants => {un => 1},
				input     => ['Excel', iname => 'Excel2003.xls', no_column_names => 1],
				output    => 'UnitTest',
				skipping  => sub { my ($etl $record) = @_; return ($record{1} =~ m/^Header/ ? 1 : 0); },
				work_in   => 't/DataFiles',
			} )->process;
			is( $etl->output->number_of_records, 1, 'Code skipped headers' );
		};
		subtest 'file' => sub {
			my $etl = ETL::Pipeline->new( {
				constants => {un => 1},
				input     => ['Excel', iname => 'Excel2003.xls'],
				output    => 'UnitTest',
				work_in   => 't/DataFiles',
			} )->process;
			is( $etl->input->file->basename, 'Excel2003.xls', 'File path set' );
		};
	};
};

done_testing();
