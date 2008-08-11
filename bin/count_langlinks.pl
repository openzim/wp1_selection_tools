#!/usr/bin/perl

use strict;

use PerlIO::gzip;

open MAINPAGES, "<:gzip", $ARGV[0] or die;
open LANGLINKS, "<:gzip", $ARGV[1] or die;

my ($main_id, $ns, $title, $redir);
my ($ll_id, $otherwiki, $othertitle);

my $line = <MAINPAGES>;
($main_id, $ns, $title, $redir) = split / /, $line, 4;

$line = <LANGLINKS>;
($ll_id, $otherwiki, $othertitle) = split / /, $line, 3;

my $count = 0;

my $i = 0;

LOOP: while ( $line = <LANGLINKS> ) { 
  
  ($ll_id, $otherwiki, $othertitle) = split / /, $line, 3;

  next LOOP if ($main_id > $ll_id);

  while ( $main_id < $ll_id ) { 
    $i++;
    if ( 0 == $i % 100000) { print STDERR ".";}
    if ( $title =~ /[A-Za-z]/ ) { 
      print "$title $count\n";
    }

    $count = 0;
    my $line = <MAINPAGES>;
    last LOOP unless ($line);
    ($main_id, $ns, $title, $redir) = split / /, $line, 4;
  }

  if ($main_id == $ll_id) { 
    $count++;
  }

}

print STDERR "\n";
