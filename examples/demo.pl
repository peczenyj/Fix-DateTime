#!/usr/bin/env perl
use DateTime;
use Fix::DateTime;

my $today = DateTime->today; 
my $tzsn  = $today->time_zone_short_name;

print <<EOF ;
Example of Fix::DateTime

my \$today = DateTime->today; 
my \$tzsn  = \$today->time_zone_short_name;

------------------------
The time zone for today $today is (tzsn => $tzsn) 
If Fix::DateTime is enable ($Fix::DateTime::ENABLE) time zone should be ($Fix::DateTime::DEFAULT_VALUE)

EOF
