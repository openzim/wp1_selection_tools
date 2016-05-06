#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use PerlIO::gzip;

my $pagesFile="";
my $categoriesFile="";
my $categorylinksFile="";
my $redirectsFile="";
my $modus="";
my $start="";

my %done;
my @todo;

GetOptions('categoriesFile=s' => \$categoriesFile, 'pagesFile=s' => \$pagesFile, 'categorylinksFile=s' => \$categorylinksFile, 'redirectsFile=s' => \$redirectsFile, 'modus=s' => \$modus, 'start=s' => \$start );

if (!$pagesFile || !$categoriesFile || !$categorylinksFile || !$redirectsFile || !$modus || !($modus eq "get_parents" || $modus eq "get_children" ) ) {
    print "usage: ./parse_categories.pl --pagesFile=main_pages_sort_by_ids.lst.gz --categoriesFile=categories_sort_by_ids.lst.gz  --categorylinksFile=categorylinks_sort_by_ids.lst.gz --redirectsFile=redirects_sort_by_ids.lst.gz --modus=[get_children|get_parents] --start=my_start_page\n";
    exit;
};

if ($modus eq "get_children") {
    $modus = 1;
} else {
    $modus = undef;
}

my %graph;

my ($pageId, $pageNamespace, $pageName, $pageRedirect);
my ($categoryId, $categoryNamespace, $categoryName, $categoryRedirect);
my ($redirectSourcePageId, $redirectTargetNamespace, $redirectTargetPageName);
my ($categorylinkSourceId, $categorylinkTargetName);

my (%pages_hash, %revert_pages_hash, %categories_hash, %revert_categories_hash, %redirects_hash);

open( PAGES_FILE, '<:gzip', $pagesFile ) or die("Unable to open file $pagesFile.\n");
while( <PAGES_FILE> ) {
    ($pageId, $pageNamespace, $pageName, $pageRedirect) = split(" ", $_);
    $pages_hash{$pageId} = $pageName;
    $revert_pages_hash{$pageName} = $pageId;
}
close( PAGES_FILE );

open( CATEGORIES_FILE, '<:gzip', $categoriesFile ) or die("Unable to open file $categoriesFile.\n");
while( <CATEGORIES_FILE> ) {
    ($categoryId, $categoryNamespace, $categoryName, $categoryRedirect) = split(" ", $_);
    if ($categoryNamespace eq "14") {
        $categories_hash{$categoryId} = $categoryName;
        $revert_categories_hash{$categoryName} = $categoryId;
	$graph{$categoryId} = [()];
    }
}
close( CATEGORIES_FILE );

open( CATEGORYLINKS_FILE, '<:gzip', $categorylinksFile ) or die("Unable to open file $categorylinksFile.\n");

if ( defined($modus) ) {
    while( <CATEGORYLINKS_FILE> ) {
        ($categorylinkSourceId, $categorylinkTargetName) = split(" ", $_);
        my $categorylinkTargetId = $revert_categories_hash{$categorylinkTargetName};
        if (defined($categorylinkTargetId)) {
	    push(@{$graph{$categorylinkTargetId}}, $categorylinkSourceId);
        }
    }
} else {
    while( <CATEGORYLINKS_FILE> ) {
	($categorylinkSourceId, $categorylinkTargetName) = split(" ", $_);
	my $categorylinkTargetId = $revert_categories_hash{$categorylinkTargetName};
	if (defined($categorylinkTargetId)) {
	    push(@{$graph{$categorylinkSourceId}}, $categorylinkTargetId);
	}
    }
}

close( CATEGORYLINKS_FILE );

$start =~ s/ /_/g;
$start = ucfirst($start);

if ($start) {
    push(@todo, revertResolve($start));
} else {
    while ($start = <STDIN>) {
	$start =~ s/\n//;
	$start =~ s/ /_/g;
	$start = ucfirst($start);
	push(@todo, revertResolve($start));
    }
}

while (my $current_id = shift(@todo)) {
    next unless (defined($current_id));
    next if (exists($done{$current_id}));
    my $current_result = resolve($current_id);
    $done{$current_id} = 1;

    foreach my $id (@{$graph{$current_id}}) {
	my $result;
	if (isCategoryId($id)) {
	    $result = resolveCategory($id);
	    unless (exists($done{$id})) {
		push(@todo, $id);
	    }
	}
	else {
	    $result = resolvePage($id);
	}
	
	if ($result) {
	    print "$current_id $id $current_result $result\n";
	}
    }
}    

sub revertResolve {
    if (substr($_[0], 0, 9) eq "Category:") {
	return $revert_categories_hash{substr($_[0], 9)}; 
    } else {
	return $revert_pages_hash{$_[0]};
    }
}

sub resolve {
    if (exists($pages_hash{$_[0]})) {
	return resolvePage($_[0]);
    }
    
    if (isCategoryId($_[0])) {
	return resolveCategory($_[0]);
    }
}

sub resolvePage {
    return $pages_hash{$_[0]};
}

sub resolveCategory {
    return "Category:".$categories_hash{$_[0]};
}

sub isCategoryId {
    return exists($categories_hash{$_[0]});
}
