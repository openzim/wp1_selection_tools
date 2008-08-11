#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use PerlIO::gzip;

my $categoryGraphFile="";

GetOptions('categoryGraphFile=s' => \$categoryGraphFile );

if ( !$categoryGraphFile ) {
    print "usage: ./simplify_category_graph.pl --categoryGraphFile=category_graph.lst.gz\n";
    exit;
};

my ($childId, $parentId, $childName, $parentName);
my %graph;
my %rgraph;
my %hash;

open( CATEGORY_GRAPH_FILE, '<:gzip', $categoryGraphFile ) or die("Unable to open file $categoryGraphFile.\n");
while( <CATEGORY_GRAPH_FILE> ) {
    ($childId, $parentId, $childName, $parentName) = split(" ", $_);
    
    unless (exists($hash{$childId})) {
	$hash{$childId} = $childName;
    }

    unless (exists($hash{$parentId})) {
	$hash{$parentId} = $parentName;
    }

    unless (exists($graph{$parentId})) {
	$graph{$parentId} = [()];
    }
    push(@{$graph{$parentId}}, $childId);

    unless (exists($rgraph{$childId})) {
	$rgraph{$childId} = [()];
    }
    push(@{$rgraph{$childId}}, $parentId);
}
close( CATEGORY_GRAPH_FILE );

my $reducedNodeCount = 0;
sub reduceNode {
    my $nodeId = shift;

    return 0 unless (exists($graph{$nodeId}) && exists($rgraph{$nodeId}) );

    my $index;
    my @children = @{$graph{$nodeId}};
    my @parents = @{$rgraph{$nodeId}};

    foreach $parentId (@parents) {
	$index = 0;
	foreach $childId (@{$graph{$parentId}}) {
	    if ($childId eq $nodeId) {
		splice(@{$graph{$parentId}}, $index, 1);
	    }
	    $index += 1;
	}
	foreach $childId (@children) {
	    unless (grep /$childId/, @{$graph{$parentId}}) {
		unless ($childId eq $nodeId) {
		    push(@{$graph{$parentId}}, $childId);
		}
	    }
	}
    }
    
    foreach $childId (@children) {
	$index = 0;
	foreach $parentId (@{$rgraph{$childId}}) {
	    if ($parentId eq $nodeId) {
		splice(@{$rgraph{$childId}}, $index, 1);
	    }
	    $index += 1;
	}
	foreach $parentId (@parents) {
	    unless (grep /$parentId/, @{$rgraph{$childId}}) {
		unless ($parentId eq $nodeId) {
		    push(@{$rgraph{$childId}}, $parentId);
		}
	    }
	}
    }
    
    delete($graph{$nodeId});
    delete($rgraph{$nodeId});
    delete($hash{$nodeId});    

    $reducedNodeCount += 1;

    return 1;
}

my $todo;
do {
    $todo = 0;
    foreach $parentId (keys(%graph)) {
	if (scalar(@{$graph{$parentId}}) < 50) {
	    $todo = reduceNode($parentId);
	}
    }
} while ($todo);

foreach $parentId (keys(%graph)) {
    foreach $childId (@{$graph{$parentId}}) {

	unless (exists($hash{$childId})) {
	    print STDERR "Problem with hash key $childId for node $parentId\n";
	}

	unless (exists($hash{$parentId})) {
	    print STDERR "Problem with hash key $parentId for node $parentId\n";
	}

	print "$childId $parentId $hash{$childId} $hash{$parentId}\n";
    }
}


