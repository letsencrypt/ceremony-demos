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
    # Be nice to those asking for help :)
    exit 0
fi

if [ $# -ne 0 ]; then
    usage
    exit 1
fi

# see init-softhsm.sh for slot initialization
export SOFTHSM2_CONF="${PWD}/softhsm2.conf"
echo "directories.tokendir = ${PWD}/softhsm/" > $SOFTHSM2_CONF

# Store the output in a ramdisk so we don't chew up my disk endlessly running this tooling.
RAMDISK_DIR=/run/shm/ceremonies
mkdir -p "${RAMDISK_DIR}"
for ceremonyYear in $(find ./ceremonies/ -maxdepth 1 -type d -printf '%P '); do
    mkdir -p "${RAMDISK_DIR}/${ceremonyYear}"
done
if [ ! -L "ceremony-output" ]; then
    ln -s "${RAMDISK_DIR}/" ceremony-output
fi

# Simulate previously-performed ceremonies so we have the keys and certificates
# available to reference.
ceremony --config ./ceremonies/2000/root-dst.yaml
ceremony --config ./ceremonies/2015/root-x1.yaml
ceremony --config ./ceremonies/2020/root-x2.yaml
ceremony --config ./ceremonies/2020/root-x2-cross-cert.yaml
## The zombie cross-sign
ceremony --config ./ceremonies/2021/root-x1-cross-cert.yaml


# Simulating intermediate HSM
ceremony --config ./ceremonies/2020/r3-key.yaml
ceremony --config ./ceremonies/2020/r4-key.yaml
ceremony --config ./ceremonies/2023/r8-key.yaml
ceremony --config ./ceremonies/2023/r9-key.yaml
ceremony --config ./ceremonies/2023/r10-key.yaml
ceremony --config ./ceremonies/2020/e1-key.yaml
ceremony --config ./ceremonies/2020/e2-key.yaml
ceremony --config ./ceremonies/2023/e5-key.yaml
ceremony --config ./ceremonies/2023/e6-key.yaml
ceremony --config ./ceremonies/2023/e7-key.yaml

# Simulating root HSM
ceremony --config ./ceremonies/2020/root-x1.crl.yaml
ceremony --config ./ceremonies/2020/root-x2.crl.yaml
ceremony --config ./ceremonies/2020/r3-cert.yaml
ceremony --config ./ceremonies/2020/r3-cross-csr.yaml
ceremony --config ./ceremonies/2020/r4-cert.yaml
ceremony --config ./ceremonies/2020/r4-cross-csr.yaml
ceremony --config ./ceremonies/2023/r8-cert.yaml
ceremony --config ./ceremonies/2023/r9-cert.yaml
ceremony --config ./ceremonies/2023/r10-cert.yaml
ceremony --config ./ceremonies/2020/e1-cert.yaml
ceremony --config ./ceremonies/2020/e2-cert.yaml
ceremony --config ./ceremonies/2023/e5-cert.yaml
ceremony --config ./ceremonies/2023/e5-cross-cert.yaml
ceremony --config ./ceremonies/2023/e6-cert.yaml
ceremony --config ./ceremonies/2023/e6-cross-cert.yaml
ceremony --config ./ceremonies/2023/e7-cert.yaml
ceremony --config ./ceremonies/2023/e7-cross-cert.yaml

# Verify the root -> intermediate signatures, plus the TLS Server Auth EKU.
# -check_ss_sig means to verify the root certificate's self-signature.

## 1609459200 is Dec 31 2021; this is necessary because we're testing with NotBefore in the future.
openssl verify -check_ss_sig -attime 1609459200 -CAfile ${RAMDISK_DIR}/2015/root-x1.cert.pem -purpose sslserver \
    ${RAMDISK_DIR}/2020/int-r3.cert.pem \
    ${RAMDISK_DIR}/2020/int-r4.cert.pem

openssl verify -check_ss_sig -attime 1609459200 -CAfile ${RAMDISK_DIR}/2020/root-x2.cert.pem -purpose sslserver \
    ${RAMDISK_DIR}/2020/int-e1.cert.pem \
    ${RAMDISK_DIR}/2020/int-e2.cert.pem

## 1611300000 is Jan 22 2021; this is necessary because we're testing with NotBefore in the future.
openssl verify -check_ss_sig -attime 1611300000 -CAfile ${RAMDISK_DIR}/2000/root-dst.cert.pem \
    ${RAMDISK_DIR}/2021/root-x1-cross.cert.pem

## 1704067201 is Dec 31 2024; this is necessary because we're testing with NotBefore in the future.
openssl verify -check_ss_sig -attime 1704067201 -CAfile ${RAMDISK_DIR}/2015/root-x1.cert.pem -purpose sslserver \
    ${RAMDISK_DIR}/2023/int-r8.cert.pem \
    ${RAMDISK_DIR}/2023/int-r9.cert.pem \
    ${RAMDISK_DIR}/2023/int-r10.cert.pem \
    ${RAMDISK_DIR}/2023/int-e5-cross.cert.pem \
    ${RAMDISK_DIR}/2023/int-e6-cross.cert.pem \
    ${RAMDISK_DIR}/2023/int-e7-cross.cert.pem

openssl verify -check_ss_sig -attime 1704067201 -CAfile ${RAMDISK_DIR}/2020/root-x2.cert.pem -purpose sslserver \
    ${RAMDISK_DIR}/2023/int-e5.cert.pem \
    ${RAMDISK_DIR}/2023/int-e6.cert.pem \
    ${RAMDISK_DIR}/2023/int-e7.cert.pem

# Generate human-readable text files from all of ceremony output files.
for x in $(find -L ${RAMDISK_DIR} -type f -name '*.cert.pem'); do
    openssl x509 -text -noout -out "${x%.*}.txt" -in "${x}" &
done

for r in $(find -L ${RAMDISK_DIR} -type f -name '*.cross-csr.pem'); do
    openssl req -text -noout -verify -out "${r%.*}.txt" -in "${r}" &
done

for c in $(find -L ${RAMDISK_DIR} -type f -name '*.crl.pem'); do
    openssl crl -text -noout -out "${c%.*}.txt" -in "${c}" &
done

wait
