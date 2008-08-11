#!/usr/bin/perl

use locale;
use strict;
use Data::Dumper;

open MAINPAGES, "<:gzip", $ARGV[0] or die;
open LANGLINKS, "<:gzip", $ARGV[1] or die;
open PAGELINKS, "<:gzip", $ARGV[2] or die;
open HITCOUNT,  "<:gzip", $ARGV[3] or die;

#binmode MAINPAGES, ":utf8";
#binmode LANGLINKS, ":utf8";
#binmode PAGELINKS, ":utf8";
#binmode HITCOUNT, ":utf8";
#binmode STDOUT, ":utf8";

my ($ll_page, $ll_count, $ll_line);
my ($pl_page, $pl_count, $pl_line);
my ($hc_page, $hc_count, $hc_line);
my $page_line;

my $line;

$line = <LANGLINKS>;
chomp $line;
($ll_page, $ll_count) = split / /, $line, 2;

$line = <PAGELINKS>;
chomp $line;
($pl_page, $pl_count) = split / /, $line, 2;

$pl_line = 1;

$line = <HITCOUNT>;
chomp $line;
($hc_page, $hc_count) = split / /, $line, 2;

my $page;
my $llinks;
my $plinks;
my $hits;

while ( $page = <MAINPAGES> ) {
  $page_line++;

  if ( 0 == $page_line % 50000) { 
    print STDERR ".";
  }

  chomp $page;
#  print "\n--\npage: '$page' $page_line\n";
#  print "\thc_page: '$hc_page'\n";
#  print "\tpl_page: '$pl_page' at $pl_line\n";
#  print "\tll_page: '$ll_page'\n\n";

  if ( $ll_page lt $page ) { 
    while ( $line = <LANGLINKS> ) { 
      $ll_line++;
      chomp $line;
      ($ll_page, $ll_count) = split / /, $line, 2;
#      print "\tll page $ll_line: $ll_page\n";
      last unless ($ll_page lt $page);
    }
  } else {
#    print "ll $ll_line ok '$ll_page' '$page'\n";
  }

  if ( $pl_page lt $page ) { 
    while ( $line = <PAGELINKS> ) { 
      $pl_line++;
      chomp $line;
      ($pl_page, $pl_count) = split / /, $line, 2;	
#      print "\tpl page $pl_line: '$pl_page' \n";
      last unless ($pl_page lt $page);
    }
  } else {
#    print "pl $pl_line ok '$pl_page' '$page'\n";
  }

  if ( $hc_page lt $page ) { 
    while ( $line = <HITCOUNT> ) { 
      $hc_line++;
      chomp $line;
      ($hc_page, $hc_count) = split / /, $line, 2;
#      print "\tread hc page $hc_line: $hc_page $hc_count\n";
      last unless ($hc_page lt $page);
    }
  } 
#  print "hc $hc_line ok '$hc_page' '$page'\n";

  $llinks = $page eq $ll_page ? $ll_count : 0;
  $plinks = $page eq $pl_page ? $pl_count : 0;
  $hits = $page eq $hc_page ? $hc_count : 0;

  print "$page $llinks $plinks $hits\n";
}
