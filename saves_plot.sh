#!/bin/bash

data=stats_plot

cat <<EOF | gnuplot -p
set xlabel "Ascensions"
set ylabel "HS/min for Transcension"
set grid
set logscale y
plot "<(grep ^1 \"$data\" | uniq)" u 2:6 w lp title "1st Trans", \
     "<(grep ^2 \"$data\" | uniq)" u 2:6 w lp title "2nd Trans", \
     "<(grep ^3 \"$data\" | uniq)" u 2:6 w lp title "3rd Trans"
EOF

cat <<EOF | gnuplot -p
set xlabel "Ascensions"
set ylabel "HS/min for Transcension"
set grid
#set logscale y
plot "<(grep ^1 \"$data\" | uniq)" u 2:6 w lp title "1st Trans", \
     "<(grep ^2 \"$data\" | uniq)" u 2:6 w lp title "2nd Trans", \
     "<(grep ^3 \"$data\" | uniq)" u 2:6 w lp title "3rd Trans"
EOF

cat <<EOF | gnuplot -p
set xlabel "Ascensions"
set ylabel "Highest Zone"
set grid
plot "<(grep ^1 \"$data\" | uniq)" u 2:3 w lp title "1st Trans", \
     "<(grep ^2 \"$data\" | uniq)" u 2:3 w lp title "2nd Trans", \
     "<(grep ^3 \"$data\" | uniq)" u 2:3 w lp title "3rd Trans"
EOF

cat <<EOF | gnuplot -p
set xlabel "Ascensions"
set ylabel "HS/min"
set logscale y
plot "<(grep ^1 \"$data\" | uniq)" u 2:6 w lp title "1st Trans - T", \
     "<(grep ^2 \"$data\" | uniq)" u 2:6 w lp title "2nd Trans - T", \
     "<(grep ^3 \"$data\" | uniq)" u 2:6 w lp title "3rd Trans - T", \
     "<(grep ^1 \"$data\" | uniq)" u 2:7 w lp title "1st Trans - A", \
     "<(grep ^2 \"$data\" | uniq)" u 2:7 w lp title "2nd Trans - A", \
     "<(grep ^3 \"$data\" | uniq)" u 2:7 w lp title "3rd Trans - A"
EOF

cat <<EOF | gnuplot -p
set xlabel "Ascensions"
set ylabel "Minutes"
set y2label "Highest Zone"
set y2tics
set grid
plot "<(grep ^1 \"$data\" | uniq)" u 2:5 axes x1y1 w lp title "1st Trans Time", \
     "<(grep ^2 \"$data\" | uniq)" u 2:5 axes x1y1 w lp title "2nd Trans Time", \
     "<(grep ^3 \"$data\" | uniq)" u 2:5 axes x1y1 w lp title "3rd Trans Time", \
     "<(grep ^1 \"$data\" | uniq)" u 2:3 axes x1y2 w lp title "1st Trans HZE", \
     "<(grep ^2 \"$data\" | uniq)" u 2:3 axes x1y2 w lp title "2nd Trans HZE", \
     "<(grep ^3 \"$data\" | uniq)" u 2:3 axes x1y2 w lp title "3rd Trans HZE"
EOF
