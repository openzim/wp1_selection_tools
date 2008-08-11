#!/usr/bin/perl

use PerlIO::gzip;

open MAIN, "<:gzip", $ARGV[0];
open IN, "<:gzip", $ARGV[1];

my $a;
my $b;
my $line;

my ($main_id, $main_rest);
$line = <MAIN>;
chomp $line;
($main_id, $main_rest) = split / /, $line, 2;

while ( $line = <IN> ) { 
  $count++;
  if ( 0 == $count % 1000000) { print STDERR "."; }
  ($a, $b) = split / /, $line, 2;

  while ( $a > $main_id) {
    $line = <MAIN>;
    chomp $line;
    ($main_id, $main_rest) = split / /, $line, 2;
  }
 
  if ( $main_id == $a) { 
    print $b;
  }
}
print STDERR "\nSorting.\n";
