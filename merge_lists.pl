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

# Open pages
my $pagesFile = "$directory/pages";
print STDERR "Reading $pagesFile...\n";
open(FILE, '<', $pagesFile) or die("Unable to open file $pagesFile\n");
while(<FILE>) {
    my $line = $_;
    chomp($line);
    my ($pageId, $pageTitle, $pageSize, $isRedirect) = split("\t", $line);
    $counts{$pageTitle}{"i"} = $pageId;
    unless ($isRedirect) {
	$counts{$pageTitle}{"s"} = $pageSize;
    }
    $id2title{$pageId} = $pageTitle;
}
close(FILE);

# Open pagelinks
my $pagelinksFile = "$directory/pagelinks";
print STDERR "Reading $pagelinksFile...\n";
open(FILE, '<', $pagelinksFile) or die("Unable to open file $pagelinksFile\n");
while(<FILE>) {
    my $line = $_;
    chomp($line);
    my ($sourcePageId, $targetPageTitle) = split("\t", $line);
    $counts{$targetPageTitle}{"l"} = exists($counts{$targetPageTitle}{"l"}) ? $counts{$targetPageTitle}{"l"}+1 : 0;
}
close(FILE);

# Open langlinks
my $langlinksFile = "$directory/langlinks";
print STDERR "Reading $langlinksFile...\n";
open(FILE, '<', $langlinksFile) or die("Unable to open file $langlinksFile\n");
while(<FILE>) {
    my $line = $_;
    chomp($line);
    my ($pageId) = split("\t", $line);
    my $pageTitle = $id2title{$pageId};
    next unless ($pageTitle);
    $counts{$pageTitle}{"ll"} = exists($counts{$pageTitle}{"ll"}) ? $counts{$pageTitle}{"ll"}+1 : 0;
}
close(FILE);

# Open pageviews
my $pageviewsFile = "$directory/pageviews";
print STDERR "Reading $pageviewsFile...\n";
open(FILE, '<', $pageviewsFile) or die("Unable to open file $pageviewsFile\n");
while(<FILE>) {
    my $line = $_;
    chomp($line);
    my ($pageTitle, $pageviewCount) = split("\t", $line);
    $counts{$pageTitle}{"v"} = $pageviewCount;
}
close(FILE);

# Open redirects
my $redirectsFile = "$directory/redirects";
print STDERR "Reading $redirectsFile...\n";
open(FILE, '<', $redirectsFile) or die("Unable to open file $redirectsFile\n");
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

# Open ratings (if exists)
my $ratingsFile = "$directory/ratings";
if (-f $ratingsFile) {
    print STDERR "Reading $ratingsFile...\n";
    open(FILE, '<', $ratingsFile) or die("Unable to open file $ratingsFile\n");
    while(<FILE>) {
	my $line = $_;
	chomp($line);
	my ($pageTitle, $project, $quality, $importance) = split("\t", $line);
	my $ratingEntry = $project."=".$quality.":".$importance;
	if (exists($counts{$pageTitle}{"r"})) {
	    $counts{$pageTitle}{"r"} .= ($counts{$pageTitle}{"r"} ? "\t" : "").$ratingEntry;
	} else {
	    $counts{$pageTitle}{"r"} = $ratingEntry;
	}
    }
    close(FILE);
}

# Print counts
print STDERR "Printing all counts...\n";
open(FILE, '<', $pagesFile) or die("Unable to open file $pagesFile\n");
while(<FILE>) {
    my $line = $_;
    chomp($line);
    my ($pageId, $pageTitle, $isRedirect) = split("\t", $line);
    next if ($isRedirect);
    print
	$pageTitle."\t".
	$pageId."\t".
	($counts{$pageTitle}{"s"} || "0")."\t".
	($counts{$pageTitle}{"l"} || "0")."\t".
	($counts{$pageTitle}{"ll"} || "0")."\t".
	($counts{$pageTitle}{"v"} || "0").
	(exists($counts{$pageTitle}{"r"}) ? "\t".$counts{$pageTitle}{"r"} : "").
	"\n";
}
close(FILE);

# Exit
print STDERR "Finishing...\n";
exit 0;
