#!/bin/bash

set -e

URL="$1"
[ -z "$URL" ] && echo "Usage: $0 <URL>" && exit 1

# Create data directories
mkdir -p data/raw data/csv data/parsed

echo "[INFO] Downloading HTML page from $URL..."
wget -q -O data/page.html "$URL"

echo "[INFO] Extracting .xls links..."
awk '
    BEGIN { IGNORECASE = 1 }
    /<a [^>]*href *= *"[^\"]*\.xls"/ {
        match($0, /href *= *"([^"]*\.xls)"/, m)
        if (m[1] != "") print m[1]
    }
' data/page.html > data/links.txt

link_count=$(wc -l < data/links.txt)
echo "[INFO] Extracted $link_count links"
echo "[INFO] First 5 links:"
head -n 5 data/links.txt

echo "[INFO] Downloading .xls files..."
count=0
while read -r link; do
    prefix=$(printf "%04d" $count)
    fname="${prefix}-$(basename "$link")"
    wget -q "$link" -O "data/raw/$fname"
    echo "[DOWNLOADED] $link -> data/raw/$fname"
    count=$((count + 1))
done < data/links.txt

echo "[INFO] Converting .xls files to .csv..."
for file in $(ls data/raw | sort); do
    out="data/csv/${file%.xls}.csv"
    ssconvert "data/raw/$file" "$out" >/dev/null 2>&1
    echo "[CONVERTED] $file -> ${file%.xls}.csv"
done

echo "[INFO] Removing first 7 lines and adding ID column..."
for file in $(ls data/csv | sort); do
    prefix=$(echo "$file" | cut -d'-' -f1)
    awk -v id="$prefix" -v fname="$file" 'NR > 7 { print $0 "," id "," fname }' "data/csv/$file" > "data/parsed/$file"
    echo "[PARSED] $file -> data/parsed/$file"
done

cat ./data/parsed/* > ./data/merged.csv

echo "[DONE] All files saved under ./data"
echo "[DONE] Saved result in the ./data/merged.csv"
