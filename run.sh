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

# Verify the self-signature on these CSRs.
openssl req -verify -in int-r3.cross-csr.pem -noout
openssl req -verify -in int-r4.cross-csr.pem -noout

# Simulating root HSM
ceremony --config root-x1.yaml
ceremony --config root-x2.yaml
ceremony --config e1-cert.yaml
ceremony --config e2-cert.yaml
ceremony --config r3-cert.yaml
ceremony --config r4-cert.yaml
ceremony --config root-x1.crl.yaml
ceremony --config root-x2.crl.yaml
ceremony --config x2-signed-by-x1.yaml

# Verify the root -> intermediate signatures, plus the TLS Server Auth EKU.
# -check_ss_sig means to verify the root certificate's self-signature.
# 1609459200 is January 1 2021; this is necessary because we're testing with NotBefore in the future.
openssl verify -check_ss_sig -attime 1609459200 -CAfile root-x2.cert.pem -purpose sslserver int-e1.cert.pem int-e2.cert.pem
openssl verify -check_ss_sig -attime 1609459200 -CAfile root-x1.cert.pem -purpose sslserver int-r3.cert.pem int-r3.cert.pem

# Verify the X1 -> X2 cross-signature.
# Don't verify `-purpose sslserver` here because x2-signed-by-x1 intentionally
# doesn't have the "TLS Server Auth" EKU (and doesn't need it).
openssl verify -check_ss_sig -attime 1609459200 -CAfile root-x1.cert.pem x2-signed-by-x1.cert.pem

# Verify the path from X1 -> X2 -> E1 and X1 -> X2 -> E2, plus the TLS Server Auth EKU.
openssl verify -check_ss_sig -attime 1609459200 -CAfile root-x1.cert.pem -purpose sslserver -untrusted x2-signed-by-x1.cert.pem int-e1.cert.pem
openssl verify -check_ss_sig -attime 1609459200 -CAfile root-x1.cert.pem -purpose sslserver -untrusted x2-signed-by-x1.cert.pem int-e2.cert.pem

# Verify the CRLs.
openssl crl -verify -CAfile root-x1.cert.pem -in root-x1.crl.pem -noout
openssl crl -verify -CAfile root-x2.cert.pem -in root-x2.crl.pem -noout

# Simulate cross-signing from a third-party CA based on our cross-csr output.
openssl ca -batch -extensions x509_extensions -out int-r3.cross-cert.pem -config openssl.conf -infiles int-r3.cross-csr.pem
openssl ca -batch -extensions x509_extensions -out int-r4.cross-cert.pem -config openssl.conf -infiles int-r4.cross-csr.pem

openssl verify -check_ss_sig -CAfile third-party-ca/ca.crt -purpose sslserver int-r3.cross-cert.pem int-r4.cross-cert.pem

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
