#!/bin/bash -exv
# This script simulates a ceremony where we generate the certificates from
# https://community.letsencrypt.org/t/lets-encrypt-new-hierarchy-plans/125517
export SOFTHSM2_CONF=$PWD/softhsm2.conf
echo "directories.tokendir = $PWD/softhsm/" > $SOFTHSM2_CONF

# see init-softhsm.sh for slot initialization

# Simulating intermediate HSM
ceremony --config e1-key.yaml
ceremony --config e2-key.yaml
ceremony --config r3-key.yaml
ceremony --config r4-key.yaml
ceremony --config r3-cross-csr.yaml
ceremony --config r4-cross-csr.yaml

# Simulating root HSM
ceremony --config root-x1.yaml
ceremony --config root-x2.yaml
ceremony --config x2-signed-by-x1.yaml
ceremony --config e1-cert.yaml
ceremony --config e2-cert.yaml
ceremony --config r3-cert.yaml
ceremony --config r4-cert.yaml
ceremony --config root-x1.crl.yaml
ceremony --config root-x2.crl.yaml

rm root-x1.key.pem
rm root-x1.cert.pem

for c in *.cert.pem ; do
  openssl x509 -text -noout -out $c.txt -in $c
done
for c in *.crl.pem ; do
  openssl crl -inform pem -in $c  -text -noout > $c.txt
done

for f in root-x2.cert.pem.txt x2-signed-by-x1.cert.pem.txt root-x2.crl.pem.txt int-e1.cert.pem.txt int-e2.cert.pem.txt int-r3.cert.pem.txt int-r4.cert.pem.txt; do
  echo $f
  echo '```text'
  cat $f
  echo '```'
  echo
done > output-for-forum.txt
