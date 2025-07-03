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
    if [ -n "${CEREMONY_BIN_2021}" ] && [ -x "${CEREMONY_BIN_2021}" ]; then
        export CEREMONY_BIN="${CEREMONY_BIN_2021}"
        return 0
    fi

    TOOLS="/tmp/ceremony-tools"

    # The 2021 ceremony was not conducted by Let's Encrypt, so this commit is
    # just a version that works with the configs in this directory.
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

"${CEREMONY_BIN}" --config "./root-x1-cross-cert.yaml"
"${CEREMONY_BIN}" --config "./root-x1-cross-csr.yaml"

## 1611300000 is Jan 22 2021; this ensures the check will still pass even after root-dst expires.
openssl verify \
    -check_ss_sig \
    -attime 1611300000 \
    -CAfile "../2000/root-dst.cert.pem" \
    "./root-x1-cross.cert.pem"

openssl req -noout -verify -in "./root-x1-cross.csr.pem"
