use Test::More;


use_ok( 'Data::ETL::Load::Perl' );

my $check = 0;
sub code { $check = $_->{value}; }

my $load = new_ok( 'Data::ETL::Load::Perl' => [execute => \&code] );

$load->set( value => 1 );
ok( $load->write_record, 'Code executed' );
is( $check, 1, 'Variable changed' );

done_testing;
