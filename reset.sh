#!/bin/bash -exv

rm -f *.pem
rm -rf softhsm/*
git reset -- softhsm
git checkout -- softhsm
