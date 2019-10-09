#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../classes/";

use utf8;
use Config;
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use Mediawiki::Mediawiki;

# get the params
my $host = "";
my $path = "";
my $readFromStdin;
my @titles;
my @languages;

# Get console line arguments
GetOptions('host=s' => \$host, 
	   'path=s' => \$path,
	   'readFromStdin' => \$readFromStdin,
	   'title=s' => \@titles,
	   'language=s' => \@languages,
	   );

if (!$host || ( !scalar(@titles) && !$readFromStdin) || !scalar(@languages)) {
    print "usage: ./listLangLinks.pl --sourceSite=enwiki [--title=Paris] [--readFromStdin] [--language=fr]\n";
    exit;
}

# readFromStdin
if ($readFromStdin) {
    while (my $title = <STDIN>) {
	utf8::decode($title);
        $title =~ s/\n//;
        push(@titles, $title);
    }
}

# Site
my $site = Mediawiki::Mediawiki->new();
$site->hostname($host);
$site->path($path);

# Go over the title list
foreach my $title (@titles) {
    my %langLinks = map { $_->{lang} => $_->{content} } @{$site->langLinks($title)};
    foreach my $language (@languages) {
	my $line = $title."\t".$language."\t".($langLinks{$language} || "")."\n";
	utf8::encode($line);
	print $line;
    }
}

exit;
