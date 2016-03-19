#!/usr/bin/env perl

use Spreadsheet::ParseXLSX;
use Data::Dumper;

my $parser = Spreadsheet::ParseXLSX->new;
my $workbook = $parser->parse("/Users/bertrand/MY_GITHUB/my-running/EXCEL/2016-03-11_MOOC-TRAIL_CARNET.xls");

print Dumper($workbook);