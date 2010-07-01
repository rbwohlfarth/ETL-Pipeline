use Test::More;

BEGIN { use_ok( 'RawData::Record' ); }
require_ok( 'RawData::Record' );


my $empty = new_ok( 'RawData::Record' );
is( $empty->is_blank( 1 ), 1, 'is_blank()' );


my $from_list = RawData::Record->from_array(
	qw/Field1 Field2 Field3 Field4 Field5/
);
ok( defined $from_list                  , 'Object exists' );
ok( $from_list->isa( 'RawData::Record' ), 'Object is the correct type' );
ok( defined $from_list->data            , 'data()' );

my @keys = sort keys( %{$from_list->data} );
is( scalar( @keys ), 5, 'Correct number of fields' );

foreach my $index (1..5) {
	is( $keys[$index - 1], $index, "Field $index has the correct key" );
}

foreach my $key (@keys) {
	is( $from_list->data->{$key}, "Field$key", "Field $key has the correct data" );
}


done_testing();

