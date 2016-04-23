use Data::ETL;
use File::Spec::Functions qw/splitdir/;
use Path::Class;
use String::Util qw/trim/;
use Test::More;

my $root = dir( qw/t DataFiles XmlFiles/ );
working_folder "$root";

BEGIN { use_ok( 'Data::ETL::Extract::XmlFiles' ); }
require_ok( 'Data::ETL::Extract::XmlFiles' );

my $data = new_ok( 'Data::ETL::Extract::XmlFiles' );
$data->setup;

is( $data->next_record, 1, 'File parsed' );
subtest 'XML file path' => sub {
	my $path = file( $data->path );
	ok( $path->parent->subsumes( $root ), 'Correct directory' );
	is( $path->basename, '1234.xml', 'Correct file' );
};

is( $data->get( '/FeedbackFile/Row/SubTables/Feedback/Row/Data/FileId' ),
	'1234', 'XPath finds field');
is( $data->get( [
	'/FeedbackFile/Row/SubTables/Feedback/Row/SubTables/FeedbackFollowups/Row/Data/FollowupDescription',
	"\n--divider--\n",
] ), trim( <<LITERAL ), 'Multiple nodes concatenated');
<P>The first feedback line went right here.</P>
<P>I replaced it with this silly text.</P>
<P>I don't want real data for testing - just the structure.</P>
--divider--
<P>A second follow up sentence.</P>
LITERAL
is( $data->get( [
	'/FeedbackFile/Row/SubTables/Feedback/Row/SubTables/FeedbackFollowups/Row/Data/FollowupDescription',
	undef,
] ), trim( <<LITERAL ), 'undef returns first of multiple fields');
<P>The first feedback line went right here.</P>
<P>I replaced it with this silly text.</P>
<P>I don't want real data for testing - just the structure.</P>
LITERAL
is( $data->get( [
	'/FeedbackFile/Row/SubTables/Feedback/Row/SubTables/FeedbackFollowups/Row/Data/FollowupDescription',
	'first',
] ), trim( <<LITERAL ), 'First of multiple fields');
<P>The first feedback line went right here.</P>
<P>I replaced it with this silly text.</P>
<P>I don't want real data for testing - just the structure.</P>
LITERAL
is( $data->get( [
	'/FeedbackFile/Row/SubTables/Feedback/Row/SubTables/FeedbackFollowups/Row/Data/FollowupDescription',
	'last',
] ), trim( <<LITERAL ), 'Last of multiple fields');
<P>A second follow up sentence.</P>
LITERAL
is( $data->get(
	'/FeedbackFile/Row/SubTables/Feedback/Row/SubTables/FeedbackFollowups/Row/Data/Feedbackid',
), '369', 'Unique values');

my @nodes = $data->get_nodes( '/FeedbackFile/Row/SubTables/Feedback/Row/SubTables/FeedbackFollowups/Row/Data/FollowupDescription' );
ok( scalar( @nodes ) > 1, 'Raw node set' );

ok( $data->exists( '/FeedbackFile' ), 'Node exists');
ok( !$data->exists( '/Other' ), 'Node does not exist');

is( $data->next_record, 0, 'End of file list' );

$data->finished;
done_testing();
