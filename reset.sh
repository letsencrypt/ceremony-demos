#!/bin/bash -exv

find -L -type f \( -name '*.pem' -o -name '*.txt' \) -delete
rm -rf softhsm/*
git reset -- softhsm
git checkout -- softhsm
