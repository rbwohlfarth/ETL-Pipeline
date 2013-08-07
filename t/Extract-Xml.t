use Data::ETL;
use String::Util qw/trim/;
use Test::More;

working_folder 't/DataFiles';

BEGIN { use_ok( 'Data::ETL::Extract::Xml' ); }
require_ok( 'Data::ETL::Extract::Xml' );

my $data = new_ok( 'Data::ETL::Extract::Xml', [
	path      => 't/DataFiles/FM-Export.xml',
	root_node => '/RLXML/FILES/FEEDBACK',
] );
$data->setup;

is( $data->next_record, 1, 'File parsed' );
is( $data->attribute( 'ACTION' ), 'DELETE', 'Attribute value' );

subtest 'First record' => sub {
	is( $data->next_record, 1, 'Record found' );
	is( $data->get( 'ROW/DATA/FILESEQUENCEID' ), '12345', 'Single field');
	is( $data->get( [
		'ROW/SUBTABLES/FOLLOW/ROW/DATA/DETAILS',
		"\n--divider--\n",
	] ), trim( <<LITERAL ), 'Multiple fields');
Narrative text goes into this place. It can be several sentences long. A paragraph or two is not uncommon. See how long you've been reading?
--divider--
Narrative text goes into this place. It can be several sentences long. A paragraph or two is not uncommon. See how long you've been reading?
--divider--
Narrative text goes into this place. It can be several sentences long. A paragraph or two is not uncommon. See how long you've been reading?
--divider--
The last line is different for the unit test.
LITERAL
	is( $data->get( [
		'ROW/SUBTABLES/FOLLOW/ROW/DATA/DETAILS',
		undef,
	] ), trim( <<LITERAL ), 'undef returns first of multiple fields');
Narrative text goes into this place. It can be several sentences long. A paragraph or two is not uncommon. See how long you've been reading?
LITERAL
	is( $data->get( [
		'ROW/SUBTABLES/FOLLOW/ROW/DATA/DETAILS',
		'first',
	] ), trim( <<LITERAL ), 'First of multiple fields');
Narrative text goes into this place. It can be several sentences long. A paragraph or two is not uncommon. See how long you've been reading?
LITERAL
	is( $data->get( [
		'ROW/SUBTABLES/FOLLOW/ROW/DATA/DETAILS',
		'last',
	] ), trim( <<LITERAL ), 'Last of multiple fields');
The last line is different for the unit test.
LITERAL
};

subtest 'Second record' => sub {
	is( $data->next_record, 1, 'Record found' );
	is( $data->get( 'ROW/DATA/FILESEQUENCEID' ), '67890', 'Different File ID');
};

is( $data->next_record, 1, 'Third record' );
is( $data->next_record, 0, 'End of file'  );

$data->finished;
done_testing();
