#!/bin/bash -exv

# This script simulates a ceremony where we generate new intermediate 
# certificates.

# see init-softhsm.sh for slot initialization
export SOFTHSM2_CONF=$PWD/softhsm2.conf
echo "directories.tokendir = $PWD/softhsm/" > $SOFTHSM2_CONF

# Simulate previously-performed ceremonies so we have the keys and certificates
# available to reference.
ceremony --config root-x1.yaml
ceremony --config root-x2.yaml

# Simulating intermediate HSM
ceremony --config e5-key.yaml
ceremony --config e6-key.yaml
ceremony --config r7-key.yaml
ceremony --config r8-key.yaml

# Simulating root HSM
ceremony --config e5-cert.yaml
ceremony --config e6-cert.yaml
ceremony --config r7-cert.yaml
ceremony --config r8-cert.yaml

# Verify the root -> intermediate signatures, plus the TLS Server Auth EKU.
# -check_ss_sig means to verify the root certificate's self-signature.
# 1672531201 is January 1 2023; this is necessary because we're testing with NotBefore in the future.
openssl verify -check_ss_sig -attime 1672531201 -CAfile root-x2.cert.pem -purpose sslserver int-e5.cert.pem int-e6.cert.pem
openssl verify -check_ss_sig -attime 1672531201 -CAfile root-x1.cert.pem -purpose sslserver int-r7.cert.pem int-r8.cert.pem

# Cleanup artifacts from re-simulated previous ceremonies.
rm root-x1.key.pem root-x1.cert.pem
rm root-x2.key.pem root-x2.cert.pem

# Generate human-readable text files from all of the PEM certificates.
for c in *.cert.pem ; do
  openssl x509 -text -noout -out ${c%.*}.txt -in $c
done
