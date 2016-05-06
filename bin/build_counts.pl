#!/usr/bin/perl
binmode STDOUT, ":utf8";
binmode STDIN, ":utf8";
binmode STDERR, ":utf8";

use utf8;

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

my ($pageId, $pageNamespace, $pageName, $redirect);
my ($redirectSourcePageId, $redirectTargetNamespace, $redirectTargetPageName);
my ($pagelinkSourcePageId, $pagelinkTargetNamespace, $pagelinkTargetPageName);
my ($langlinkTargetPageId, $langlinkSourceWiki, $langlinkSourcePageName);
my ($chartPageName, $chartPageHit);
my (%pagelinks_hash, %langlinks_hash, %charts_hash);

open( PAGES_FILE, '<:gzip:utf8', $pagesFile ) or die("Unable to open file $pagesFile.\n");
while( <PAGES_FILE> ) {
    next unless (utf8::valid($_));
    ($pageId, $pageNamespace, $pageName, $redirect) = split(" ", $_);
    unless ($pageNamespace) {
	$pagelinks_hash{$pageName} = 0;
	$langlinks_hash{$pageId} = 0;
    }
}
close( PAGES_FILE );

open( PAGELINKS_FILE, '<:gzip:utf8', $pagelinksFile ) or die("Unable to open file $pagelinksFile.\n");
while( <PAGELINKS_FILE> ) {
    next unless (utf8::valid($_));
    ($pagelinkSourcePageId, $pagelinkTargetNamespace, $pagelinkTargetPageName) = split(" ", $_);
    unless ($pagelinkTargetNamespace) {
	if (exists($pagelinks_hash{$pagelinkTargetPageName}) && exists($langlinks_hash{$pagelinkSourcePageId}) ) {
	    $pagelinks_hash{$pagelinkTargetPageName} += 1;
	}
    }
}
close( PAGELINKS_FILE );

open( LANGLINKS_FILE, '<:gzip:utf8', $langlinksFile ) or die("Unable to open file $langlinksFile.\n");
my $langlinks_line = readline(*LANGLINKS_FILE);
open( PAGES_FILE, '<:gzip:utf8', $pagesFile ) or die("Unable to open file $pagesFile.\n");
while( <PAGES_FILE> ) {
    next unless (utf8::valid($_));
    ($pageId, $pageNamespace, $pageName, $redirect) = split(" ", $_);
    unless($pageNamespace || $redirect) {
	updateLanglinkCount();
    }
}
close( PAGES_FILE );
close( LANGLINKS_FILE );

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

open( REDIRECTS_FILE, '<:gzip:utf8', $redirectsFile ) or die("Unable to open file $redirectsFile.\n");
my $redirects_line = readline(*REDIRECTS_FILE);
open( PAGES_FILE, '<:gzip:utf8', $pagesFile ) or die("Unable to open file $pagesFile.\n");
while( <PAGES_FILE> ) {
    next unless (utf8::valid($_));
    ($pageId, $pageNamespace, $pageName, $redirect) = split(" ", $_);
    if(!$pageNamespace && $redirect) {
        updatePagelinkCount();
    }
}
close( PAGES_FILE );
close( LANGLINKS_FILE );

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
    open( CHARTS_FILE, '<:gzip:utf8', $chartsFile ) or die("Unable to open file $chartsFile.\n");
    while( <CHARTS_FILE> ) {
	next unless (utf8::valid($_));
	($chartPageName, $chartPageHit) = split(" ", $_);
	$charts_hash{$chartPageName} = $chartPageHit || 0;
    }
    close( CHARTS_FILE );
}

open( PAGES_FILE, '<:gzip:utf8', $pagesFile ) or die("Unable to open file $pagesFile.\n");
while( <PAGES_FILE> ) {
    next unless (utf8::valid($_));
    ($pageId, $pageNamespace, $pageName, $redirect) = split(" ", $_);
    unless ($pageNamespace || $redirect) {
	print $pageId." ".$pageName." ".$langlinks_hash{$pageId}." ".$pagelinks_hash{$pageName}." ".($charts_hash{$pageName} || "0" )."\n";
    }
}
close( PAGES_FILE );




