#!/bin/bash -exv

rm -f *.pem *.pem.txt
rm -rf softhsm/*
git reset -- softhsm third-party-ca
git checkout -- softhsm third-party-ca
