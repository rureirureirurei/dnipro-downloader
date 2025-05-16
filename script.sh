#!/bin/bash

set -e

URL="$1"
[ -z "$URL" ] && echo "Usage: $0 <URL>" && exit 1

mkdir -p data/raw data_csv data_parsed

# Step 1: Download the HTML page
wget -q -O page.html "$URL"

# Step 2: Extract all .xls links using awk
awk '
    BEGIN { IGNORECASE = 1 }
    /<a [^>]*href *= *"[^\"]*\.xls"/ {
        match($0, /href *= *"([^"]*\.xls)"/, m)
        if (m[1] != "") print m[1]
    }
' page.html > links.txt

# Step 3: Download .xls files with prefix numbering
count=0
while read -r link; do
    prefix=$(printf "%02d" $count)
    fname="${prefix}-$(basename "$link")"
    wget -q "$link" -O "data/raw/$fname"
    count=$((count + 1))
done < links.txt

# Step 4: Convert to CSV
mkdir -p data_csv
for file in $(ls data/raw | sort); do
    out="data_csv/${file%.xls}.csv"
    ssconvert "data/raw/$file" "$out"
done

# Step 5: Remove first 7 lines and add column with file number
mkdir -p data_parsed
for file in $(ls data_csv | sort); do
    prefix=$(echo "$file" | cut -d'-' -f1)
    awk -v id="$prefix" 'NR > 7 { print $0 "," id }' "data_csv/$file" > "data_parsed/$file"
done

