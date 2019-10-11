#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use FindBin;

my %titles;
my %scores;
my %results;

# Check command line arguments
my $titleFile = $ARGV[0] || "";
my $lang      = $ARGV[1] || "";
my $scoreFile = $ARGV[2] || "";
my $langLinks = "${FindBin::Bin}data/tmp/$lang.langlinks";

if (!$lang) {
    print STDERR "Language is not set.\n";
    exit 1;
}

for my $file ($titleFile, $langLinks, $scoreFile) {
    if (!-f $file) {
        print STDERR "File '$file' does not exist, is not a file or is not readable.\n";
        exit 1;
    }
}

# Open title list
print STDERR "Reading $titleFile...\n";
open(FILE, '<', $titleFile) or die("Unable to open file '$titleFile'\n");
while(<FILE>) {
    my $title = $_;
    chomp($title);
    $titles{$title} = undef;
}
close(FILE);

# Open score list
print STDERR "Reading $scoreFile...\n";
open(FILE, '<', $scoreFile) or die("Unable to open file '$scoreFile'\n");
while(<FILE>) {
    my $line = $_;
    chomp($line);
    my ($title, $score) = split("\t", $line);
    $scores{$title} = $score;
}
close(FILE);

# Open langlinks (and find translation)
print STDERR "Reading $langLinks...\n";
open(FILE, '<', $langLinks) or die("Unable to open file '$langLinks'\n");
while(<FILE>) {
    my $line = $_;
    chomp($line);
    my ($s, $l, $t) = split("\t", $line);
    $results{$t} = ($scores{$t} || 0)
        if ($l eq $lang && exists $titles{$s})
}
close(FILE);

# Print result
print "$_\n" for (sort { $results{$b} <=> $results{$a} } keys %results);
