use ETL::Pipeline;
use String::Util qw/hascontent/;
use Test::More;


subtest 'Single XML file' => sub {
	my $etl = ETL::Pipeline->new( {
		work_in => 't/DataFiles',
		input   => ['Xml', name => 'FM-Export.XML', root => '/RLXML/FILES/FEEDBACK'],
	} );
	$etl->input->configure;
	pass( 'configure' );

	ok( $etl->input->next_record, 'next_record' );
	is( $etl->input->attribute( 'ACTION' ), 'DELETE', 'attribute' );

	subtest 'Second record' => sub {
		ok( $etl->input->next_record, 'next_record' );
		is( $etl->input->get( 'ROW/DATA/FILESEQUENCEID' ), '12345', 'get' );

		subtest 'Multiple values' => sub {
			my @data = $etl->input->get_repeating(
				'ROW/SUBTABLES/PERSON',
				'ROW/DATA/LASTNAME'
			);
			is_deeply( \@data, ['DOE', 'Smith'], 'List' );

			my @data = $etl->input->get_repeating(
				'ROW/SUBTABLES/PERSON',
				'ROW/DATA/LASTNAME',
				'ROW/DATA/FIRSTNAME',
			);
			is_deeply( \@data, [['DOE', 'JOHN'], ['Smith', 'Fred']], 'Related' );
		};
	};
	subtest 'Third record' => sub {
		ok( $etl->input->next_record, 'next_record' );
		is( $etl->input->get( 'ROW/DATA/FILESEQUENCEID' ), '67890', 'get' );
	};
	subtest 'Fourth record' => sub {
		ok( $etl->input->next_record, 'next_record' );
		is( $etl->input->get( 'ROW/DATA/FILESEQUENCEID' ), '15926', 'get' );
	};

	ok( !$etl->input->next_record, 'end of file' );
	$etl->input->finish;
};

subtest 'One record per XML file' => sub {
	my $etl = ETL::Pipeline->new( {
		work_in => 't/DataFiles/XmlFiles',
		input   => ['Xml', iname => qr/\.xml$/, root => '/'],
	} );
	$etl->input->configure;
	pass( 'configure' );

	ok( $etl->input->next_record, 'first file' );
	my $pk = $etl->input->get( '/FeedbackFile/Row/Data/PK' );
	ok( hascontent( $pk ), 'first PK' );

	ok( $etl->input->next_record, 'second file' );
	isnt( $etl->input->get( '/FeedbackFile/Row/Data/PK' ), $pk, 'second PK' );

	ok( !$etl->input->next_record, 'end of list' );
	$etl->input->finish;
};

done_testing();
