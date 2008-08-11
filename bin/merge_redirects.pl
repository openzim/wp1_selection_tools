#!/usr/bin/perl

use locale;
use strict;
use Data::Dumper;

open REDIRECTS, "<:gzip", $ARGV[0] or die;
my ($redirect, $target);
my $line = <REDIRECTS>;
chomp $line;
($redirect, $target) = split / /, $line, 2;

my ($page, $rest);

my $i = 0;
while ( $line = <STDIN> ) { 
  $i++;
  if ( 0 == $i % 100000) { print STDERR "!"; }
  ($page, $rest) = split / /, $line, 2;

  while ( (! eof REDIRECTS) && $redirect lt $page) { 
    $line = <REDIRECTS>;
    chomp $line;
    ($redirect, $target) = split / /, $line, 2;
  }

  if ( $redirect eq $page ) { 
#    print "Found redir $page $target\n";
    $page = $target;
  }

  print $page . " " . $rest ;
}

