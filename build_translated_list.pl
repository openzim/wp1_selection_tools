#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use FindBin;

my %titles;
my %ids;

# Check command line arguments
my $titleFile = $ARGV[0] || "";
my $lang      = $ARGV[1] || "";
my $langLinks = "$FindBin::Bin/data/en.needed/langlinks.tmp";
my $pages     = "$FindBin::Bin/data/en.needed/pages";

if (!$lang) {
    print STDERR "Language is not set.\n";
    exit 1;
}

for my $file ($titleFile, $langLinks, $pages) {
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

# Open page list (and find title id)
print STDERR "Reading $pages...\n";
open(FILE, '<', $pages) or die("Unable to open file '$pages'\n");
while(<FILE>) {
    my $line = $_;
    chomp($line);
    my ($id, $title) = split("\t", $line);
    if (exists $titles{$title}) {
        $ids{$id} = undef;
        delete $titles{$title};
    }
}
close(FILE);

# Open langlinks (and find translation)
print STDERR "Reading $langLinks...\n";
open(FILE, '<', $langLinks) or die("Unable to open file '$langLinks'\n");
while(<FILE>) {
    my $line = $_;
    chomp($line);
    my ($i, $l, $t) = split("\t", $line);
    print $t."\n" if ($l eq $lang && exists $ids{$i})
}
close(FILE);


