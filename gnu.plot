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
set term png size 300,200


