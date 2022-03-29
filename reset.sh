#!/bin/bash -exv

rm -f *.pem *.txt
rm -rf softhsm/*
git reset -- softhsm
git checkout -- softhsm
