#!/usr/bin/perl
use PerlIO::gzip;

#open PAGELINKS, "<:gzip", "pagelinks.lst2.gz" or die;
open MAINPAGES, "<:gzip", "$ARGV[0]" or die;

my $main = get_next_main_id(undef);

my $line;
my @parts;
my $count = 0;
my $output = 0;

while ( $line = <STDIN> ) { 
  $count++;
  if ( 0 == $count % 1000000 ) { 
    print STDERR "filter2 count $count output $output main id $main \n";
    sleep 1;
  }

  @parts = split / /, $line, 2;

  if ( $main > $parts[0]) { 
    next; 
  } elsif ( $main == $parts[0] ) { 
    print STDOUT $parts[1]; 
    $output++;
  } elsif ( $main < $parts[0] ) { 
    $main = get_next_main_id($main);
    if ( $main == $parts[0]) { 
      print STDOUT $parts[1];
      $output++;
    }
  }
}

print STDERR "no more pagelinks entries\n";
exit;

sub get_next_main_id() {
  my $prev = shift;

  my $line;
  my @parts;

  while ($line = <MAINPAGES> ) { 
    @parts = split / /, $line, 4;    
    if ( @parts[0] != $main) { 
      return $parts[0];
    }
  }

  print STDERR "No more main namespace pageids\n";
  exit;
}
