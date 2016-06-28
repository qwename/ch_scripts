#!/bin/bash

COL_ASCENDS=2
COL_HZE=3
COL_LAST_TRANS=4
COL_HS_PER_MIN=6

dir=./live_plots
[[ -d $dir ]] || exit 1

all_data=$(find "$dir" -type f -print0 | xargs -0 cat)
plot_data=$(echo "$all_data" | sed -n '/^[0-9]/p')
ascensions=($(echo "$plot_data" | cut -d' ' -f 2 | sort -n | uniq))

if (( ${#ascensions[@]} == 0 )); then
    echo >&2 "No ascensions found"
    exit 1
fi

plot_str="plot $(echo ${ascensions[@]} | sed -e "s/\([0-9]\{2\}\)/'-' u $COL_LAST_TRANS:$COL_HS_PER_MIN w lp title 'HS\/min, \1 Ascensions' axes x1y1, '-' u $COL_LAST_TRANS:$COL_HZE w l title 'HZE, \1 Ascensions' axes x1y2, /g" -e "s/, $//")"

xranges=$(echo "$all_data" | sed -n -e '/^set xrange/p' | sed 's/[^[]\+\[\([0-9]\+\):\([0-9]\+\).*/\1 \2/')
xrange_beg=$(echo "$xranges" | sort -k 1,1n | head -n 1 | cut -d' ' -f 1)
xrange_end=$(echo "$xranges" | sort -k 2,2n | tail -n 1 | cut -d' ' -f 2)

plot=$(cat <<EOF
set grid
set xlabel "Time Since Last Transcension (min)"
set ylabel "HS/min (Transcension)"
set y2label "HZE"
set y2tics
set autoscale
set xrange [$xrange_beg:$xrange_end]
set nokey
$plot_str
EOF
)

for ascends in ${ascensions[@]}; do
    cols=$((COL_ASCENDS-1))
    ascends_data=$(echo "$plot_data" | \
                         sed -n "/^\([^ ]\+ \+\)\{$cols\}$ascends/p")
    plot=$plot$'\n'$ascends_data$'\n'e
    plot=$plot$'\n'$ascends_data$'\n'e
done

echo "$plot"
