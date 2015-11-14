#!/usr/bin/perl
use strict;
use File::Temp;
use JSON;
use File::Slurp;

sub bynumeric {
    int ($a) <=> int ($b);    # presuming numeric
}

require 'gs_shared.pl';

my ($histogram_out, $history_out, $id, $vote) = @ARGV;

my $plot_const = '
set datafile separator ","
set dummy jw
set grid x y2
set key out horiz bot center
set title "Score/Votes over Time"
set xlabel "Date" offset 0,-1,0
set xdata time
set timefmt "%Y-%m-%d %H:%M:%S"
#set xrange  ["2000-01-01 00:00:00":"2010-01-01 00:00:00"]
#set x2range ["2000-01-01 00:00:00":"2010-01-01 00:00:00"]
set ylabel "Votes"
set y2label "Score"
set ytics nomirror
set y2tics
set tics out
set autoscale y
set yrange [0:*]
set y2range [0:10]

set term png size 600,400
#xtics is seconds in a year
set xtics rotate by -45 31536000 format "%Y-%b"
';

sub total_votes($) {
    my ($vote) = @_;
    my $sum = 0;
    foreach my $num (keys %$vote) {
        $sum += $vote->{$num};
    }
    return $sum;
}

sub vote_score($) {
    my ($vote) = @_;
    my $score  = 0;
    my $total  = total_votes($vote);

    foreach my $num (keys %$vote) {
        $score += $vote->{$num} * int ($num);
    }
    if ($total == 0) {
        $score = 0;
    } else {
        $score /= $total;
    }
    return $score;
}

my $json = from_json(read_file($vote));    #, 'UTF-8'));
print "Plotting ", $id, "\n";
open my $pipe, "| gnuplot -p > $histogram_out";

#open my $pipe, ">-";

my @dates      = sort keys %{$json->{'votes'}};
my $date_count = scalar @dates;

foreach my $d (keys %{$json->{'votes'}}) {
    delete $json->{'votes'}->{$d}->{'0'};
}

my $max_vote = $json->{'votes'}->{$dates[$date_count - 1]};

my $plot =
"
set boxwidth 0.75
set key off
set style fill solid 1.00 border lt -1
#set key inside right top vertical Right noreverse noenhanced autotitles nobox
#set style histogram clustered gap 1 title  offset character 0, 0, 0
#set datafile missing '-'
set style data histograms
set xtics border in scale 0,0 nomirror   offset character 0, 0, 0 autojustify
set xtics  norangelimit font \",8\"
set xtics   ()
#set title \"Histogram of Votes\" 
set yrange [ 0 : 100 ] noreverse nowriteback
set ylabel \"Percentage\"
unset ytics
#set xrange [ 0 : 10]
set border 3
set term png size 300,200
";
print $pipe $plot;
print $pipe 'plot "-" using 1:3:xtic(2) with boxes lt rgb "#006600"', "\n";

my $vote_total = total_votes($max_vote);

foreach my $v (sort bynumeric keys %$max_vote) {
    my $perc = (($max_vote->{$v} * 100) / $vote_total);
    print $pipe "$v $v " . $perc . "\n";
}

my $data = File::Temp->new();

#open my $data, ">-";

foreach my $d (sort keys %{$json->{'votes'}}) {
    my $vote = $json->{'votes'}->{$d};
    print $data $d, ",", total_votes($vote), ",", vote_score($vote), "\n";
}
close $data;

my $plot_file = $plot_const . "\n"
  . "plot \"$data\" using 1:2 axes x1y1  title 'Votes' with linespoints, \\
      \"$data\" using 1:3 axes x1y2 title 'Score' with linespoint"
  ;

open my $pipe, "| gnuplot > $history_out";

print $pipe $plot_file;
close $pipe;
