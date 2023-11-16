#!/bin/bash -exv

find -L -type f \( -name '*.pem' -o -name '*.txt' \) -not -path './outputs/*' -delete
rm -rf softhsm/*
git reset -- softhsm
git checkout -- softhsm
