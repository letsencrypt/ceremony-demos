#!/bin/bash -e

function usage() {
    echo -e "USAGE:
      This script simulates a ceremony where we generate new intermediate
      certificates.

      ./$(basename ${0}) [-h]
          -h | Outputs this help text"
}

if [ "${1}" == "-h" ]; then
    usage
    exit 0
fi

if [ $# -ne 0 ]; then
    usage
    exit 1
fi

# see init-softhsm.sh for slot initialization
export SOFTHSM2_CONF="${PWD}/softhsm2.conf"
echo "directories.tokendir = ${PWD}/softhsm/" > $SOFTHSM2_CONF

# Simulate previously-performed ceremonies so we have the keys and certificates
# available to reference.
ceremony --config ./ceremonies/2015/root-x1.yaml
ceremony --config ./ceremonies/2020/root-x2.yaml

# Simulating intermediate HSM
ceremony --config ./ceremonies/2023/e5-key.yaml
ceremony --config ./ceremonies/2023/e6-key.yaml
ceremony --config ./ceremonies/2023/r7-key.yaml
ceremony --config ./ceremonies/2023/r8-key.yaml

# Simulating root HSM
ceremony --config ./ceremonies/2023/e5-cert.yaml
ceremony --config ./ceremonies/2023/e6-cert.yaml
ceremony --config ./ceremonies/2023/r7-cert.yaml
ceremony --config ./ceremonies/2023/r8-cert.yaml

# Verify the root -> intermediate signatures, plus the TLS Server Auth EKU.
# -check_ss_sig means to verify the root certificate's self-signature.
# 1704067201 is January 1 2024; this is necessary because we're testing with NotBefore in the future.
openssl verify -check_ss_sig -attime 1704067201 -CAfile ./ceremonies/2020/root-x2.cert.pem -purpose sslserver ./ceremonies/2023/int-e5.cert.pem ./ceremonies/2023/int-e6.cert.pem
openssl verify -check_ss_sig -attime 1704067201 -CAfile ./ceremonies/2015/root-x1.cert.pem -purpose sslserver ./ceremonies/2023/int-r7.cert.pem ./ceremonies/2023/int-r8.cert.pem

# Generate human-readable text files from all of the PEM certificates.
for c in $(find -type f -name '*.cert.pem'); do
  openssl x509 -text -noout -out "${c%.*}.txt" -in "${c}"
done

# Cleanup artifacts from re-simulated previous ceremonies.
rm ./ceremonies/2015/root-x1.key.pem ./ceremonies/2015/root-x1.cert.pem
rm ./ceremonies/2020/root-x2.key.pem ./ceremonies/2020/root-x2.cert.pem