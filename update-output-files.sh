#!/bin/bash

for i in $(find ./ceremonies/ -type f -name '*.cert.pem' -o -name '*.cert.txt' -o -name '*.key.pem'); do
    stripPrefix="${i#*./ceremonies/}"
    YEAR="${stripPrefix%/*}"
    cp "${i}" "./outputs/${YEAR}/"
done

git status
