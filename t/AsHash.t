use Test::More;
use Data::ETL::Extract::DelimitedText;

subtest 'Without header row' => sub {
	my $file = new_ok( 'Data::ETL::Extract::DelimitedText' => [
		has_header_row => 0,
		path           => 't/DelimitedText.txt',
		root_folder    => 't',
	] );
	$file->setup;

	is( $file->record_number, 0, 'No record loaded yet' );

	ok( $file->next_record, 'Record loaded' );
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
		has_header_row => 1,
		path           => 't/DelimitedText.txt',
		root_folder    => 't',
	] );
	$file->setup;

	is( $file->record_number, 1, 'Skipped header row' );

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

done_testing;
