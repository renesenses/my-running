#!/usr/bin/env perl

use Spreadsheet::ParseXLSX;
use Data::Dumper;

use Spreadsheet::ParseExcel;
 
my $parser   = Spreadsheet::ParseExcel->new();
my $workbook = $parser->parse('/Users/renesenses/MY_GITHUB/my-running/EXCEL/2016-03-11_MOOC-TRAIL_CARNET.xls');

my $parser2 = Spreadsheet::ParseXLSX->new;
my $workbook2 = $parser->parse('/Users/renesenses/MY_GITHUB/my-running/EXCEL/2016-03-11_MOOC-TRAIL_CARNET.xlxs');

print Dumper($workbook);