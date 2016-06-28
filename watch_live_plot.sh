#!/bin/bash

plot_file=./live_plots/live_plot

while inotifywait -q -e close_write "$plot_file" >/dev/null ; do
    data=$(cat "$plot_file")
    plot_str=$(echo "$data" | sed -n '1,/^plot/p')
    plot_data=$(echo "$data" | sed -e '1,/^plot/d' -e '$ d')

    plot_str=$(echo "$plot_str" | \
               sed "s/^\(plot.*\)/\1 axes x1y1/")
    cat <<EOF
set y2label "HZE"
set y2tics
$plot_str, "-" u 4:3 axes x1y2 w lp title "Zone"
$plot_data
e
$plot_data
e
EOF
done > >(gnuplot -p)
