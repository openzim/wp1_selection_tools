#!/usr/bin/perl

use strict;

my ($page, $oldpage, $ll_count, $ll_tally, $pl_count, $pl_tally,
                     $hit_count, $hit_tally);

my $line = <STDIN>;
chomp $line;

($oldpage, $ll_tally, $pl_tally, $hit_tally) = split / /, $line, 4;


my $i = 0;
while ( $line = <STDIN> ) { 
  $i++;
  if ( 0 == $i % 100000) { print STDERR ":"; }
  chomp $line;

  ($page, $ll_count, $pl_count, $hit_count) = split / /, $line, 4;

  if ( ! ( $page eq $oldpage) ) { 
    print "$oldpage $ll_tally $pl_tally $hit_tally\n";
    $ll_tally = 0;
    $pl_tally = 0;
    $hit_tally = 0;
    $oldpage = $page;
  }  
 
  $ll_tally += $ll_count;
  $pl_tally += $pl_count;
  $hit_tally += $hit_count;
}
  
print "$oldpage $ll_tally $pl_tally $hit_tally\n";

print STDERR "\n";
