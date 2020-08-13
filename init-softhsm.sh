#!/bin/bash -exv
#
# This doesn't really need to be run again. I ran it once to set up a SoftHSM
# directory, but then checked in the SoftHSM files so run.sh can be run
# repeatedly with the same slot ids.

export SOFTHSM2_CONF=$PWD/softhsm2.conf
echo "directories.tokendir = $PWD/softhsm/" > $SOFTHSM2_CONF

softhsm2-util --init-token --free --label "root HSM" --so-pin 1234 --pin 1234
softhsm2-util --init-token --free --label "intermediate HSM" --so-pin 1234 --pin 1234
