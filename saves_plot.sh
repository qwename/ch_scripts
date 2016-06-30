#!/bin/bash

COL_TRANSCENDS=1
COL_ASCENDS=2
COL_HZE=3
COL_LAST_TRANS=4
COL_HS_PER_MIN=6

usage() {
    cat <<EOF
Usage: $0 [TRANSCENSIONS] [XRANGE-BEG] [XRANGE-END]
Outputs commands suitable for piping into gnuplot.
TRANSCENSIONS can be a number to limit to viewing one transcension, or '*' for
all transcensions.
XRANGE-BEG and XRANGE-END changes the x interval of the plot.
EOF
}

if [[ $1 =~ ^((--)?help|-h)$ ]]; then
    usage
    exit
fi

transcension=$1
xrange_beg=$2
xrange_end=$3

if [[ $transcension =~ ^\*$ ]]; then
    transcension=
fi
if [[ -n $transcension && ! $transcension =~ ^[0-9]+$ ]]; then
    echo >&2 "Not a valid transcension number: '$transcension'"
    exit 1
fi

file=./stats_plot
[[ -f $file ]] || exit 1

regex="^[0-9]"
if [[ -n $transcension ]]; then
    regex="^$transcension "
fi

plot_data=$(grep "$regex" "$file")
transcensions=($(echo "$plot_data" | cut -d' ' -f 1 | sort -n | uniq))
ascensions=($(echo "$plot_data" | cut -d' ' -f 2 | sort -n | uniq))

if (( ${#transcensions[@]} == 0 )); then
    echo >&2 "No transcensions found"
    exit 1
fi

plot1="'-' u $COL_ASCENDS:$COL_HS_PER_MIN w lp title 'HS/min, \1 Transcensions' axes x1y1"
plots="$plot1, "

plot2="'-' u $COL_ASCENDS:$COL_HZE w lp title 'HZE, \1 Transcensions' axes x1y2"
more_plots=("$plot2")
for p in "${more_plots[@]}"; do
    plots="$plots$p, "
done

plot_str="plot $(echo ${transcensions[@]} | \
                 sed -e "s|\([0-9]\+\)|$plots|g" -e "s/, $//")"

if [[ -z $xrange_beg ]]; then
    xrange_beg=${ascensions[0]}
    if (( $xrange_beg > 0 )); then
        xrange_beg=$((xrange_beg - 1))
    fi
fi
if [[ -z $xrange_end ]]; then
    xrange_end=$((${ascensions[-1]} + 1))
fi

title="${#transcensions[@]} Transcensions"
if [[ -n $transcension ]]; then
    title="Transcension $transcension"
fi

plot=$(cat <<EOF
set title "$title"
set grid
set xlabel "Ascensions"
set ylabel "HS/min (Transcension)"
set y2label "HZE"
set y2tics
set autoscale
set xrange [$xrange_beg:$xrange_end]
#set nokey
set key left top
$plot_str
EOF
)

for transcends in ${transcensions[@]}; do
    cols=$((COL_TRANSCENDS-1))
    transcends_data=$(echo "$plot_data" | \
                         sed -n "/^\([^ ]\+ \+\)\{$cols\}$transcends /p")
    plot=$plot$'\n'$transcends_data$'\n'e
    for p in "${more_plots[@]}"; do
        plot=$plot$'\n'$transcends_data$'\n'e
    done
done

echo "$plot"
