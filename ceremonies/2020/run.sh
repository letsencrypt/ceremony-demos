#!/bin/bash -e

function usage() {
    echo -e "Usage:

    ./$(basename "${0}")
    "
}

if [ "${1}" == "-h" ]; then
    usage
    exit 0
fi

function _echo() {
    echo "$(date +'%Y/%m/%d %H:%M:%S') ${@}"
}

function setup_ceremony_tool() {
    if [ -n "${CEREMONY_BIN_HISTORIC}" ] && [ -x "${CEREMONY_BIN_HISTORIC}" ]; then
        return 0
    fi

    TMPDIR="/tmp/ceremony-tools"
    export CEREMONY_BIN_HISTORIC="${TMPDIR}/bin/PRE_2023/ceremony"
    mkdir -p "${TMPDIR}/bin/PRE_2023/"
    if [ ! -d "${TMPDIR}/boulder" ]; then
        git clone https://github.com/letsencrypt/boulder/ "${TMPDIR}/boulder"
    fi

    if [ ! -x "${CEREMONY_BIN_HISTORIC}" ]; then
        # Build ceremony on the commit prior to removing configuration of Policy OIDs.
        # This will allow all ceremonies prior to 2021 to complete successfully without
        # requiring backporting changes to those ceremonies and losing the historical
        # representation of the ceremony.
        cd "${TMPDIR}/boulder"
        git checkout d73125d8f6ad0e0cbb8d9926a387580dccf8c99a
        make
        cd -
        cp "${TMPDIR}/boulder/bin/ceremony" "${TMPDIR}/bin/PRE_2023/"
    fi
}

setup_ceremony_tool

CEREMONY_YEAR="$(basename "$(dirname "$(readlink -f "${0}")")")"
_echo "Running ${CEREMONY_YEAR} ceremony with tooling at ${CEREMONY_BIN_HISTORIC}"

CEREMONY_DIR="$(dirname ${BASH_SOURCE[0]})"
cd "${CEREMONY_DIR}"

"${CEREMONY_BIN_HISTORIC}" --config "./root-x2.yaml"
"${CEREMONY_BIN_HISTORIC}" --config "./root-x2-cross-cert.yaml"
"${CEREMONY_BIN_HISTORIC}" --config "./root-x1.crl.yaml"
"${CEREMONY_BIN_HISTORIC}" --config "./root-x2.crl.yaml"

"${CEREMONY_BIN_HISTORIC}" --config "./e1-key.yaml"
"${CEREMONY_BIN_HISTORIC}" --config "./e2-key.yaml"
"${CEREMONY_BIN_HISTORIC}" --config "./r3-key.yaml"
"${CEREMONY_BIN_HISTORIC}" --config "./r4-key.yaml"

"${CEREMONY_BIN_HISTORIC}" --config "./e1-cert.yaml"
"${CEREMONY_BIN_HISTORIC}" --config "./e2-cert.yaml"
"${CEREMONY_BIN_HISTORIC}" --config "./r3-cert.yaml"
"${CEREMONY_BIN_HISTORIC}" --config "./r4-cert.yaml"

"${CEREMONY_BIN_HISTORIC}" --config "./r3-cross-csr.yaml"
"${CEREMONY_BIN_HISTORIC}" --config "./r4-cross-csr.yaml"

## 1609459200 is Dec 31 2021; this ensures the check will still pass even after root-x1 expires.
openssl verify \
    -check_ss_sig \
    -attime 1609459200 \
    -CAfile "../2015/root-x1.cert.pem" \
    -purpose sslserver \
    "./int-r3.cert.pem" \
    "./int-r4.cert.pem"

## 1609459200 is Dec 31 2021; this ensures the check will still pass even after root-x2 expires.
openssl verify \
    -check_ss_sig \
    -attime 1609459200 \
    -CAfile "./root-x2.cert.pem" \
    -purpose sslserver \
    "./int-e1.cert.pem" \
    "./int-e2.cert.pem"
