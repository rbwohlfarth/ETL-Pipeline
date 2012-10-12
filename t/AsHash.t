use Test::More;
use Data::ETL::Extract::DelimitedText;

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

is( scalar( @{$file->names     } ), 4, 'Field names set'   );
is( scalar( @{$file->names->[0]} ), 1, 'first: only name'  );
is( scalar( @{$file->names->[1]} ), 1, 'second: only name' );
is( scalar( @{$file->names->[2]} ), 1, 'third: only name'  );
is( scalar( @{$file->names->[3]} ), 1, 'fourth: only name' );
is( $file->names->[0]->[0], 'first' , 'first: right name'  );
is( $file->names->[1]->[0], 'second', 'second: right name' );
is( $file->names->[2]->[0], 'third' , 'third: right name'  );
is( $file->names->[3]->[0], 'fourth', 'fourth: right name' );

ok( $file->next_record, 'Record loaded' );
ok( defined $file->record, 'Record has data' );

my @keys = keys %{$file->record};
is( scalar( @keys )        , 9       , 'Numbers and names'      );
is( $file->record->{0     }, 'Field1', 'Found Field1 by number' );
is( $file->record->{1     }, 'Field2', 'Found Field2 by number' );
is( $file->record->{2     }, 'Field3', 'Found Field3 by number' );
is( $file->record->{3     }, 'Field4', 'Found Field4 by number' );
is( $file->record->{4     }, 'Field5', 'Found Field5 by number' );
is( $file->record->{first }, 'Field1', 'Found Field1 by name'   );
is( $file->record->{second}, 'Field2', 'Found Field2 by name'   );
is( $file->record->{third }, 'Field3', 'Found Field3 by name'   );
is( $file->record->{fourth}, 'Field4', 'Found Field4 by name'   );

$file->finished;

done_testing;
