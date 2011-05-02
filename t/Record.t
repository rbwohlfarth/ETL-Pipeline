use Test::More;

BEGIN { use_ok( 'ETL::Record' ); }
require_ok( 'ETL::Record' );


my $empty = new_ok( 'ETL::Record' );
is( $empty->is_blank( 1 ), 1, 'is_blank() is true' );


my $from_list = ETL::Record->from_array(
	qw/Field1 Field2 Field3 Field4 Field5/
);
ok( defined $from_list, 'from_array() creates instance' );
ok( $from_list->isa( 'ETL::Record' ), 'from_array() creates correct type' );
ok( defined $from_list->raw, 'from_array() set raw()' );

my @keys = sort keys( %{$from_list->raw} );
is( scalar( @keys ), 5, 'raw() has correct number of fields' );

foreach my $index (1..5) {
	is( $keys[$index - 1], $index, "Field $index has the correct key" );
}

foreach my $key (@keys) {
	is( 
		$from_list->raw->{$key}, 
		"Field$key", 
		"Field $key has the correct value"
	);
}


done_testing();
