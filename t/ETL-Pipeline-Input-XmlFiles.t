use ETL::Pipeline;
use Test::More;


subtest 'Simple case' => sub {
	my $etl = ETL::Pipeline->new( {
		work_in => 't/DataFiles/XmlFiles',
		input   => ['XmlFiles'],
	} );
	$etl->input->configure;
	pass( 'configure' );

	ok( $etl->input->next_record, 'next_record' );
	is( $etl->input->get( '/FeedbackFile/Row/Data/PK' ), '1234', 'get' );
	is( $etl->input->file->basename, '1234.xml', 'file' );

	subtest 'Multiple values' => sub {
		my @data = $etl->input->get_repeating(
			'/FeedbackFile/Row/SubTables/Feedback/Row/SubTables/FeedbackFollowups/Row/Data',
			'PK'
		);
		is_deeply( \@data, [258, 159, 483], 'List' );

		my @data = $etl->input->get_repeating(
			'/FeedbackFile/Row/SubTables/Feedback/Row/SubTables/FeedbackFollowups/Row/Data',
			'PK',
			'FollowupMethod',
		);
		is_deeply( \@data, [[258, 'Telephone'], [159, 'Letter'], [483, 'E-Mail']], 'Related' );
	};

	subtest 'Second file' => sub {
		ok( $etl->input->next_record, 'next_record' );
		is( $etl->input->file->basename, '5678.xml', 'file' );
	};

	ok( !$etl->input->next_record, 'end of file' );
	$etl->input->finish;
};

subtest 'File filter' => sub {
	my $etl = ETL::Pipeline->new( {
		work_in => 't/DataFiles/XmlFiles',
		input   => ['XmlFiles', name => '1234.*'],
	} );
	$etl->input->configure;
	pass( 'configure' );

	ok( $etl->input->next_record, 'next_record' );
	is( $etl->input->file->basename, '1234.xml', 'file' );

	ok( !$etl->input->next_record, 'end of file' );
	$etl->input->finish;
};

done_testing();
