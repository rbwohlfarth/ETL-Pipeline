#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install;

name 'Data-ETL';
license 'perl';
all_from 'lib/Data/ETL.pm';

requires 'File::Find::Rule';
requires 'Moose';
requires 'Moose::Role';
requires 'Regexp::Common';
requires 'Spreadsheet::ParseExcel';
requires 'Spreadsheet::XLSX';
requires 'String::Util';
requires 'Text::CSV';

test_requires 'Test::More' => '0.88';
test_requires 'Test::Pod'  => '1.44';

auto_manifest;
auto_install;
WriteAll;
