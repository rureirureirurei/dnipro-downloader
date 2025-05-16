#!/bin/bash

set -e

URL="$1"
[ -z "$URL" ] && echo "Usage: $0 <URL>" && exit 1

if [ -d "./data" ]; then
    echo "./data directory already exists, please remove it"
    exit 1
fi

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

touch "data/merged.csv"

echo "[INFO] Removing first 7 lines, normalizing dates, and adding ID column..."
for file in $(ls data/csv | sort --reverse); do
    prefix=$(echo "$file" | cut -d'-' -f1)

    # Extract DD.MM.YYYY from filename and rearrange manually
    raw_date=$(echo "$file" | grep -oE '[0-9]{2}\.[0-9]{2}\.[0-9]{4}' | head -n1)
    day=$(echo "$raw_date" | cut -d. -f1)
    month=$(echo "$raw_date" | cut -d. -f2)
    year=$(echo "$raw_date" | cut -d. -f3)
    base_iso="$year-$month-$day"

    awk -F',' -v id="$prefix" -v fname="$file" -v base="$base_iso" '
        function to_epoch(iso) {
            split(iso, d, "-")
            return mktime(d[1] " " d[2] " " d[3] " 00 00 00")
        }
        BEGIN {
            base_epoch = to_epoch(base)
        }
        NR > 7 {
            raw = $1
            gsub(/"/, "", raw)

            if (raw ~ /^[0-9]+$/) {
                new_epoch = base_epoch + (raw - 1) * 86400
                new_date = strftime("%Y-%m-%d", new_epoch)
            } else if (raw ~ /^[0-9]{1,2}\/[0-9]{1,2}\/[0-9]{4}$/) {
                split(raw, p, "/")
                new_date = sprintf("%04d-%02d-%02d", p[3], p[2], p[1])
            } else {
                new_date = raw
            }

            $1 = new_date
            OFS = FS
            print $0, id, fname
        }
    ' "data/csv/$file" > "data/parsed/$file"
    cat "data/parsed/$file" >> "data/merged.csv"

    echo "[PARSED] $file -> data/parsed/$file"
done


echo "[DONE] All files saved under ./data"
echo "[DONE] Saved result in the ./data/merged.csv"
