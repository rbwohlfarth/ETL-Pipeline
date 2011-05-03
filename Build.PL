use Module::Build;
my $build = Module::Build->new(
	dist_abstract => 'Extract-Transform-Load pattern',
	dist_author   => 'Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>',
	dist_version  => '1.0',
	license       => 'restrictive',
	module_name   => 'ETL',
	requires      => {
		'perl'      => '5.10.1',
		'DBI'       => '1.615',
		'Moose'     => '1.01',
		'Spreadsheet::ParseExcel' => '',
		'Spreadsheet::XLSX'       => '',
		'Text::CSV' => '',
	},
);
$build->create_build_script;
