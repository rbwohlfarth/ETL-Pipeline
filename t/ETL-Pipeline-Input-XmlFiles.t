use ETL::Pipeline;
use Test::More;

subtest 'Retrieving data' => sub {
	sub retrievingData {
		my ($etl, $record) = @_;

		return unless $etl->count == 1;

		is( $etl->input->file->basename, '1234.xml', 'First file' );
		is( $etl->get( '/FeedbackFile/Row/Data/PK' ), '1234', 'Individual value' );
		is( ref( $etl->get( '/FeedbackFile/Row/SubTable/Feedback' ) ), 'ARRAY', 'Repeating node' );
	}
	my $etl = ETL::Pipeline->new( {
		constants => {un => 1},
		input     => ['XmlFiles', iname => '*.xml'],
		on_record => \&retievingData,
		output    => 'UnitTest',
		work_in   => 't/DataFiles/XmlFiles',
	} )->process;
	is( $etl->count, 2, 'All records processed' );
};
subtest 'Records at' => sub {
	sub recordsAt {
		my ($etl, $record) = @_;

		return unless $etl->count == 1;

		is( $etl->get( '/Data/PK' ), '1234', 'Individual value' );
		is( ref( $etl->get( '/SubTable/Feedback' ) ), 'ARRAY', 'Repeating node' );
	}
	my $etl = ETL::Pipeline->new( {
		constants => {un => 1},
		input     => ['XmlFiles', iname => '*.xml', records_at => '/FeedbackFile/Row'],
		on_record => \&recordsAt,
		output    => 'UnitTest',
		work_in   => 't/DataFiles/XmlFiles',
	} )->process;
};
subtest 'ETL::Pipeline::File::Listing' => sub {
	sub fileListing {
		my ($etl, $record) = @_;

		if ($etl->count == 1) {
			is( $etl->input->file->basename, '1234.xml', 'First file' );
		} else {
			is( $etl->input->file->basename, '5678.xml', 'Second file' );
		}
	}
	my $etl = ETL::Pipeline->new( {
		constants => {un => 1},
		input     => ['XmlFiles', iname => '*.xml'],
		on_record => \&fileListing,
		output    => 'UnitTest',
		work_in   => 't/DataFiles/XmlFiles',
	} )->process;
	is( $etl->count, 2, 'All files processed' );
};

done_testing();
