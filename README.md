## Required programs:
*program (version I use)*
- Perl 5 (5.16.3)
- Bash 4 (4.2.26)
- inotiywait (package inotify-tools 3.14)
- gnuplot (4.6)
- grep (GNU grep 2.20)
- sed (GNU sed 4.2.2)
- tr (8.22)

## Required Perl modules
- Math::BigFloat
- JSON
- MIME::Base64

## Sample Usage
##### Monitoring a single save file, and copying it to a new timestamped file if changed.

```
./watch_save.sh clickerHeroes.txt
# Optionally, specify a different directory as the second argument.
./watch_save.sh clickerHeroes.txt /your/dest/dir
```

##### Getting bulk stats from a directory of save files, and then plot them.
```
 >stats_file
for file in /your/dir/here; do
    ./get_stats "$file" 2>> stats_file
done
./saves_plot.sh stats_file | gnuplot -p
# Specify any transcension, set xrange from 0 to 1000
./saves_plot.sh stats_file \* 0 1000 | gnuplot -p
# Plot transcension 3 only, starting xrange from 100
./saves_plot.sh stats_file 3  100 | gnuplot -p
```

##### Watch live statistics by reading the Flash cookie which updates every 30 seconds or so.

Stats are written to the file "live_plot", and can be read again by the script by passing it as an argument.

The live_plot files are automatically copied to a timestamped file every ascension, or on script execution if an existing file is detected.

```
./watch_live.sh
./watch_live.sh live_plot
```

Plot the stats

``gnuplot -p live_plot``

Sample plots

``./watch_live_plot.sh``

Combine all live_plot files

```
# Plot all live stats for transcension 2
./live_plot_combined 2 | gnuplot -p
# Same as ./saves_plot.sh, 
# Plot all live stats for transcension 2, ascension 3, starting xrange from 100
./live_plot_combined 2 3 100 | gnuplot -p
```
