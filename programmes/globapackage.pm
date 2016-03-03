package MyGlobalPackage;

use strict;
use warnings;

use base 'Exporter';

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

1;