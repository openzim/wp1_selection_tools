#!/usr/bin/perl

use strict;
use warnings;
use utf8;

# Globale variables
my %topRatings;
my %counts;
my %qualityScores = (
    "FA-Class"    => 500,
    "FL-Class"    => 500,
    "A-Class"     => 400,
    "GA-Class"    => 400,
    "Bplus-Class" => 350,
    "B-Class"     => 300,
    "C-Class"     => 225,
    "Start-Class" => 150,
    "Stub-Class"  => 50,
);
my %importanceScores = (
    "Top-Class"   => 400,
    "High-Class"  => 300,
    "Mid-Class"   => 200,
    "Low-Class"   => 100,
);

# Check if directory exists
my $allFile = $ARGV[0] || "";
if (!-f $allFile) {
    print STDERR "File '$allFile' does not exist. You have to call build_scores.pl with as argument the Wikipedia WP1 'all' file.\n";
    exit 1;
}

# Open 'all' file
print STDERR "Reading $allFile...\n";
open(FILE, '<', $allFile) or die("Unable to open file $allFile\n");
while(<FILE>) {
    my $line = $_;
    chomp($line);
    my ($pageTitle, $pageId, $pageSize, $pageLinksCount, $langLinksCount, $pageViewsCount, @pageRatings) = split("\t", $line);
    catch_top_ratings($pageLinksCount, $langLinksCount, $pageViewsCount, @pageRatings);
    $counts{$pageTitle} = {
        P  => extract_projects(@pageRatings),
        Q  => compute_internal_quality(@pageRatings),
        IA => compute_internal_importance(@pageRatings),
        XS => compute_external_importance($pageLinksCount, $langLinksCount, $pageViewsCount)
    };
}
close(FILE);

# Compute projects scores
for my $project (keys(%topRatings)) {
    my $count = $topRatings{$project}{count};
    $topRatings{$project}{score} = int((compute_external_importance(
        $topRatings{$project}{pageLinksCount} / $count,
        $topRatings{$project}{langLinksCount} / $count,
        $topRatings{$project}{pageViewsCount} / $count
    ) - 1000) / 2);
}

# Output results
print STDERR "Printing scores...\n";
for my $article (keys(%counts)) {
    print "$article\t".compute_final_score($article)."\n";
}

# Compute the final score
sub compute_final_score {
    my $pageTitle = shift;

    $counts{$pageTitle}{Q} + $counts{$pageTitle}{IA} +
        compute_article_project_score(split(/ /, $counts{$pageTitle}{P})) +
        $counts{$pageTitle}{XS}
}

# Compute wikiproject scope points
sub compute_article_project_score {
    my $project_score = 0;

    for my $project (@_) {
        if (($topRatings{$project}{score} || 0) > $project_score) {
            $project_score = $topRatings{$project}{score}
        }
    }

    $project_score
}

# Keep track of top rated articles
sub catch_top_ratings {
    my ($pageLinksCount, $langLinksCount, $pageViewsCount, @pageRatings) = @_;
    for my $pageRating (@pageRatings) {
        if ($pageRating =~ m/(.+?)=([^:]+):(.+)/) {
            my ($project, $quality, $importance) = ($1, $2, $3);
            if ($importance eq "Top-Class") {

                if (!exists($topRatings{$project})) {
                    $topRatings{$project} = { count => 0, pageLinksCount => 0,
                                              langLinksCount => 0, pageViewsCount => 0 }
                }

                $topRatings{$project}{count} += 1;
                $topRatings{$project}{langLinksCount} += $langLinksCount;
                $topRatings{$project}{pageViewsCount} += $pageViewsCount;
                $topRatings{$project}{pageLinksCount} += $pageLinksCount;
            }
        } else {
            die "Unable to parse rating $pageRating";
        }
    }
}

# Compute internal quality score
sub compute_internal_quality {
    my (@pageRatings) = @_;
    my $count = 0;
    my $quality_total = 0;

    for my $pageRating (@pageRatings) {
        if ($pageRating =~ m/(.+?)=([^:]+):(.+)/) {
            my $quality = $2;
            if (exists($qualityScores{$quality})) {
                $quality_total += $qualityScores{$quality};
            }
            $count++;
        } else {
            die "Unable to parse rating $pageRating";
        }
    }

    $quality_total ? int($quality_total / $count) : 0;
}

# Compute Wikiproject importance score
sub compute_internal_importance {
    my (@pageRatings) = @_;
    my $count = 0;
    my $importance_total = 0;

    for my $pageRating (@pageRatings) {
        if ($pageRating =~ m/(.+?)=([^:]+):(.+)/) {
            my $importance = $3;
            if (exists($importanceScores{$importance})) {
                $importance_total += $importanceScores{$importance};
            }
            $count++;
        } else {
            die "Unable to parse rating $pageRating";
        }
    }

    $importance_total ? int($importance_total / $count) : 0;
}

# Compute external importance score
sub compute_external_importance {
    my ($pageLinksCount, $langLinksCount, $pageViewsCount) = @_;

    int(50 * myLog10($pageViewsCount) + 100 * myLog10($pageLinksCount) + 250 * myLog10($langLinksCount))
}

# get the list of projects
sub extract_projects {
    my $projects = "";

    for my $pageRating (@_) {
        if ($pageRating =~ m/(.+?)=([^:]+):(.+)/) {
            $projects .= $projects ? " " : "";
            $projects .= $1;
        } else {
            die "Unable to parse rating $pageRating";
        }
    }

    $projects
}

# Tools
sub myLog10 {
    my $value = shift;
    $value ? log($value)/log(10) : 0;
}

# Exit
print STDERR "Finishing...\n";
exit 0;
