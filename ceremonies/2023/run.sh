#!/bin/bash -e

function usage() {
    echo -e "Usage:

    ./$(basename "${0}") /path/to/ceremony-binary /path/to/key-material
    "
}

if [ "${1}" == "-h" ]; then
    usage
    exit 0
fi

if [ "$#" -ne 2 ]; then
    usage
    exit 1
fi

CEREMONY_BIN="${1}"
if [ ! -x "${CEREMONY_BIN}" ]; then
    echo "${CEREMONY_BIN} is not executable. Exiting..."
    exit 1
fi

RAMDISK_DIR="${2}"
if [ ! -d "${RAMDISK_DIR}" ]; then
    echo "${RAMDISK_DIR} does not exist. Exiting..."
    exit 1
fi

CEREMONY_YEAR="$(basename "$(dirname "$(readlink -f "${0}")")")"
echo "Running ceremony: ${CEREMONY_YEAR}"

CEREMONY_DIR="$(dirname ${BASH_SOURCE[0]})"
cd ${CEREMONY_DIR}


"${CEREMONY_BIN}" --config "./e5-key.yaml"
"${CEREMONY_BIN}" --config "./e6-key.yaml"
"${CEREMONY_BIN}" --config "./e7-key.yaml"
"${CEREMONY_BIN}" --config "./e8-key.yaml"
"${CEREMONY_BIN}" --config "./e9-key.yaml"
"${CEREMONY_BIN}" --config "./r10-key.yaml"
"${CEREMONY_BIN}" --config "./r11-key.yaml"
"${CEREMONY_BIN}" --config "./r12-key.yaml"
"${CEREMONY_BIN}" --config "./r13-key.yaml"
"${CEREMONY_BIN}" --config "./r14-key.yaml"

"${CEREMONY_BIN}" --config "./e5-cert.yaml"
"${CEREMONY_BIN}" --config "./e6-cert.yaml"
"${CEREMONY_BIN}" --config "./e7-cert.yaml"
"${CEREMONY_BIN}" --config "./e8-cert.yaml"
"${CEREMONY_BIN}" --config "./e9-cert.yaml"
"${CEREMONY_BIN}" --config "./r10-cert.yaml"
"${CEREMONY_BIN}" --config "./r11-cert.yaml"
"${CEREMONY_BIN}" --config "./r12-cert.yaml"
"${CEREMONY_BIN}" --config "./r13-cert.yaml"
"${CEREMONY_BIN}" --config "./r14-cert.yaml"

"${CEREMONY_BIN}" --config "./e5-cross-cert.yaml"
"${CEREMONY_BIN}" --config "./e6-cross-cert.yaml"
"${CEREMONY_BIN}" --config "./e7-cross-cert.yaml"
"${CEREMONY_BIN}" --config "./e8-cross-cert.yaml"
"${CEREMONY_BIN}" --config "./e9-cross-cert.yaml"

# Verify the root -> intermediate signatures, plus the TLS Server Auth EKU.
# -check_ss_sig means to verify the root certificate's self-signature.

## 1704067201 is Dec 31 2024; this is necessary because we're testing with NotBefore in the future.
openssl verify -check_ss_sig -attime 1704067201 -CAfile ${RAMDISK_DIR}/2015/root-x1.cert.pem -purpose sslserver \
    ${RAMDISK_DIR}/2023/int-e5-cross.cert.pem \
    ${RAMDISK_DIR}/2023/int-e6-cross.cert.pem \
    ${RAMDISK_DIR}/2023/int-e7-cross.cert.pem \
    ${RAMDISK_DIR}/2023/int-e8-cross.cert.pem \
    ${RAMDISK_DIR}/2023/int-e9-cross.cert.pem \
    ${RAMDISK_DIR}/2023/int-r10.cert.pem \
    ${RAMDISK_DIR}/2023/int-r11.cert.pem \
    ${RAMDISK_DIR}/2023/int-r12.cert.pem \
    ${RAMDISK_DIR}/2023/int-r13.cert.pem \
    ${RAMDISK_DIR}/2023/int-r14.cert.pem

openssl verify -check_ss_sig -attime 1704067201 -CAfile ${RAMDISK_DIR}/2020/root-x2.cert.pem -purpose sslserver \
    ${RAMDISK_DIR}/2023/int-e5.cert.pem \
    ${RAMDISK_DIR}/2023/int-e6.cert.pem \
    ${RAMDISK_DIR}/2023/int-e7.cert.pem \
    ${RAMDISK_DIR}/2023/int-e8.cert.pem \
    ${RAMDISK_DIR}/2023/int-e9.cert.pem
