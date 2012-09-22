use Test::More;

BEGIN { use_ok( 'Data::ETL::Extract::DelimitedText' ); }
require_ok( 'Data::ETL::Extract::DelimitedText' );

my $file = new_ok( 'Data::ETL::Extract::DelimitedText' => [
	path => 't/DelimitedText.txt',
] );
$file->setup;

subtest 'First record' => sub {
	ok( $file->next_record, 'Record loaded' );
	ok( defined $file->record, 'Record has data' );

	my @keys = keys %{$file->record};
	is( scalar( @keys )   , 4        , 'Four columns'  );
	is( $file->record->{0}, 'Header1', 'Found Header1' );
	is( $file->record->{1}, 'Header2', 'Found Header2' );
	is( $file->record->{2}, 'Header3', 'Found Header3' );
	is( $file->record->{3}, 'Header4', 'Found Header4' );
};
subtest 'Second record' => sub {
	ok( $file->next_record, 'Record loaded' );
	ok( defined $file->record, 'Record has data' );
};
subtest 'Third record' => sub {
	ok( $file->next_record, 'Record loaded' );
	ok( defined $file->record, 'Record has data' );

	my @keys = keys %{$file->record};
	is( scalar( @keys )   , 5       , 'Five columns' );
	is( $file->record->{0}, 'Field6', 'Found Field6' );
	is( $file->record->{1}, 'Field7', 'Found Field7' );
	is( $file->record->{2}, 'Field8', 'Found Field8' );
	is( $file->record->{3}, 'Field9', 'Found Field9' );
	is( $file->record->{4}, 'Field0', 'Found Field0' );
};
is( $file->next_record, 0, 'End of file reached' );

$file->finished;

done_testing();
