#! /usr/bin/env perl

# Usage : perl -w import-compta.pl excel-filename [sheet-name]

# Works as a basic template

use Spreadsheet::ParseExcel;
#use Spreadsheet::WriteExcel

use strict;
use warnings;
use Data::Dumper;
use Programme::Schema;
use File::Basename;

Programme::Schema->load_namespaces;


my $schema = Programme::Schema->connect('dbi:SQLite:programmev2.db', '', '',{ sqlite_unicode => 1});

my @inputs;
my $spreadsheet;
my $book;

my @result_steps;

my $input;

# SUBS

sub seconds_to_time {
	my $seconds = shift;
	my $hours = int($seconds / 3600);
	my $minutes = int(($seconds - 3600 * $hours)/60);
	$seconds = $seconds - (3600 * $hours) - (60 * $minutes);
	return $hours.":".$minutes.":".$seconds;
}

sub time_to_minutes {
	my $time_str = shift;
	my ($hours, $minutes, $seconds) = split(/:/, $time_str);
	return $hours * 60 + $minutes + $seconds / 60;
}

sub time_to_seconds {
	my $time_str = shift;
	my ($hours, $minutes, $seconds) = split(/:/, $time_str);
	return $hours * 3600 + $minutes * 60 + $seconds;
}

sub compute_fract_duration {
	my $nb = shift;
	my $time_str1 = shift;
	my $time_str2 = shift	;
	return seconds_to_time((time_to_seconds($time_str1)+time_to_seconds($time_str2))*$nb);
}	


sub getbookinfo {
	my $book = shift;
	my($filename, $path, $suffix) = fileparse($book);
	print "Book label : \t",$book->get_filename(),"\n";
	my @sheets = $book->worksheet();
	print "Nb of sheets : \t",$book->worksheet_count(),"\n";
}


$input = "/Users/bertrand/MY_GITHUB/my-running/EXCEL/4programmedbimport-v2.xls";

# add check of xls file version must be 
if (-e $input) {
	my $parser   = Spreadsheet::ParseExcel->new();
	my $workbook = $parser->parse($input);

	getbookinfo($workbook);

	print "####################################\n";

	for my $worksheet ( $workbook->worksheets() ) {
		my $table_id 	= $worksheet->get_name();
		my @columns_id;
		
		my ($min_row, $max_row) = $worksheet->row_range();
		my ($min_col, $max_col) = $worksheet->col_range();
		foreach my $col ( $min_col .. $max_col ) {
			my $cell = $worksheet->get_cell(0, $col);
			push @columns_id, $cell->value();
		}	
		my $rs 		= $schema->resultset($table_id );
		my $record 	= $schema->resultset($table_id )->new_result({});
		my $source 	= $schema->source($table_id );
		my @fields 	= $source->columns;

		if ( (join(",",@fields)) eq (join(",",@columns_id)) ) {
			print "schema ok \n";
			# full populate table without any check
			
#			my ($min_row, $max_row) = $worksheet->row_range();
#			my ($min_col, $max_col) = $worksheet->col_range();
			foreach my $row ($min_row+1 .. $max_row) {
				my @record=(); 
				foreach my $col ( $min_col .. $max_col )  {
					my $cell = $worksheet->get_cell($row, $col);
					push @record, $cell->value();
				}
				print join(",",@record),"\n";
#				print Dumper(@record);
				@result_steps = $schema->resultset($table_id)->populate([ 
					[ @fields ],[ @record ]
				]);
			}	
		}
		else {
			print "schema NOK \n";
			print "Table : ", $table_id, " columns / xls fields mismatch !\n"; 
			
			
		}
		
		# Populating other tables
		
		foreach my $step (@result_steps) {
			print Dumper($step);
			my $step_lib 		= $step->{step_lib};
			my $step_type 		= $step->{step_type};
			my $step_proglib 	= $step->{step_proglib};
			my $step_duration 	= $step->{step_duration};
			my $step_tolerance 	= $step->{step_tolerance}; 
			
			my ($step_no,$nb_steps) = (split("/",$step_lib));
			
			
			# parsing step_proglib
			# parsing kyewords : 'dont','à','récupération','et finir par','x'
			#/^([\d]{1,2}(h|:)([\d]{2})?(allure [1-2]{1}|vitesse marathon|80-85% de la VMA) \(  \)/
			#
			$step_duration = $1 # Always
			$$			
			
			$1
			if ($step_type eq 'b') {
				# populate base
				
				my $base_import = $schema->resultset('Base')->find_or_create({
						base_lib 		=> $step_lib
						base_type 		=> $step_type,
						base_proglib 	=> $step_proglib,
						base_allureid	=> 
				
				base_lib, base_type, base_proglibL,base_allureid
			}
			else {
				# populate fractionne	
			}
			
		# need to deal with missing or computed fields in xls sheets vs table
			if ($table_id eq 'Step') {
#				my ($min_row, $max_row) = $worksheet->row_range();
#				my ($min_col, $max_col) = $worksheet->col_range();
				my @record=(); 
				foreach my $row ($min_row+1 .. $max_row) {
					@record=(); 
					foreach my $col ( $min_col .. $max_col )  {
						my $cell = $worksheet->get_cell($row, $col);
						push @record, $cell->value();
					}
					if ( $record[0] =~ /^([\d]{2}:[\d]{2}:[\d]{2})@([\s\w\d%]+)$/ ) {
						push @record, $2, $1; # $2 is an allure
					}
					print join(",",@record),"\n";
					print Dumper(@record);
				
					
		});
				
				
				}	
			}
			if ($table_id eq 'Base') {
#				my ($min_row, $max_row) = $worksheet->row_range();
#				my ($min_col, $max_col) = $worksheet->col_range();
				my @record=(); 
				foreach my $row ($min_row+1 .. $max_row) {
					@record=(); 
					foreach my $col ( $min_col .. $max_col )  {
						my $cell = $worksheet->get_cell($row, $col);
						push @record, $cell->value();
					}
					if ( $record[0] =~ /^([\d]{2}:[\d]{2}:[\d]{2})@([\s\w\d%]+)$/ ) {
						push @record, $2, $1; # $2 is an allure
					}
					print join(",",@record),"\n";
					print Dumper(@record);
					$schema->resultset($table_id)->populate([ 
							[ @fields ],[ @record ]
					]);
				}	
			}
			elsif ($table_id eq 'Fractionne') {
#				my ($min_row, $max_row) = $worksheet->row_range();
#				my ($min_col, $max_col) = $worksheet->col_range();
				my @record=(); 
				foreach my $row ($min_row+1 .. $max_row) {
					@record=(); 
					foreach my $col ( $min_col .. $max_col )  {
						my $cell = $worksheet->get_cell($row, $col);
						push @record, $cell->value();
					}
					print "RECORD-O",$record[0],"\n";
					# ^([\d]+)x\(([\d]{2}:[\d]{2}:[\d]{2})@([\s\w\d%\+\-\_]+)\/([\d]{2}:[\d]{2}:[\d]{2})@([\s\w\d%\+\-\_]+)\)
					if ( $record[0] =~ /^([\d]+)x\(([\d]{2}:[\d]{2}:[\d]{2})@([\s\w\d%\+\-\_]+)\/([\d]{2}:[\d]{2}:[\d]{2})@([\s\w\d%\+\-\_]+)\)$/ ) {
						push @record, $1, $2, $3, $4, $5, compute_fract_duration($1,$2,$4); # $3 and $5 are allures
					}
					print join(",",@record),"\n";
					print Dumper(@record);
					$schema->resultset($table_id)->populate([ 
							[ @fields ],[ @record ]
					]);
				}	
			}	
		}
	}
}	
else {
	print "Input invalid !\n";
}