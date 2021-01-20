#!/usr/bin/env python
import subprocess
import sqlite3
import argparse
import re
import frontmatter
import os
import tempfile
import sys

def touch(path):
    with open(path, 'a'):
        os.utime(path, None)
        
def get_score(fm, date):
    score = 0
    count = 0
    history_date = filter(lambda d: d['date'] == date, fm['history'])
    if len(history_date) == 1:
        scores = history_date[0]['votes'];
        scores = zip(range(1,11), scores)
        for (key, val) in scores:
            score += int(key) * int(val)
            count += int(val)
        score /= float(count)

    return (score, count)

parser = argparse.ArgumentParser(description='Process History into Frontmatter')
parser.add_argument('article_fm', help='article fm')
parser.add_argument('target_histogram', help='Histogram Chart of Votes')
parser.add_argument('target_history', help='History Chart Scores vs. Votes')
args = parser.parse_args()

fm = frontmatter.load(args.article_fm)

scoredate = "2009-12-09 15:45:37"
score = filter(lambda x : x['date'] == scoredate, fm['history'])

if len(score) == 1:
    plot = subprocess.Popen(['gnuplot'], stdin=subprocess.PIPE)
    plot.stdin.write(
        """
        set term png size 300,200
        set output "%s"\n
        """ % args.target_histogram
    )
    plot.stdin.write(
        """
        set boxwidth 0.75
        set key off
        set style fill solid 1.00 border lt -1
        #set key inside right top vertical Right noreverse noenhanced autotitles nobox
        #set style histogram clustered gap 1 title  offset character 0, 0, 0
        #set datafile missing '-'
        set style data histograms
        set xtics border in scale 0,0 nomirror   offset character 0, 0, 0 autojustify
        set xtics  norangelimit font ",8"
        set xtics   ()
        #set title "Histogram of Votes" 
        set yrange [ 0 : 100 ] noreverse nowriteback
        set ylabel "Percentage"
        unset ytics
        #set xrange [ 0 : 10]
        set border 3
        plot "-" using 1:3:xtic(2) with boxes lt rgb "#006600"
        """
    )

    zipped_votes = zip(range(1,11), score[0]['votes'])
    total = sum(score[0]['votes'])
    for (d, v) in zipped_votes:
        plot.stdin.write("%d %d %f\n" % (d, d, (v / float(total)) * 100))

    plot.stdin.write("e\n")
    plot.communicate()
else:
    touch(args.target_histogram)
    
if len(fm['history']) > 1:
    plot = subprocess.Popen(['gnuplot'], stdin=subprocess.PIPE)
    plot.stdin.write(
        """
        set term png size 600,400
        set output "%s"\n
        """ % args.target_history
    )
    plot.stdin.write(
        """
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
        """)

    history_data = tempfile.NamedTemporaryFile('w', delete=False)
    for h in fm['history']:
        score = get_score(fm, h['date'])              
        history_data.file.write(",".join([h['date'], str(score[1]), str(score[0])]) + "\n")
    history_data.close()      

    plot.stdin.write("""
        plot "%s" using 1:2 axes x1y1  title 'Votes' with linespoints, \\
             "%s" using 1:3 axes x1y2 title 'Score' with linespoint
    """ % (history_data.name, history_data.name))

    plot.communicate()

    os.unlink(history_data.name)
else:
    touch(args.target_history)
