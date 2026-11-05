#!/bin/bash -evx

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
    if [ -n "${CEREMONY_BIN_2026_11}" ] && [ -x "${CEREMONY_BIN_2026_11}" ]; then
        export CEREMONY_BIN="${CEREMONY_BIN_2026_11}"
        return 0
    fi

    TOOLS="/tmp/ceremony-tools"

    # This version was the most recent Boulder release at the time we prepared
    # this ceremony demo.
    CEREMONY_VER="v0.20261105.0"

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
echo "Running ${CEREMONY_YEAR} ceremony with tooling at ${CEREMONY_VER}"

# Produce the new CRLs.
"${CEREMONY_BIN}" --config "./root-x1.crl.yaml"
"${CEREMONY_BIN}" --config "./root-x2.crl.yaml"
"${CEREMONY_BIN}" --config "./root-ye.crl.yaml"
"${CEREMONY_BIN}" --config "./root-yr.crl.yaml"

# Verify the CRLs.
openssl crl -verify -CAfile "../2015/root-x1.cert.pem" -in "./root-x1.crl.pem" -noout
openssl crl -verify -CAfile "../2020/root-x2.cert.pem" -in "./root-x2.crl.pem" -noout
openssl crl -verify -CAfile "../2025/root-ye.cert.pem" -in "./root-ye.crl.pem" -noout
openssl crl -verify -CAfile "../2025/root-yr.cert.pem" -in "./root-yr.crl.pem" -noout
