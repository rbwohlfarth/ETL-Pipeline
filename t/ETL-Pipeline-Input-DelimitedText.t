use ETL::Pipeline;
use Test::More;

subtest 'Retrieving data' => sub {
	sub retrievingData {
		my ($etl, $record) = @_;

		if ($etl->count == 1) {
			subtest '$record' => sub {
				is( $record->{0}, 'Field1', 'Field 1' );
				is( $record->{1}, 'Field2', 'Field 2' );
				is( $record->{2}, 'Field3', 'Field 3' );
				is( $record->{3}, 'Field4', 'Field 4' );
				is( $record->{4}, 'Field5', 'Field 5' );
			};
			subtest 'get' => sub {
				is( $etl->get( 0 ), 'Field1', 'Field 1' );
				is( $etl->get( 1 ), 'Field2', 'Field 2' );
				is( $etl->get( 2 ), 'Field3', 'Field 3' );
				is( $etl->get( 3 ), 'Field4', 'Field 4' );
				is( $etl->get( 4 ), 'Field5', 'Field 5' );
			};
			subtest 'By header' => sub {
				is( $etl->get( 'Header1' ), 'Field1', 'Header 1' );
				is( $etl->get( 'Header2' ), 'Field2', 'Header 2' );
				is( $etl->get( 'Header3' ), 'Field3', 'Header 3' );
				is( $etl->get( 'Header4' ), 'Field4', 'Header 4' );
			};
		}
		return 1;
	}
	my $etl = ETL::Pipeline->new( {
		constants => {un => 1},
		input     => ['DelimitedText', iname => 'DelimitedText.txt'],
		on_record => \&retrievingData,
		output    => 'UnitTest',
		work_in   => 't/DataFiles',
	} )->process;
	is( $etl->output->number_of_records, 2, 'All records processed' );
};
subtest 'ETL::Pipeline::Input::File::Table' => sub {
	subtest 'no_column_names' => sub {
		sub noColumnNames {
			my ($etl, $record) = @_;

			return unless $etl->count == 1;

			subtest '$record' => sub {
				is( $record->{0}, 'Header1', 'Field 1' );
				is( $record->{1}, 'Header2', 'Field 2' );
				is( $record->{2}, 'Header3', 'Field 3' );
				is( $record->{3}, 'Header4', 'Field 4' );
			};
			subtest 'get' => sub {
				is( $etl->get( 0 ), 'Header1', 'Field 1' );
				is( $etl->get( 1 ), 'Header2', 'Field 2' );
				is( $etl->get( 2 ), 'Header3', 'Field 3' );
				is( $etl->get( 3 ), 'Header4', 'Field 4' );
			};
			subtest 'By header' => sub {
				ok( !defined( $etl->get( 'Header1' ) ), 'Header 1' );
				ok( !defined( $etl->get( 'Header2' ) ), 'Header 2' );
				ok( !defined( $etl->get( 'Header3' ) ), 'Header 3' );
				ok( !defined( $etl->get( 'Header4' ) ), 'Header 4' );
			};
		}
		my $etl = ETL::Pipeline->new( {
			constants => {un => 1},
			input     => ['DelimitedText', iname => 'DelimitedText.txt', no_column_names => 1],
			on_record => \&noColumnNames,
			output    => 'UnitTest',
			work_in   => 't/DataFiles',
		} )->process;
		is( $etl->has_aliases, 0, 'No aliases' );
	};
};
subtest 'ETL::Pipeline::Input::File' => sub {
	subtest 'skipping' => sub {
		my $etl = ETL::Pipeline->new( {
			constants => {un => 1},
			input     => ['DelimitedText', iname => 'DelimitedText.txt', skipping => 1],
			output    => 'UnitTest',
			work_in   => 't/DataFiles',
		} )->process;
		is( $etl->output->number_of_records, 1, 'One row skipped' );

		$etl = ETL::Pipeline->new( {
			constants => {un => 1},
			input     => ['DelimitedText', iname => 'DelimitedText.txt', skipping => sub { shift =~ m/^Header/ ? 1 : 0 }],
			output    => 'UnitTest',
			work_in   => 't/DataFiles',
		} )->process;
		is( $etl->output->number_of_records, 1, 'Code skipped headers' );
	};
	subtest 'file' => sub {
		my $etl = ETL::Pipeline->new( {
			constants => {un => 1},
			input     => ['DelimitedText', iname => 'DelimitedText.txt'],
			output    => 'UnitTest',
			work_in   => 't/DataFiles',
		} )->process;
		is( $etl->input->file->basename, 'DelimitedText.txt', 'File path set' );
	};
};

done_testing;
