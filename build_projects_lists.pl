#!/usr/bin/perl

use strict;
use warnings;
use utf8;

my %scores;
my %projectsFds;

# Check if directory and files exist
my $dir = $ARGV[0] || "";
my $scoresFile = "$dir/scores";
my $allFile = "$dir/all";

if (!-d $dir) {
    print STDERR "Directory '$dir' does not exist, is not a directory or is not readable.\n";
    exit 1;
}

unless (-f $scoresFile && -f $allFile) {
    print STDERR "Files '$scoresFile' or '$allFile' do not exist, or are not readable.\n";
    exit 1;
}

# Create project directory
my $projectsDir = "$dir/projects";
if (!-d $projectsDir) {
    print STDERR "Creating directory '$projectsDir'...\n";
    mkdir $projectsDir;
}

# Open 'scores' file
print STDERR "Reading $scoresFile...\n";
open(FILE, '<', $scoresFile) or die("Unable to open file '$scoresFile'\n");
while(<FILE>) {
    my $line = $_;
    chomp($line);
    my ($pageTitle, $pageScore) = split("\t", $line);
    $scores{$pageTitle} = $pageScore;
}
close(FILE);

# Open 'all' file
print STDERR "Reading $allFile...\n";
open(FILE, '<', $allFile) or die("Unable to open file '$allFile'\n");
while(<FILE>) {
    my $line = $_;
    chomp($line);
    my ($pageTitle, $pageId, $pageSize, $pageLinksCount, $langLinksCount, $pageViewsCount, @pageRatings) = split("\t", $line);
    for my $pageRating (@pageRatings) {
        my ($project, $rating) = split("=", $pageRating);
        my $fd = getProjectFd($project);
        print $fd $pageTitle."\t".$scores{$pageTitle}."\n";
    }
}
close(FILE);

# Close all projects fds
for my $project (keys(%projectsFds)) {
    close($projectsFds{$project});
}

# Sorting all project files
opendir(DIR, $projectsDir) or die("Unable to open directory '$projectsDir'\n");
while (my $projectFile = readdir(DIR)) {
    next unless ($projectFile =~ m/\.tmp$/);
    $projectFile = "$projectsDir/$projectFile";
    my $newProjectFile = $projectFile;
    $newProjectFile =~ s/\.tmp$//m;
    print STDERR "Sorting $projectFile to $newProjectFile\n";
    my $cmd = qq(cat "$projectFile" | sort -k2 -n -r | awk '!a[\$0]++' | cut -f1 > "$newProjectFile");
    system $cmd;
    $cmd = qq(rm "$projectFile"); `$cmd`;
}
closedir(DIR);

# Exit
print STDERR "Finishing...\n";
exit 0;

sub getProjectFd {
    my $project  = shift;

    return $projectsFds{$project} if exists($projectsFds{$project});

    my $project_escaped = $project =~ s/\//_/gr;
    my $projectFile = "$projectsDir/$project_escaped.tmp";
    print STDERR "Opening project file '$projectFile'...\n";
    open($projectsFds{$project}, '>', $projectFile) or die("Unable to open file '$projectFile'\n");
    $projectsFds{$project}
}
