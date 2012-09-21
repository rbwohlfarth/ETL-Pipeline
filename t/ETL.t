use Test::More;

BEGIN { use_ok( 'Data::ETL' ); }
require_ok( 'Data::ETL' );

ok( defined &extract_using, 'extract_using command exported' );
ok( defined &transform    , 'transform command exported'     );
ok( defined &set          , 'set command exported'           );
ok( defined &load_into    , 'load_into command exported'     );
ok( defined &run          , 'run command exported'           );

done_testing();
