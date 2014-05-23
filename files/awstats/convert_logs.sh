#!/bin/sh

for f in /storage/content/logs/iis_logs/u_ex*.log; do
        if [ -f "$f" ]; then
                newfile=`basename "$f" | sed 's/^u_ex\([0-9]*\)\([0-9][0-9]\)\(\..*\)/access.20\1\2\3/'`
                logconvert --from w3c --to vhostcombined < "$f" > /storage/content/logs/to_be_merged/"$newfile"
                mv "$f" /storage/content/logs/iis_logs/archived
        fi
done

