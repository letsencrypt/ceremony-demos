#!/bin/bash

set -o pipefail

for i in $(find ./ceremonies/ -type f -name '*.pem' -o -name '*.txt'); do
    stripPrefix="${i#*./ceremonies/}"
    YEAR="${stripPrefix%/*}"
    cp "${i}" "./outputs/${YEAR}/"
done

git status
