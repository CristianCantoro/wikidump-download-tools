# wikidump-download

Some scripts to download the Wikipedia dumps (available at
[dumps][dumps]).

## Overview

### 1. download size files for a given dump

For example, the `pages-meta-history` dump for Spanish wikipedia (`eswiki`)
made on `2021-02-01` is available at
[https://dumps.wikimedia.org/eswiki/20210201/](https://dumps.wikimedia.org/eswiki/20210201/).

Thus, to download sizes we execute the following command:

```bash
./sizes/download_sizes.sh https://dumps.wikimedia.org/eswiki/20210201/
```

Results are contained in `./sizes/2021-02-01.eswiki.pages-meta-history.txt`:

```bash
$ head -n5 ./sizes/2021-02-01.eswiki.pages-meta-history.txt
eswiki-20210201-pages-meta-history1.xml-p1p1094.7z 163.8 MB
eswiki-20210201-pages-meta-history1.xml-p1095p2904.7z 174.6 MB
eswiki-20210201-pages-meta-history1.xml-p2905p4657.7z 170.4 MB
eswiki-20210201-pages-meta-history1.xml-p4658p6270.7z 159.9 MB
eswiki-20210201-pages-meta-history1.xml-p6271p8248.7z 181.0 MB
```

### 2. make lists of files to download

```bash
./downloadlists/make_lists.sh sizes/2021-02-01.eswiki.pages-meta-history.txt
```

Results are contained in `./downloadlists/2021-02-01.eswiki.pages-meta-history.txt`:

```bash
$ head -n5 ./downloadlists/2021-02-01.eswiki.pages-meta-history.txt
https://dumps.wikimedia.org/eswiki/20210201/eswiki-20210201-pages-meta-history1.xml-p1p1094.7z  http://dumps.wikimedia.your.org/eswiki/20210201/eswiki-20210201-pages-meta-history1.xml-p1p1094.7z
https://dumps.wikimedia.org/eswiki/20210201/eswiki-20210201-pages-meta-history1.xml-p1095p2904.7z http://dumps.wikimedia.your.org/eswiki/20210201/eswiki-20210201-pages-meta-history1.xml-p1095p2904.7z
https://dumps.wikimedia.org/eswiki/20210201/eswiki-20210201-pages-meta-history1.xml-p2905p4657.7z http://dumps.wikimedia.your.org/eswiki/20210201/eswiki-20210201-pages-meta-history1.xml-p2905p4657.7z
https://dumps.wikimedia.org/eswiki/20210201/eswiki-20210201-pages-meta-history1.xml-p4658p6270.7z http://dumps.wikimedia.your.org/eswiki/20210201/eswiki-20210201-pages-meta-history1.xml-p4658p6270.7z
https://dumps.wikimedia.org/eswiki/20210201/eswiki-20210201-pages-meta-history1.xml-p6271p8248.7z http://dumps.wikimedia.your.org/eswiki/20210201/eswiki-20210201-pages-meta-history1.xml-p6271p8248.7z
```

### 3. download the actual dump files

```bash
./scripts/download.sh -d ./downloadlists/2021-02-01.eswiki.pages-meta-history.txt
```

The file will be saved in the directory `./data/eswiki/20210201`:

```bash
$ find data/eswiki/20210201 -type f | sort -V | head -n5
data/eswiki/20210201/eswiki-20210201-pages-meta-history1.xml-p1p1094.7z
data/eswiki/20210201/eswiki-20210201-pages-meta-history1.xml-p1095p2904.7z
data/eswiki/20210201/eswiki-20210201-pages-meta-history1.xml-p2905p4657.7z
data/eswiki/20210201/eswiki-20210201-pages-meta-history1.xml-p4658p6270.7z
data/eswiki/20210201/eswiki-20210201-pages-meta-history1.xml-p6271p8248.7z
```

## Usage

### sizes/download_sizes.sh

```text
Usage: download_sizes.sh [options] <dump_url>
       download_sizes.sh ( -h | --help )
       download_sizes.sh --version

Arguments:
    <dump_url>                The wikidump base url
                              e.g. https://dumps.wikimedia.org/enwiki/20180301/
Options:
    -d, --debug               Enable debug mode.
    -f, --ext <ext>           Extension of the files to filter [default: .7z].
    -t, --filetype <filetype> Type of files to filter
                              [default: pages-meta-history].
    -h, --help                Show this help message and exits.
    --version                 Print version and copyright information.
```

### downloadlists/make_lists.sh

```text
Usage: make_lists.sh [options] <sizefile>

Options:
  -d, --debug                 Enable debug mode.
  -h, --help                  Show this help message and exits.
  --version                   Print version and copyright information.
```

### scripts/download.sh

```text
Usage: download.sh [options] <downloadlist>
       download.sh --kill
       download.sh ( -h | --help )
       download.sh --version

Arguments:
  <dowloadlist>               Date to download (e.g. 2018-03-01)

Options:
  -c, --continue              Continue the previous download.
  -d, --debug                 Enable debug mode (incompatible with --quiet).
  -k, --kill                  Kill connection.
  -q, --quiet                 Suppress output (incompatible with --debug).
  -h, --help                  Show this help message and exits.
  --version                   Print version and copyright information.
```

## Dependencies

The following software are needed to run the wikidump-download scripts:

* realpath
* docopts
* parallel
* xidel

[dumps]: https://dumps.wikimedia.org/dumps/
