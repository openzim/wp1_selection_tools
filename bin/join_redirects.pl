#!/usr/bin/perl

use PerlIO::gzip;

open MAINPAGES, "<:gzip", $ARGV[0] or die;
open REDIRECTS, "<:gzip", $ARGV[1] or die;
open PAGELINKS, "<:gzip", $ARGV[2] or die;

#open OUT, ">:gzip", $ARGV[3];

my @main;
my @redir;
my @pagelinks;

my $ok = 0;  # redirects found in redirects table
my $okp = 0; # redirects guessed from pagelinks table
my $error = 0;

chomp($line = <REDIRECTS>);
@redir = split / /, $line, 3;
print "$redir[0] $redir[2]\n";

chomp($line = <PAGELINKS>);
@pagelinks = split / /, $line, 3;
print "$pagelinks[0] $pagelinks[1]\n";

my $count = 0;

while( $line = <MAINPAGES>) {
  $count++;
  $countb++;
  if ( 0 == $ok % 30000) { 
#    print STDERR "Count: $count\tOK: $ok / $okp\tERROR: $error | $main[0] $redir[0] $pagelinks[0]\n";
    print STDERR ".";
  }

  chomp $line;
  @main = split / /, $line, 4;

  next unless ( $main[3] == 1);

  while ( $redir[0] < $main[0] ) { 
    $countb++;
    if ( 0 == $countb % 100000) { 
#      print STDERR "Count: $count\tOK: $ok / $okp\tERROR: $error | $main[0] $redir[0] $pagelinks[0]\n";
    }
  
    chomp($line = <REDIRECTS>);
    @redir = split / /, $line, 3;
  }

  if ( $redir[0] == $main[0] ) { 
#    print "OK $main[0] $main[2] -> $redir[2]\n";
     print  "$main[2] $redir[2]\n";
     $ok++; 
  } else { 
    while ( $pagelinks[0] < $main[0] ) { 
      $countb++;
      if ( 0 == $countb % 1000000) { 
#        print STDERR "Count: $count\tOK: $ok / $okp\tERROR: $error | $main[0] $redir[0] $pagelinks[0]\n";
      }

      chomp($line = <PAGELINKS>);
      @pagelinks = split / /, $line, 3;
    }

    if ( $pagelinks[0] == $main[0] ) { 
      $okp++;
      print "$main[2] $pagelinks[1]\n";
    } else { 
#	 print "ERROR $main[0] $main[2] no target / next is $redir[0] $redir[2]\n";
     $error++;
    }
  }
}

print STDERR "\nFinal count: $count  OK: $ok / $okp ERRORS: $error\n";
