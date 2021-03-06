#!/bin/bash
# This script may stop randomly (after a long time?), put it in the following
# loop so that it doesn't break:
# while true; do
#     ./this_script [ARG] ..
# done

stats_script=./get_stats.pl
lso_script=./parse_accountSO.pl
plot_file=./live_plots/live_plot
search_dir="/home/$USER/.macromedia/Flash_Player/#SharedObjects/"
site=kongregate
lso_name=accountSO.sol

read_file=$1
if (( $# > 0 )) && [[ -f $read_file ]]; then
    echo >&2 "Loading plot data from '$read_file'"
    plot_data=$(sed -e '1,/^plot/d' -e '$ d' "$read_file")
elif (( $# == 0 )); then
    echo >&2 "Usage: $0 <FILE>"
    exit 1
else
    echo >&2 "Not a file: '$read_file'"
    plot_data=
fi

lso_file=$(find "$search_dir" -type f -name "$lso_name" | grep "$site" |
           head -n 1)
if [[ -z $lso_file ]]; then
    echo >&2 "Failed to find Flash cookie '$lso_name' in '$search_dir'"
    exit 1
fi
lso_dir=$(dirname "$lso_file")

backup_file() {
    (( $# == 1 )) || return
    local file=$1
    if [[ -f $file ]]; then
        backup=${file}.$(date +%s)
        echo >&2 "Copying '$file' to '$backup'"
        cp "$file" "$backup"
    fi
}

backup_file "$plot_file"

echo >&2 "Monitoring directory '$lso_dir' for changes to file '$lso_name'"
ascensions=
while [[ $(inotifywait -q -e moved_to "$lso_dir" --format "%f") =~ $lso_name ]]; do
    retries=0
    temp_data=
    while (( $retries < 3)); do
        output=$("$stats_script"  <("$lso_script" "$lso_file") 2>&1)
        echo "$output" | sed -n "2,\$p"

        current_data=$(echo "$output" | sed -n "1p")
        if [[ -z $plot_data ]]; then
            temp_data=$current_data
        else
            temp_data=$plot_data$'\n'$current_data
        fi

        first_line=$(echo "$temp_data" | sed -n "1p")
        last_line=$(echo "$temp_data" | sed -n "$ p")

        if [[ $last_line =~ ^Failed ]]; then
            echo >&2 "$last_line"
            echo >&2 "Retrying $retries more times"
            retries=$(($retries + 1))
            sleep 1
            continue
        fi

        current_ascensions=$(echo "$last_line" | cut -d' ' -f 2)
        # Might have to fix script
        if [[ ! $current_ascensions =~ ^[0-9]+$ ]]; then
            echo >&2 "Invalid ascension value: '$current_ascensions'"
            echo >&2 "Retrying $retries more times"
            retries=$(($retries + 1))
            sleep 1
            continue
        fi
        if [[ -n $ascensions ]] && [[ $ascensions != $current_ascensions ]]; then
            echo "Ascension counts differ: $ascensions != $current_ascensions"
            backup_file "$plot_file"
            temp_data=$current_data
            first_line=$(echo "$current_data" | sed -n "1p")
            last_line=$(echo "$current_data" | sed -n "$ p")
        fi
        ascensions=$current_ascensions

        retries=0
        break
    done
    if (( $retries == 3 )); then
        continue
    fi

    plot_data=$temp_data

    x_beg=$(echo "$first_line" | cut -d' ' -f 4)
    x_end=$(echo "$last_line" | cut -d' ' -f 4)
    diff=$(perl -e "print ($x_end-$x_beg)")

    xrange_beg=$(echo "$x_beg" | sed "s/\..*//")
    if (( $xrange_beg > 0 )); then
        xrange_beg=$((xrange_beg - 1))
    fi
    xrange_end=$(($(echo "$x_end" | sed "s/\..*//") + 5))
    if (( $xrange_end - $xrange_beg < 30 )); then
        xrange_end=$(($xrange_beg + 30));
    fi

    yrange_beg=$(echo "$first_line" | cut -d' ' -f 6 | sed "s/.\..*//")
    yrange_end=$(echo "$last_line" | cut -d' ' -f 6 | sed "s/\..*//")0

    title="$ascensions Ascensions, $diff minutes"

    swap="${plot_file}.swp"
    cat <<EOF >"$swap"
set title "$title"
set grid
set xlabel "Time Since Last Transcension (min)"
set ytics nomirror
set ylabel "HS/min (Transcension)"
set autoscale
set xrange [$xrange_beg:$xrange_end]
#set yrange [$yrange_beg:$yrange_end]
plot "-" u 4:6 w lp title "Live Stats"
$plot_data
e
EOF
    cp "$swap" "$plot_file"
done
