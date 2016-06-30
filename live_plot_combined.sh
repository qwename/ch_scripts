#!/bin/bash

COL_ASCENDS=2
COL_HZE=3
COL_LAST_TRANS=4
COL_HS_PER_MIN=6

usage() {
    cat <<EOF
Usage: $0 <TRANSCENSION> [ASCENSION=*] [XRANGE-BEG] [XRANGE-END]
EOF
}

if (( $# < 1 )); then
    usage >&2
    exit 1
fi
transcension=$1
ascension=$2
xrange_beg=$3
xrange_end=$4

if [[ ! $transcension =~ ^[0-9]+$ ]]; then
    echo >&2 "Not a valid transcension number: '$transcension'"
    exit 1
fi

if [[ $ascension =~ ^\*$ ]]; then
    ascension=
fi
if [[ -n $ascension && ! $ascension =~ ^[0-9]+$ ]]; then
    echo >&2 "Not a valid ascension number: '$ascension'"
    exit 1
fi

dir=./live_plots
[[ -d $dir ]] || exit 1

regex="^$transcension "
if [[ -n $ascension ]]; then
    regex="$regex$ascension "
fi

all_data=$(find "$dir" -type f -exec \
           grep -Z -l -m 1 "$regex" {} \+ | xargs -0 cat)
plot_data=$(echo "$all_data" | sed -n "/$regex/p" | sort -k1n -k2n -k3n | uniq)
ascensions=($(echo "$plot_data" | cut -d' ' -f 2 | sort -n | uniq))

if (( ${#ascensions[@]} == 0 )); then
    echo >&2 "No ascensions found"
    exit 1
fi

plot1="'-' u $COL_LAST_TRANS:$COL_HS_PER_MIN w lp title 'HS/min, \1 Ascensions' axes x1y1"
plots="$plot1, "

plot2="'-' u $COL_LAST_TRANS:$COL_HZE w lp title 'HZE, \1 Ascensions' axes x1y2"
more_plots=() #("$plot2")
for p in "${more_plots[@]}"; do
    plots="$plots$p, "
done

plot_str="plot $(echo ${ascensions[@]} | \
                 sed -e "s|\([0-9]\+\)|$plots|g" -e "s/, $//")"

xranges=$(echo "$all_data" | sed -n -e '/^set xrange/p' | sed 's/[^[]\+\[\([^:]\+\):\([^]]\+\).*/\1 \2/')
if [[ -z $xrange_beg ]]; then
    xrange_beg=$(echo "$xranges" | sort -k 1,1n | head -n 1 | cut -d' ' -f 1)
fi
if [[ -z $xrange_end ]]; then
    xrange_end=$(echo "$xranges" | sort -k 2,2n | tail -n 1 | cut -d' ' -f 2)
fi

title="Transcension $transcension"
if [[ -n $ascension ]]; then
    title="$title, Ascension $ascension"
fi

plot=$(cat <<EOF
set title "$title"
set grid
set xlabel "Time Since Last Transcension (min)"
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

for ascends in ${ascensions[@]}; do
    cols=$((COL_ASCENDS-1))
    re_ascends="^\([^ ]\+ \+\)\{$cols\}$ascends "
    ascends_data=$(echo "$plot_data" | sed -n "/$re_ascends/p")
    plot=$plot$'\n'$ascends_data$'\n'e
    for p in "${more_plots[@]}"; do
        plot=$plot$'\n'$ascends_data$'\n'e
    done
done

echo "$plot"
