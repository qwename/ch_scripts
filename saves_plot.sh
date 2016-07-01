#!/bin/bash

COL_T=1
COL_A=2
COL_HZE=3
COL_LAST_T=4
COL_LAST_A=5
COL_HS_PER_MIN_T=6
COL_HS_PER_MIN_A=7
COL_HS_SAC=8
COL_TOTAL_HS=9
COL_CURRENT_AS=10
COL_ADD_AS=11

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
transcensions=($(echo "$plot_data" | cut -d' ' -f $COL_T | sort -n | uniq))
ascensions=($(echo "$plot_data" | cut -d' ' -f $COL_A | sort -n | uniq))
addOneAS=$(echo "$plot_data" | \
           cut -d' ' -f $COL_A,$COL_CURRENT_AS,$COL_ADD_AS | \
           sort -k 1,1n -k 3,3n | \
           sed -n '/^\([0-9]\+ \)\{2\}1$/p')
addOneAS_x=($(echo "$addOneAS" | cut -d' ' -f 1))
addOneAS_y=($(echo "$addOneAS" | cut -d' ' -f 2))

if (( ${#transcensions[@]} == 0 )); then
    echo >&2 "No transcensions found"
    exit 1
fi

plot1_cols="$COL_A:$COL_HS_PER_MIN_T"
plot1_title="HS/min"
plot1_label="HS/min (Transcension)"
plot1="'-' u $plot1_cols w lp title '$plot1_title, \1 Transcensions' axes x1y1"
plots="$plot1, "

#plot2_cols="$COL_A:$COL_HZE"
#plot2_title="HZE"
#plot2_label="HZE"
plot2_cols="$COL_A:$COL_CURRENT_AS"
plot2_title="AS"
plot2_label="Ancient Souls"
plot2="'-' u $plot2_cols w lp title '$plot2_title, \1 Transcensions' axes x1y2"

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

lines=
for i in $(eval echo {0..$((${#addOneAS_x[@]}-1))}); do
    x_coord=${addOneAS_x[$i]}
    y_coord=${addOneAS_y[$i]}
    lines="set arrow from second $x_coord,0 to second $x_coord,$y_coord nohead"$'\n'$lines
    lines="set arrow from second $x_coord,$y_coord to second $xrange_end,$y_coord nohead"$'\n'$lines
done

plot=$(cat <<EOF
set title "$title"
set grid
set xlabel "Ascensions"
set ylabel "$plot1_label"
set y2label "$plot2_label"
set y2tics
set autoscale
set xrange [$xrange_beg:$xrange_end]
#set nokey
set key left top
$lines
$plot_str
EOF
)

for transcends in ${transcensions[@]}; do
    cols=$((COL_T-1))
    transcends_data=$(echo "$plot_data" | \
                         sed -n "/^\([^ ]\+ \+\)\{$cols\}$transcends /p")
    plot=$plot$'\n'$transcends_data$'\n'e
    for p in "${more_plots[@]}"; do
        plot=$plot$'\n'$transcends_data$'\n'e
    done
done


echo "$plot"
