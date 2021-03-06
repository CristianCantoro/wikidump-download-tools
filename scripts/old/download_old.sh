#!/bin/sh

timeout  -s TERM 8h aria2c -j 12 --max-overall-download-limit=6M --max-overall-upload-limit=50k -d data --file-allocation=none torrentfiles/$1/*.torrent
timeout  -s TERM 10h aria2c -j 12 --max-overall-download-limit=50M --max-overall-upload-limit=50k -d data --file-allocation=none torrentfiles/$1/*.torrent

