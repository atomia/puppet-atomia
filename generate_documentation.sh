#!/bin/sh

puppet doc manifests/* > "doc.txt"
rm doc/*
start=0
while read line
do
        if [ `echo $line | grep -o '\=\= Class:*' | wc -l` -eq 1 ]; then
                filename=`echo $line | sed  's/== Class: //' | tr -d '\r'`
                start=1
        fi

        if [ $start -eq 1 ]; then
                echo $line | sed 's/\=\=/\#\#/' | sed 's/\#\#\=/\#\#/' >> "doc/$filename.md"
        fi

        if [ `echo $line | grep -o '\=\=\= End*' | wc -l` -eq 1 ]; then
                start=0
        fi
done < "doc.txt"
rm doc.txt
