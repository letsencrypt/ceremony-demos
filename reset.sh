#!/bin/bash -exv

rm -f *.pem *.pem.txt
rm -rf softhsm/*
git reset -- softhsm
git checkout -- softhsm
