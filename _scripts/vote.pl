#!/usr/bin/perl
use strict;
use JSON;
use File::Slurp;

require 'gs_shared.pl';

my ($target) = shift @ARGV;
my $index    = shift @ARGV;
my @vote_f   = @ARGV;

sub get_votes($$$) {
    my %votes;
    my ($date, $vote_file, $encoding) = @_;
    my $vote_text = read_file($vote_file);    #, $encoding);
    my $total_votes = ($vote_text =~ /TOTAL VOTES: ([0-9]+)/is)[0];
    my $avg_score   = ($vote_text =~ /AVERAGE SCORE: ([0-9\.]+)/is)[0];
    my $vote_num    = 1;
    while ($vote_text =~
        /<img src="(?:[^"]+)?dot_green.gif" height="([0-9]{1,3}(?:\.[0-9]+)?)(E-?[0-9]+)?"/isg
      ) {
        my $perc = $1;
        my $exp  = $2;
        if ($exp =~ /E/ig) {
            $exp =~ s/E//ig;
        } else {
            $exp = 0;
        }
        $votes{$vote_num} = $perc * (10**$exp);
        $vote_num++;
    }

    #scalar @votes or die("No votes found in $vote_file\n$vote_text");
    my $rescale = 0;
    my $sum     = 0;
    if ($rescale) {
        foreach my $v (keys %votes) {
            $sum += $votes{$v};
        }
    } else {

        #this will add zeros votes to match up
        $sum = 100;
    }

    foreach my $v (keys %votes) {
        $votes{$v} = roundoff(($votes{$v} * $total_votes) / $sum, 1);
    }

    #print $total_votes, "\n";
    my $accounted = 0;
    foreach my $v (keys %votes) {
        $accounted += $votes{$v};
    }
    $votes{0} = $total_votes - $accounted;

    my $votes_total = 0;
    foreach my $v (keys %votes) {
        $votes_total += $v * $votes{$v};
    }
    if ($total_votes > 0) {
        $votes_total /= $total_votes;
        if (abs ($votes_total - $avg_score) > 0.05) {
            foreach my $v (sort keys %votes) {
                print "$v :: ", $votes{$v}, " :: ",
                  ($votes{$v} / $total_votes * 100), "\n";
            }
            die (
                "Score for $vote_file is out of margin ($total_votes votes), $votes_total :: $avg_score"
            );
        }
    }

    return %votes;
}

my %votes;
$votes{'id'}    = $index;
$votes{'votes'} = {};

foreach my $v (@vote_f) {
    chomp $v;
    my $date;
    if ($v =~
        m@history/[0-9]+.([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2}).(?:.+?).html@i
      ) {
        my ($y, $m, $d, $h, $min, $s) = ($1, $2, $3, $4, $5, $6);
        $date = sqlite_date_full($y, $m, $d, $h, $min, $s);
    } elsif ($v =~ /archive.gamespy.com/) {
        $date = sqlite_date_full(2009, 12, 9, 15, 45, 37);
    } else {
        my $text = read_file($v);
        if ($text =~
            m@http://web.archive.org/web/([0-9]{4})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})([0-9]{2})@
          ) {
            my ($y, $m, $d, $h, $min, $s) = ($1, $2, $3, $4, $5, $6);
            $date = sqlite_date_full($y, $m, $d, $h, $min, $s);
        } else {
            print "Date Unknown in File $v\n";

            #unknown date
            exit 1;
        }
    }
    my %new_votes = get_votes($date, $v, 'UTF-8');
    $votes{'votes'}{$date} = \%new_votes;
}

write_file($target, to_json(\%votes));
