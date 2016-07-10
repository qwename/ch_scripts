#!/bin/bash

COL_T=1
COL_A=2
COL_HZE=3
COL_LAST_T=4
COL_LAST_A=5
COL_HS_PER_MIN_T=6
COL_HS_PER_MIN_A=7
COL_HS_SAC=8
COL_HS_T=9
COL_HS_A=10
COL_TOTAL_AS=11
COL_CURRENT_AS=12
COL_ADD_AS=13
COL_TIME=14

TITLES=(Transcensions Ascensions HZE 'Time (T)' 'Time (A)' 'HS/min (T)'
        'HS/min (A)' 'HS Sacrificed' 'HS (T)' 'HS (A)'
        'Total AS' AS '+AS' 'Time')

LABELS=(Transcensions Ascensions 'Highest Zone Ever (HZE)' 
        'Time (Since Last Transcension)' 'Time (Since Last Ascension)'
        'HS/min (Transcension)' 'HS/min (Ascension)'
        'HS Sacrificed' 'HS (Transcension)' 'HS (Ascension)'
        'Total Ancient Souls (AS)' 'Ancient Souls (AS)' '+Ancient Souls (+AS)'
        'Time (Overall)')

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
if [[ -n $transcension && \
      ! $transcension =~ ^([0-9]+|\[[0-9]+-[0-9]+\])$ ]]; then
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

if (( ${#transcensions[@]} == 0 )); then
    echo >&2 "No transcensions found"
    exit 1
fi

ascensions=($(echo "$plot_data" | cut -d' ' -f $COL_A | sort -n | uniq))

trans_data=()
trans_data_str=
for transcends in ${transcensions[@]}; do
    cols=$((COL_T-1))
    data=$(echo "$plot_data" | sed -n "/^\([^ ]\+ \+\)\{$cols\}$transcends /p")
    data=$data$'\n'e
    trans_data[transcends]=$data
    if [[ -z $trans_data_str ]]; then
        trans_data_str=$data
    else
        trans_data_str=$trans_data_str$'\n'$data
    fi
done

get_plot_str() {
    (( $# == 5 )) || return 1
    local col1=$1 col2=$2 title=$3 xaxis=$4 yaxis=$5
    echo "'-' u $1:$2 w lp t '$title, \\1 Transcensions' ax x${xaxis}y${yaxis}"
}

plot_x=$COL_A
#plot_x=$COL_LAST_T
#plot_x=$COL_TIME
plot_y=$COL_HS_PER_MIN_T
#plot_y=$COL_HS_PER_MIN_A
#plot_y=$COL_HS_T
plot_title=${TITLES[$plot_y-1]}
plot_x_label=${LABELS[$plot_x-1]}
plot_y_label=${LABELS[$plot_y-1]}
plot=$(get_plot_str $plot_x $plot_y "$plot_title" 1 1)

plot_str="plot $(echo ${transcensions[@]} | \
                 sed -e "s|\([0-9]\+\)|$plot,|g" -e "s/,$//")"
data_str=$trans_data_str$'\n'$trans_data_str

plot2_1_x=$plot_x
plot2_1_y=$COL_HZE
plot2_1_title=${TITLES[$plot2_1_y-1]}
plot2_1_y_label=${LABELS[$plot2_1_y-1]}
plot2_1=$(get_plot_str $plot2_1_x $plot2_1_y $plot2_1_title 1 2)

plot2_2_x=$plot_x
plot2_2_y=$COL_CURRENT_AS
plot2_2_title=${TITLES[$plot2_2_y-1]}
plot2_2_y_label=${LABELS[$plot2_2_y-1]}
plot2_2=$(get_plot_str $plot2_2_x $plot2_2_y $plot2_2_title 1 2)

x_values=$(echo "$plot_data" | cut -d' ' -f $plot_x | sort -n)
xmin=$(echo "$x_values" | head -n 1)
xmax=$(echo "$x_values" | tail -n 1)

if [[ -z $xrange_beg ]]; then
    xrange_beg=$(perl <<EOF
\$offset = ($xmax - $xmin) * 0.01;
if ($xmin < \$offset) {
    printf 0;
} else {
    printf $xmin - \$offset;
}
EOF
)
fi
if [[ -z $xrange_end ]]; then
    xrange_end=$(perl <<EOF
\$offset = ($xmax - $xmin) * 0.01;
printf $xmax + \$offset;
EOF
)
fi

sorted_data=$(echo "$plot_data" | \
              sort -k ${COL_T},${COL_T}n \
                   -k ${COL_CURRENT_AS},${COL_CURRENT_AS}n)

trans_line=()
for transcends in ${transcensions[@]}; do
    line=$(echo "$sorted_data" | \
           sed -n "/^$transcends \([^ ]\+ \+\)\{$((COL_ADD_AS-2))\}[^0]/p" | \
           head -n 1)
    [[ -n $line ]] || continue
    trans_line[transcends]=$line
done

more_plots=("$plot2_1" "$plot2_2")
more_plots_y=($plot2_1_y $plot2_2_y)
more_plots_y_label=("$plot2_1_y_label" "$plot2_2_y_label")
all_plot_str=
more_plots_i=0
max_plot=1
while (( $more_plots_i < ${#more_plots[@]} && $max_plot > 0 )); do
    max_plot=$((max_plot-1))
    p=${more_plots[more_plots_i]}
    addOneAS_x=()
    addOneAS_y=()
    for transcends in ${transcensions[@]}; do
        line=${trans_line[transcends]}
        [[ -n $line ]] || continue
        addOneAS_x+=($(echo "$line" | cut -d' ' -f $plot_x))
        addOneAS_y+=($(echo "$line" | cut -d' ' -f ${more_plots_y[more_plots_i]}))
    done
    
    lines=
    i=0
    while (( $i < ${#addOneAS_x[@]} )); do
        x_coord=${addOneAS_x[$i]}
        y_coord=${addOneAS_y[$i]}
        lines="set arrow from $x_coord,0 to $x_coord, second $y_coord nohead"$'\n'$lines
        lines="set arrow from $x_coord, second $y_coord to $xrange_end, second $y_coord nohead"$'\n'$lines
        i=$((i+1))
    done

    str=$(echo ${transcensions[@]} | sed -e "s|\([0-9]\+\)|$p,|g" -e "s/,$//")
    str=$(cat <<EOF
set y2label "${more_plots_y_label[more_plots_i]}"
$lines
$plot_str, $str
$data_str
unset arrow
EOF
)
    if [[ -z $all_plot_str ]]; then
        all_plot_str=$str
    else
        all_plot_str=$all_plot_str$'\n'$str
    fi

    more_plots_i=$((more_plots_i+1))
done

title="${#transcensions[@]} Transcensions"
if [[ -n $transcension ]]; then
    title="Transcension $transcension"
fi

commands=$(cat <<EOF
set title "$title"
set terminal x11 size 800,600
set grid
set xtics nomirror
set xlabel "$plot_x_label"
set ytics nomirror
set y2tics
set ylabel "$plot_y_label"
set autoscale
set xrange [$xrange_beg:$xrange_end]
set yrange [0:*]
set y2range [0:*]
#set nokey
set key left top
set multiplot layout $(echo "$all_plot_str" | grep "^plot" | wc -l),1
$all_plot_str
unset multiplot
EOF
)

echo "$commands"
