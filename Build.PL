use Module::Build;
my $build = Module::Build->new(
	dist_abstract => 'Read data files in a variety of different formats',
	dist_author   => 'Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>',
	dist_version  => '1.0',
	license       => 'restrictive',
	module_name   => 'RawData',
	requires      => {
		'perl'  => '5.10.1',
		'Moose' => '1.01',
	},
);
$build->create_build_script;

