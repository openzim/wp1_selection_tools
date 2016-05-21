#!/usr/bin/perl

use utf8;
use strict;
use warnings;

my %counts;
my %id2title;

# Chef if directory exists
my $directory = $ARGV[0] || "";
if (!-d $directory) {
    print STDERR "Directory '$directory' does not exist. You have to call merge_lists.pl with as argument a directory path with the lists.\n";
    exit 1;
}

# Open pages.gz
my $pagesFile="$directory/pages.gz";
print STDERR "Reading $pagesFile...\n";
open(FILE, '<:gzip', $pagesFile) or die("Unable to open file $pagesFile.\n");
while(<FILE>) {
    my $line = $_;
    chomp($line);
    my ($pageId, $pageTitle) = split("\t", $line);
    $counts{$pageTitle}{"i"} = $pageId;
    $id2title{$pageId} = $pageTitle;
}
close(FILE);

# Open pagelinks.gz
my $pagelinksFile="$directory/pagelinks.gz";
print STDERR "Reading $pagelinksFile...\n";
open(FILE, '<:gzip', $pagelinksFile) or die("Unable to open file $pagelinksFile.\n");
while(<FILE>) {
    my $line = $_;
    chomp($line);
    my ($sourcePageId, $targetPageTitle) = split("\t", $line);
    $counts{$targetPageTitle}{"l"} = exists($counts{$targetPageTitle}{"l"}) ? $counts{$targetPageTitle}{"l"}+1 : 0;
}
close(FILE);

# Open langlinks.gz
my $langlinksFile="$directory/langlinks.gz";
print STDERR "Reading $langlinksFile...\n";
open(FILE, '<:gzip', $langlinksFile) or die("Unable to open file $langlinksFile.\n");
while(<FILE>) {
    my $line = $_;
    chomp($line);
    my ($pageId) = split("\t", $line);
    my $pageTitle = $id2title{$pageId};
    next unless ($pageTitle);
    $counts{$pageTitle}{"ll"} = exists($counts{$pageTitle}{"ll"}) ? $counts{$pageTitle}{"ll"}+1 : 0;
}
close(FILE);

# Open pageviews.gz
my $pageviewsFile="$directory/pageviews.gz";
print STDERR "Reading $pageviewsFile...\n";
open(FILE, '<:gzip', $pageviewsFile) or die("Unable to open file $pageviewsFile.\n");
while(<FILE>) {
    my $line = $_;
    chomp($line);
    my ($pageTitle, $pageviewCount) = split("\t", $line);
    $counts{$pageTitle}{"v"} = $pageviewCount;
}
close(FILE);

# Open redirects.gz
my $redirectsFile="$directory/redirects.gz";
print STDERR "Reading $redirectsFile...\n";
open(FILE, '<:gzip', $redirectsFile) or die("Unable to open file $redirectsFile.\n");
while(<FILE>) {
    my $line = $_;
    chomp($line);
    my ($sourcePageId, $targetPageTitle) = split("\t", $line);
    my $sourcePageTitle = $id2title{$sourcePageId};
    if ($sourcePageTitle &&
	exists($counts{$sourcePageTitle})) {
	
	if (exists($counts{$targetPageTitle})) {
	    if ($counts{$sourcePageTitle}{"l"}) {
		if ($counts{$targetPageTitle}{"l"}) {
		    $counts{$targetPageTitle}{"l"} += $counts{$sourcePageTitle}{"l"};
		} else {
		    $counts{$targetPageTitle}{"l"} = $counts{$sourcePageTitle}{"l"};
		}
	    }
	    if ($counts{$sourcePageTitle}{"ll"}) {
		if ($counts{$targetPageTitle}{"ll"}) {
		    $counts{$targetPageTitle}{"ll"} += $counts{$sourcePageTitle}{"ll"};
		} else {
		    $counts{$targetPageTitle}{"ll"} = $counts{$sourcePageTitle}{"ll"};
		}
	    }
	    if ($counts{$sourcePageTitle}{"v"}) {
		if ($counts{$targetPageTitle}{"v"}) {
		    $counts{$targetPageTitle}{"v"} += $counts{$sourcePageTitle}{"v"};
		} else {
		    $counts{$targetPageTitle}{"v"} = $counts{$sourcePageTitle}{"v"};
		}
	    }
	}

	delete($counts{$sourcePageTitle});
    }
}
close(FILE);

# Print counts
print STDERR "Printing all counts...\n";
open(FILE, '<:gzip', $pagesFile) or die("Unable to open file $pagesFile.\n");
while(<FILE>) {
    my $line = $_;
    chomp($line);
    my ($pageId, $pageTitle, $isRedirect) = split("\t", $line);
    next if ($isRedirect);
    print $pageTitle."\t".$pageId."\t".($counts{$pageTitle}{"l"} || "0")."\t".($counts{$pageTitle}{"ll"} || "0")."\t".($counts{$pageTitle}{"v"} || "0")."\n";
}
close(FILE);

# Exit
print STDERR "Finishing...\n";
exit 0;
