use ETL::Pipeline;
use String::Util qw/hascontent/;
use Test::More;

push @INC, './t/Modules';

my $etl = ETL::Pipeline->new( {
	work_in   => 't/DataFiles',
	input     => ['+FileInput', iname => qr/\.txt/],
	constants => {one => 1},
	output    => 'UnitTest',
} );
is( $etl->input->file->basename, 'DelimitedText.txt', 'matching regular expression' );

my $etl = ETL::Pipeline->new( {
	work_in   => 't/DataFiles',
	input     => ['+FileInput', iname => '*.txt'],
	constants => {one => 1},
	output    => 'UnitTest',
} );
is( $etl->input->file->basename, 'DelimitedText.txt', 'matching glob' );

my $etl = ETL::Pipeline->new( {
	work_in   => 't/DataFiles',
	input     => ['+FileInput', matching => sub { shift; shift->basename =~ m/\.txt/i; }],
	constants => {one => 1},
	output    => 'UnitTest',
} );
is( $etl->input->file->basename, 'DelimitedText.txt', 'matching code reference' );

my $etl = ETL::Pipeline->new( {
	work_in   => 't/DataFiles',
	input     => ['+FileInput', file => 'DelimitedText.txt'],
	constants => {one => 1},
	output    => 'UnitTest',
} );
is( $etl->input->file->basename, 'DelimitedText.txt', 'file' );

subtest 'Multiple files' => sub {
	my $etl = ETL::Pipeline->new( {
		work_in => 't/DataFiles/XmlFiles',
		input   => ['Xml', iname => qr/\.xml$/, root => '/'],
	} );
	$etl->input->configure;
	pass( 'configure' );

	my $name = $etl->input->file->basename;
	ok( hascontent( $name ), 'first file' );

	ok( $etl->input->next_record, 'read first file' );
	ok( $etl->input->next_record, 'move to next file' );
	isnt( $etl->input->file->basename, $name, 'second file' );

	ok( !$etl->input->next_record, 'end of list' );
	$etl->input->finish;
};

done_testing;
