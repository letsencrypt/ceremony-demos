#!/bin/bash -exv

# This doesn't really need to be run again. It was used to generate the
# //softhsm/ directory which is checked into this repository, but now that
# directory can be left untouched while the yaml config files statically
# reference its pin and slots.

export SOFTHSM2_CONF=$PWD/softhsm2.conf
echo "directories.tokendir = $PWD/softhsm/" > $SOFTHSM2_CONF

softhsm2-util --init-token --free --label "root HSM" --so-pin 1234 --pin 1234
softhsm2-util --init-token --free --label "intermediate HSM" --so-pin 1234 --pin 1234
