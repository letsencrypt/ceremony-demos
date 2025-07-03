#!/bin/bash -e

set -o pipefail

function usage() {
    echo -e "Usage:

    ./$(basename "${0}")
    "
}

if [ "${1}" == "-h" ]; then
    usage
    exit 0
fi

function setup_ceremony_tool() {
    # If we've been given a path to an executable to use, just use that.
    if [ -n "${CEREMONY_BIN_2020}" ] && [ -x "${CEREMONY_BIN_2020}" ]; then
        export CEREMONY_BIN="${CEREMONY_BIN_2020}"
        return 0
    fi

    TOOLS="/tmp/ceremony-tools"

    # The ceremony-demos repo didn't exist in its current state at the time of
    # the 2020 ceremony, so this is just a version that works with the configs
    # in this directory.
    CEREMONY_VER="d73125d8f6ad0e0cbb8d9926a387580dccf8c99a"

    export CEREMONY_BIN="${TOOLS}/bin/${CEREMONY_VER}/ceremony"
    if [ -x "${CEREMONY_BIN}" ]; then
        return 0
    fi

    if [ ! -d "${TOOLS}/boulder" ]; then
        git clone https://github.com/letsencrypt/boulder/ "${TOOLS}/boulder"
    fi

    cd "${TOOLS}/boulder"
    git checkout "${CEREMONY_VER}"
    make
    cd -

    mkdir -p "$(dirname ${CEREMONY_BIN})"
    cp "${TOOLS}/boulder/bin/ceremony" "${CEREMONY_BIN}"
}

setup_ceremony_tool

CEREMONY_DIR="$(dirname ${BASH_SOURCE[0]})"
cd "${CEREMONY_DIR}"

CEREMONY_YEAR="$(basename ${CEREMONY_DIR})"
echo "Running ${CEREMONY_YEAR} ceremony with tooling at ${CEREMONY_BIN}"

"${CEREMONY_BIN}" --config "./root-x2.yaml"
"${CEREMONY_BIN}" --config "./root-x2-cross-cert.yaml"
"${CEREMONY_BIN}" --config "./root-x1.crl.yaml"
"${CEREMONY_BIN}" --config "./root-x2.crl.yaml"

"${CEREMONY_BIN}" --config "./e1-key.yaml"
"${CEREMONY_BIN}" --config "./e2-key.yaml"
"${CEREMONY_BIN}" --config "./r3-key.yaml"
"${CEREMONY_BIN}" --config "./r4-key.yaml"

"${CEREMONY_BIN}" --config "./e1-cert.yaml"
"${CEREMONY_BIN}" --config "./e2-cert.yaml"
"${CEREMONY_BIN}" --config "./r3-cert.yaml"
"${CEREMONY_BIN}" --config "./r4-cert.yaml"

"${CEREMONY_BIN}" --config "./r3-cross-csr.yaml"
"${CEREMONY_BIN}" --config "./r4-cross-csr.yaml"

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
