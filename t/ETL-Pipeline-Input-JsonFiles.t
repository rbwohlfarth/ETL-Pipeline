use ETL::Pipeline;
use Test::More;

subtest 'Retrieving data' => sub {
	sub retrievingData {
		my ($etl, $record) = @_;

		return unless $etl->count == 1;

		is( $etl->get( '/[0]/PK' ), '1234', 'Individual value' );
		is( ref( $etl->get( '/[0]/Data' ) ), 'ARRAY', 'Repeating node' );
	}
	my $etl = ETL::Pipeline->new( {
		constants => {un => 1},
		input     => ['JsonFiles', iname => '*.json'],
		on_record => \&retievingData,
		output    => 'UnitTest',
		work_in   => 't/DataFiles/JsonFiles',
	} )->process;
	is( $etl->count, 2, 'All records processed' );
};
subtest 'Records at' => sub {
	sub recordsAt {
		my ($etl, $record) = @_;

		return unless $etl->count == 1;

		is( $etl->get( '/PK' ), '1234', 'Individual value' );
		is( ref( $etl->get( '/Data' ) ), 'ARRAY', 'Repeating node' );
	}
	my $etl = ETL::Pipeline->new( {
		constants => {un => 1},
		input     => ['JsonFiles', iname => '*.json', records_at => '/'],
		on_record => \&recordsAt,
		output    => 'UnitTest',
		work_in   => 't/DataFiles/JsonFiles',
	} )->process;
	is( $etl->count, 3, 'All records processed' );
};
subtest 'ETL::Pipeline::File::Listing' => sub {
	sub fileListing {
		my ($etl, $record) = @_;

		if ($etl->count == 1) {
			is( $etl->input->file->basename, '1234.json', 'First file' );
		} else {
			is( $etl->input->file->basename, '5678.json', 'Second file' );
		}
	}
	my $etl = ETL::Pipeline->new( {
		constants => {un => 1},
		input     => ['JsonFiles', iname => '*.json'],
		on_record => \&fileListing,
		output    => 'UnitTest',
		work_in   => 't/DataFiles/JsonFiles',
	} )->process;
	is( $etl->count, 2, 'All files processed' );
};

done_testing();
