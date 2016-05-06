#!/usr/bin/perl
use utf8;
use strict;
use warnings;
use PerlIO::gzip;
use Data::Dumper;
use Getopt::Long;

my $last = "";
my $count = 0;

# Get the files to open
while (my $line = <STDIN>) {
    if ($line =~ /^([\w|\.]+ [^ ]+) ([\d]+) [\d]+/) {
	if ($1 eq $last) {
	    $count += $2;
	} else {
	    if ($last) {
		print $last." ".$count." 0\n";
	    }
	    $count = $2;
	    $last = $1;
	}
    }
}
