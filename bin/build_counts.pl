#!/usr/bin/perl

my $now = time();
my $starttime = $now;

use strict;
use warnings;
use Getopt::Long;
use PerlIO::gzip;

my $pagesFile="";
my $pagelinksFile="";
my $langlinksFile="";
my $redirectsFile="";
my $chartsFile="";

GetOptions('chartsFile=s' => \$chartsFile, 'pagesFile=s' => \$pagesFile, 'pagelinksFile=s' => \$pagelinksFile, 'langlinksFile=s' => \$langlinksFile, 'redirectsFile=s' => \$redirectsFile);

if (!$pagesFile || !$pagelinksFile || !$langlinksFile || !$redirectsFile) {
    print "usage: ./build_counts.pl --pagesFile=main_pages_sort_by_ids.lst.gz --pagelinksFile=pagelinks.lst.gz --langlinksFile=langlinks_sort_by_ids.lst.gz --redirectsFile=redirects_sort_by_ids.lst.gz [--chartsFile=charts.lst.gz]\n";
    exit;
};

if ( ! -r $pagesFile) { 
  die "Can't read pagesFile: $pagesFile: $!\n";
}
if ( ! -r $pagelinksFile) { 
  die "Can't read pagelinksFile: $pagelinksFile: $!\n";
}
if ( ! -r $langlinksFile) { 
  die "Can't read langlinksFile: $langlinksFile: $!\n";
}
if ( ! -r $redirectsFile) { 
  die "Can't read redirectsFile: $redirectsFile: $!\n";
}
if ( defined $chartsFile && ! -r $chartsFile) { 
  die "Can't read chartsFile: $chartsFile: $!\n";
}

my ($pageId, $pageNamespace, $pageName, $redirect);
my ($redirectSourcePageId, $redirectTargetNamespace, $redirectTargetPageName);
my ($pagelinkSourcePageId, $pagelinkTargetNamespace, $pagelinkTargetPageName);
my ($langlinkTargetPageId, $langlinkSourceWiki, $langlinkSourcePageName);
my ($chartPageNamespace, $chartPageName, $chartPageHit);
my (%pagelinks_hash, %langlinks_hash, %charts_hash);


print STDERR "Pages file\n";
open( PAGES_FILE, '<:gzip', $pagesFile ) or die("Unable to open file $pagesFile.\n");
while( <PAGES_FILE> ) {
    ($pageId, $pageNamespace, $pageName, $redirect) = split(" ", $_);
    unless ($pageNamespace) {
	$pagelinks_hash{$pageName} = 0;
	$langlinks_hash{$pageId} = 0;
    }
}
close( PAGES_FILE );

print STDERR  "\t" . (time() - $now) . " seconds\n";
$now = time();

print STDERR "Pagelinks file\n";
open( PAGELINKS_FILE, '<:gzip', $pagelinksFile ) or die("Unable to open file $pagelinksFile.\n");
while( <PAGELINKS_FILE> ) {
    ($pagelinkSourcePageId, $pagelinkTargetNamespace, $pagelinkTargetPageName) = split(" ", $_);
    unless ($pagelinkTargetNamespace) {
	if (exists($pagelinks_hash{$pagelinkTargetPageName}) && exists($langlinks_hash{$pagelinkSourcePageId}) ) {
	    $pagelinks_hash{$pagelinkTargetPageName} += 1;
	}
    }
}
close( PAGELINKS_FILE );
print STDERR  "\t" . (time() - $now) . " seconds\n";
$now = time();


print STDERR "Langlinks file\n";
open( LANGLINKS_FILE, '<:gzip', $langlinksFile ) or die("Unable to open file $langlinksFile.\n");
my $langlinks_line = readline(*LANGLINKS_FILE);
open( PAGES_FILE, '<:gzip', $pagesFile ) or die("Unable to open file $pagesFile.\n");
while( <PAGES_FILE> ) {
    ($pageId, $pageNamespace, $pageName, $redirect) = split(" ", $_);
    unless($pageNamespace || $redirect) {
	updateLanglinkCount();
    }
}
close( PAGES_FILE );
close( LANGLINKS_FILE );
print STDERR  "\t" . (time() - $now) . " seconds\n";
$now = time();


sub updateLanglinkCount {
    do {
        return unless $langlinks_line;
        ($langlinkTargetPageId, $langlinkSourceWiki, $langlinkSourcePageName) = split(" ", $langlinks_line);

        if ($langlinkTargetPageId >= $pageId ) {
            if ($pageId == $langlinkTargetPageId) {
                $langlinks_hash{$pageId} += 1;
            } else {
                return;
            }
        }
    } while ( $langlinks_line = readline( *LANGLINKS_FILE) );
}


print STDERR "Redirects file\n";
open( REDIRECTS_FILE, '<:gzip', $redirectsFile ) or die("Unable to open file $redirectsFile.\n");
my $redirects_line = readline(*REDIRECTS_FILE);
open( PAGES_FILE, '<:gzip', $pagesFile ) or die("Unable to open file $pagesFile.\n");
while( <PAGES_FILE> ) {
    ($pageId, $pageNamespace, $pageName, $redirect) = split(" ", $_);
    if(!$pageNamespace && $redirect) {
        updatePagelinkCount();
    }
}
close( PAGES_FILE );
close( REDIRECTS_FILE );
print STDERR  "\t" . (time() - $now) . " seconds\n";
$now = time();

sub updatePagelinkCount {
    do {
        return unless $redirects_line;
        ($redirectSourcePageId, $redirectTargetNamespace, $redirectTargetPageName) = split(" ", $redirects_line);

        if ($redirectSourcePageId >= $pageId && !$redirectTargetNamespace) {
            if ($pageId == $redirectSourcePageId) {
                $pagelinks_hash{$redirectTargetPageName} += $pagelinks_hash{$pageName};
            } else {
                return;
            }
        }
    } while ( $redirects_line = readline( *REDIRECTS_FILE) );
}

if ($chartsFile) {
    print STDERR "Charts file\n";
    open( CHARTS_FILE, '<:gzip', $chartsFile ) or die("Unable to open file $chartsFile.\n");
    while( <CHARTS_FILE> ) {
	($chartPageNamespace, $chartPageName, $chartPageHit) = split(" ", $_);
	$charts_hash{$chartPageName} = $chartPageHit;
    }
    close( CHARTS_FILE );
    print STDERR  "\t" . (time() - $now) . " seconds\n";
    $now = time();
}

print STDERR "Pages file\n";
open( PAGES_FILE, '<:gzip', $pagesFile ) or die("Unable to open file $pagesFile.\n");
while( <PAGES_FILE> ) {
    ($pageId, $pageNamespace, $pageName, $redirect) = split(" ", $_);
    unless ($pageNamespace || $redirect) {
	print $pageId." ".$pageName." ".$langlinks_hash{$pageId}." ".$pagelinks_hash{$pageName}." ".($charts_hash{$pageName} || "0" )."\n";
    }
}
close( PAGES_FILE );
print STDERR  "\t" . (time() - $now) . " seconds\n";
$now = time();

print STDERR  "Total time:" . (time() - $starttime) . " seconds\n";

