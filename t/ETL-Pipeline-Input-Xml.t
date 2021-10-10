use ETL::Pipeline;
use Test::More;

subtest 'Retrieving data' => sub {
	sub retrievingData {
		my ($etl, $record) = @_;

		return unless $etl->count == 1;

		is( $etl->get( '/ROW/DATA/FILESEQUENCEID' ), '12345', 'Individual value' );
		is( ref( $etl->get( '/ROW/SUBTABLES/PERSON' ) ), 'ARRAY', 'Repeating node' );
	}
	my $etl = ETL::Pipeline->new( {
		constants => {un => 1},
		input     => [
			'Xml',
			iname      => 'FM-Export.XML',
			records_at => '/RLXML/FILES/FEEDBACK',
		],
		on_record => \&retievingData,
		output    => 'UnitTest',
		work_in   => 't/DataFiles',
	} )->process;
	is( $etl->count, 4, 'All records processed' );
};
subtest 'ETL::Pipeline::Input::File' => sub {
	pass( 'skipping - n/a' );
	subtest 'file' => sub {
		my $etl = ETL::Pipeline->new( {
			constants => {un => 1},
			input     => [
				'Xml',
				iname      => 'FM-Export.XML',
				records_at => '/RLXML/FILES/FEEDBACK',
			],
			on_record => \&retievingData,
			output    => 'UnitTest',
			work_in   => 't/DataFiles',
		} )->process;
		is( $etl->input->file->basename, 'FM-Export.XML', 'File path set' );
	};
};

done_testing();
