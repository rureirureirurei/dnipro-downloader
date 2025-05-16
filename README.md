# Dnipro Biological Data Scraper

This script automates the downloading and processing of `.xls` files from a webpage containing multiple links.

## Features

- Downloads a webpage and extracts all `.xls` links
- Saves all files in a structured `./data` directory:
  - `raw/`: downloaded `.xls` files
  - `csv/`: converted `.csv` files
  - `parsed/`: cleaned and annotated CSV files
- Converts `.xls` to `.csv` using `ssconvert`
- Removes the first 7 lines from each CSV file
- Adds two columns:
  - Numeric ID based on download order
  - Original filename for traceability
- Outputs basic progress logs to stdout

## Prerequisites

Install required tools (replace apt with your package manager)

```bash
sudo apt update
sudo apt install wget gnumeric
```

Clone a repository
```
git clone https://github.com/rureirureirurei/dnipro-downloader
cd dnipro-downloader
chmod +x script.sh
```

## Usage

```bash
chmod +x script.sh
./script.sh "http://example.com/your_page.html"
````

After processing, all data will be saved under the `./data` directory.

## To clean up

```bash
rm -rf data
```

