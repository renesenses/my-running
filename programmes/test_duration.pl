#! /usr/bin/env perl
# Test duration fonctions
use strict;
use warnings;


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

my @val = (0, 3600, 7200, 60);
my @exp = ('0:0:0', '1:0:0','2:0:0', '0:1:0');

for my $ind (0.. $#val) {
	if ( seconds_to_time($val[$ind]) eq $exp[$ind] ) { 
		print "OK test stt",$ind, "\t value : ", $val[$ind], "\t returns : ", $exp[$ind],"\n";
	}
	else {
		print "NOK test stt",$ind, "\t value : ", $val[$ind],  "\t returns : ", seconds_to_time($val[$ind]),"\n";
	}
}

my @val_time = ("01:00:00", "00:01:00");

my@exp_time =  (3600,60);

for my $ind (0.. $#val_time) {
	if ( time_to_seconds($val_time[$ind]) eq $exp_time[$ind] ) { 
		print "OK test tts",$ind, "\t value : ", $val_time[$ind], "\t returns : ", $exp_time[$ind],"\n";
	}
	else {
		print "NOK test tts",$ind, "\t value : ", $val_time[$ind],  "\t returns : ", time_to_seconds($val_time[$ind]),"\n";
	}
}



my @val_dur = ([4,"00:01:00", "00:00:40"], [7,"00:00:40", "00:00:20"], [11,"00:00:20", "00:00:20"]);

my@exp_dur =  ("2:2:0","2:0:0");

for my $ind (0.. $#val_dur) {
	if ( compute_fract_duration($val_dur[$ind][0],$val_dur[$ind][1],$val_dur[$ind][2] ) eq $exp_dur[$ind] ) { 
		print "OK test cfd",$ind, "\t value : ", $val_dur[$ind], "\t returns : ", $exp_dur[$ind],"\n";
	}
	else {
		print "NOK test cfd",$ind, "\t value : ", $val_dur[$ind],  "\t returns : ", compute_fract_duration($val_dur[$ind][0],$val_dur[$ind][1],$val_dur[$ind][2]),"\n";
	}
}

