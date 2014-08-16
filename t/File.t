use Data::ETL;
use Data::ETL::Extract::DelimitedText;
use Test::More;

working_folder 't';

subtest 'File selection' => sub {
	my $file = new_ok( 'Data::ETL::Extract::DelimitedText' => [
		find_file => qr/\.txt$/i,
	] );
	$file->setup;
	is( $file->path, 't/DataFiles/DelimitedText.txt', 'Regular expression' );
	$file->finished;

	$file = new_ok( 'Data::ETL::Extract::DelimitedText' => [
		find_file => sub { m/\.txt$/i },
	] );
	$file->setup;
	is( $file->path, 't/DataFiles/DelimitedText.txt', 'Code reference' );
	$file->finished;

	$file = new_ok( 'Data::ETL::Extract::DelimitedText' => [
		path => 't/DataFiles/DelimitedText.txt',
	] );
	$file->setup;
	is( $file->path, 't/DataFiles/DelimitedText.txt', 'Fixed path' );
	$file->finished;

	$file->path( undef );
	pass( 'No file found' );
};

subtest 'Without header row' => sub {
	my $file = new_ok( 'Data::ETL::Extract::DelimitedText' => [
		has_field_names => 0,
		path            => 't/DataFiles/DelimitedText.txt',
	] );
	$file->setup;

	is( $file->record_number, 0, 'No records loaded' );
	is( $file->_cached, 0, 'No records read' );

	ok( $file->next_record, 'First record loaded' );
	ok( defined $file->record, 'Record has data' );

	my @keys = keys %{$file->record};
	is( scalar( @keys ), 4, 'One copy of each field' );

	is( $file->get( 0 ), 'Header1', 'Found Header1 by number' );
	is( $file->get( 1 ), 'Header2', 'Found Header2 by number' );
	is( $file->get( 2 ), 'Header3', 'Found Header3 by number' );
	is( $file->get( 3 ), 'Header4', 'Found Header4 by number' );

	is( $file->get( 100 ), undef, 'Invalid field returns undef' );

	$file->finished;
};

subtest 'With header row' => sub {
	my $file = new_ok( 'Data::ETL::Extract::DelimitedText' => [
		has_field_names => 1,
		path            => 't/DataFiles/DelimitedText.txt',
	] );
	$file->setup;

	is( $file->record_number, 1, 'Header row parsed' );
	is( $file->_cached, 0, 'Next record is data' );

	ok( $file->next_record, 'Record loaded' );
	ok( defined $file->record, 'Record has data' );
	is( $file->get( 0 ), 'Field1', 'Loaded the data row' );

	is( $file->get( qr/head(er)?1/i ), 'Field1', 'Found Field1 by header' );
	is( $file->get( qr/2/i          ), 'Field2', 'Found Field2 by header' );
	is( $file->get( qr/he.*3/i      ), 'Field3', 'Found Field3 by header' );
	is( $file->get( qr/4/i          ), 'Field4', 'Found Field4 by header' );

	is( $file->get( qr/zzzz/ ), undef, 'Unmatched header returns undef' );

	$file->finished;
};

subtest 'Skip report headers' => sub {
	my $file = new_ok( 'Data::ETL::Extract::DelimitedText' => [
		has_field_names     => 0,
		path                => 't/DataFiles/DelimitedText.txt',
		report_header_until => 2,
	] );
	$file->setup;
	is( $file->record_number, 2, 'Skipped two rows' );
	is( $file->_cached, 0, 'Nothing in memory' );
};

subtest 'Variable length report headers' => sub {
	my $file = new_ok( 'Data::ETL::Extract::DelimitedText' => [
		has_field_names     => 0,
		path                => 't/DataFiles/DelimitedText.txt',
		report_header_until => sub { $_->get( 0 ) eq 'Field6' },
	] );
	$file->setup;
	is( $file->record_number, 3, 'Skipped two rows' );
	ok( $file->_cached, 'First data row cached' );
};

done_testing;
