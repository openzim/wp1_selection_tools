#!/usr/bin/perl
binmode STDOUT, ":utf8";
binmode STDIN, ":utf8";
binmode STDERR, ":utf8";

#use utf8;
use strict;
use warnings;
#use Encode;
use Data::Dumper;
use Compress::Bzip2;

# Get files
my @files = @ARGV;
my $fileCount = scalar(@files);

# Create the fhs
my @fhs;
for my $file (@files) {
    push(@fhs, (bzopen($file, "rb") or die "Cannot open $file: $bzerrno\n") );
}

# Create buffer
my %linesMap;
my %fhsMap;
my @sortedBuffer;

# Read a line
my $line;
sub readLine {
    my $index = shift;
    $fhs[$index]->bzreadline($line);
    $line =~ s/\r|\n//g;

    my $key;
    if ($line =~ /^([\w|\.]+ [^ ]+) ([\d]+) [\d]+/) {
	$key = $1;
    } else {
	return "" unless ($line);
	die "malformed line";
    }

    unless (exists($fhsMap{$key})) {
	$fhsMap{$key} = [()];
    }
    push(@{$fhsMap{$key}}, $index);
    
    unless (exists($linesMap{$key})) {
	$linesMap{$key} = [()];
    }
    push(@{$linesMap{$key}}, $line);

    return $key;
}

# Fill the buffer
sub fillBufferWith {
    my $key = readLine(shift);
    
    return if ($key eq "");

    for (my $i=0; $i<$fileCount; $i++) {
	if (!$sortedBuffer[$i] || $key lt $sortedBuffer[$i]) {
	    splice(@sortedBuffer, $i, 0, $key);
	    last;
	}
    }
}

# Write line
sub writeLine {
    my $key = shift(@sortedBuffer);
    
    print shift(@{$linesMap{$key}})."\n";
    delete($linesMap{$key}) unless (scalar(@{$linesMap{$key}}));

    fillBufferWith(shift(@{$fhsMap{$key}}));
    delete($fhsMap{$key}) unless (scalar(@{$fhsMap{$key}}));
}

# Initiate buffer
sub initBuffer {
    for (my $i=0; $i<$fileCount; $i++) {
	fillBufferWith($i);
    }
}
initBuffer();

# Run through the whole files
do {
    writeLine();
} while (scalar(@sortedBuffer));
