#!/usr/bin/env bash
set -e

show_help() {
    echo "Usage: $0 <path/to/src_dir_of_csv_files>"
    echo "Plots and saves iperf csv files to \"figures\""
}

udp=false
SUFFIX_DOWN=down
SUFFIX_UP=up
NAME_DOWN="Starlink\ Download"
NAME_UP="Starlink\ Upload"

OPTIND=1 # Reset in case getopts has been used previously in the shell.
while getopts "h?u" opt; do
   case "$opt" in
      h|\?) # display Help
         show_help
         exit 0
         ;;
     u) # UDP is true
         udp=true
         ;;
   esac
done

shift $((OPTIND-1))


# Must be in same folder as plot_iperfcsv.py

src_dir="$1"

if [ $# -ne 1 ]; then
    show_help
    exit 0
fi

plot_region()
{
    set -e

    dir="$1"
    basedir="$2"
    region_name="$3"
    dest="$4"
    pattern="$5"
    ignore_pattern="$6"
    suffix="$7"
    name="$8"
    python3 plot_iperfcsv.py $(find "${dir}" -type f \( -name "$pattern" ! -name "$ignore_pattern" \)) -n "$name (${region_name})" -f ${dest}/${basedir}_${suffix}
}

export -f plot_region

dest='figures'
mkdir -p "$dest"
for dir in "$src_dir"/*/; do
    basedir=$(basename "$dir")
    region_name=${basedir##*_}

    if [ "$udp" == "true" ]; then
        down_pattern="*down*udp.*" # From the client logs
        up_pattern="*receive*udp.*" # From the server logs
        ignore_pattern="-"
    else
        down_pattern="*down*" # From the client logs
        up_pattern="*receive*" # From the server logs
        ignore_pattern="*udp*"
    fi

    # Plot downloads
    sem -j+0 plot_region "$dir" "$basedir" "$region_name" "$dest" "$down_pattern" "$ignore_pattern" "$SUFFIX_DOWN" "$NAME_DOWN"

    # Plot uploads
    sem -j+0 plot_region "$dir" "$basedir" "$region_name" "$dest" "$up_pattern" "$ignore_pattern" "$SUFFIX_UP" "$NAME_UP"
done
sem --wait
