#!/usr/bin/perl

use strict;
use warnings;
use utf8;

my $path_prefix = shift || "";
my $page_path = "${path_prefix}pages.lzma";
my $pagelinks_path = "${path_prefix}pagelinks.lzma";

my %pages;
my $FILE;

# Put pages in memory
open $FILE, "lzma -9 -T 0 -dc $page_path |" or die "Could not open $page_path: $!";
while (<$FILE>) {
    my $line = $_;
    chomp($line);
    my ($pageId, $pageTitle) = split("\t", $line);
    $pages{$pageTitle} = $pageId;
}

# Match pagelinks
open $FILE, "lzma -9 -T 0 -dc $pagelinks_path |" or die "Could not open $pagelinks_path: $!";
while (<$FILE>) {
    my $line = $_;
    chomp($line);
    my ($sourcePageId, $targetPageTitle) = split("\t", $line);
    print "$sourcePageId ".($pages{$targetPageTitle} || "")."\n";
}

1
