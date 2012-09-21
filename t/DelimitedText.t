use Test::More;

BEGIN { use_ok( 'Data::ETL::Extract::DelimitedText' ); }
require_ok( 'Data::ETL::Extract::DelimitedText' );

# Without a header row...
my $file = new_ok( 'Data::ETL::Extract::DelimitedText' => [
	path => 't/DelimitedText.txt',
] );
$file->setup;
is( $file->record_number, 0, 'Positioned at beginning of file' );

ok( $file->next_record, 'First record loaded' );
ok( defined $file->record, 'First row has data' );
is( $file->record_number, 1, 'Counter incremented after first record' );

my @keys = sort keys( %{$file->record} );
is( scalar( @keys ), 4        , 'Four columns in first row'  );
is( $keys[0]       , 1        , 'Found field 1 in first row' );
is( $keys[1]       , 2        , 'Found field 2 in first row' );
is( $keys[2]       , 3        , 'Found field 3 in first row' );
is( $keys[3]       , 4        , 'Found field 4 in first row' );
is( $record->{1}   , 'Header1', 'Found Header1'              );
is( $record->{2}   , 'Header2', 'Found Header2'              );
is( $record->{3}   , 'Header3', 'Found Header3'              );
is( $record->{4}   , 'Header4', 'Found Header4'              );

ok( $file->next_record, 'Second record loaded' );
ok( defined $file->record, 'Second row has data' );
is( $file->record_number, 2, 'Counter incremented after second record' );

ok( $file->next_record, 'Third record loaded' );
ok( defined $file->record, 'Third row has data' );
is( $file->record_number, 3, 'Counter incremented after third record' );

my @keys = sort keys( %{$file->record} );
is( scalar( @keys ), 5        , 'Five columns in third row'  );
is( $keys[0]       , 1        , 'Found field 1 in third row' );
is( $keys[1]       , 2        , 'Found field 2 in third row' );
is( $keys[2]       , 3        , 'Found field 3 in third row' );
is( $keys[3]       , 4        , 'Found field 4 in third row' );
is( $keys[4]       , 5        , 'Found field 5 in third row' );
is( $record->{1}   , 'Field6', 'Found Field6'                );
is( $record->{2}   , 'Field7', 'Found Field7'                );
is( $record->{3}   , 'Field8', 'Found Field8'                );
is( $record->{4}   , 'Field9', 'Found Field9'                );
is( $record->{5}   , 'Field0', 'Found Field0'                );

$file->finished;


# With a header row...
my $file = new_ok( 'Data::ETL::Extract::DelimitedText' => [
	path    => 't/DelimitedText.txt',
	headers => {
		qr/head(er)?1/i => 'first' ,
		qr/2/i          => 'second',
		qr/he.*3/i      => 'third' ,
		qr/4/i          => 'fourth',
		qr/5/i          => 'fifth' ,
	},
] );
$file->setup;
is( $file->record_number, 1, 'Positioned at first data row' );

ok( $file->next_record, 'First record loaded' );
ok( defined $file->record, 'First row has data' );
is( $file->record_number, 2, 'Record count incremented after first record' );

my @keys = sort keys( %{$file->record} );
is( scalar( @keys )  , 5       , 'Five columns in first row'  );
is( $keys[0]         , 1       , 'Found field 1 in first row' );
is( $keys[1]         , 2       , 'Found field 2 in first row' );
is( $keys[2]         , 3       , 'Found field 3 in first row' );
is( $keys[3]         , 4       , 'Found field 4 in first row' );
is( $keys[4]         , 5       , 'Found field 5 in first row' );
is( $record->{1     }, 'Field1', 'Found Field1'               );
is( $record->{2     }, 'Field2', 'Found Field2'               );
is( $record->{3     }, 'Field3', 'Found Field3'               );
is( $record->{4     }, 'Field4', 'Found Field4'               );
is( $record->{5     }, 'Field5', 'Found Field5'               );
is( $record->{first }, 'Field1', 'Found Field1 by name'       );
is( $record->{second}, 'Field2', 'Found Field2 by name'       );
is( $record->{third }, 'Field3', 'Found Field3 by name'       );
is( $record->{fourth}, 'Field4', 'Found Field4 by name'       );

ok( not exists $record->{fifth}, 'No header for fifth field' );


done_testing();
