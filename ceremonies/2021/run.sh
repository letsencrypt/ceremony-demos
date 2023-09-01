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
        # This will allow all ceremonies prior to 2023 to complete successfully without
        # requiring backporting changes to those ceremonies and losing the historical
        # representation of the ceremony.
        cd "${TMPDIR}/boulder"
        git checkout 7d66d67054616867121e822fdc8ae58b10c1d71a
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

"${CEREMONY_BIN_HISTORIC}" --config "./root-x1-cross-cert.yaml"
"${CEREMONY_BIN_HISTORIC}" --config "./root-x1-cross-csr.yaml"

## 1611300000 is Jan 22 2021; this ensures the check will still pass even after root-dst expires.
openssl verify \
    -check_ss_sig \
    -attime 1611300000 \
    -CAfile "../2000/root-dst.cert.pem" \
    "./root-x1-cross.cert.pem"

openssl req -noout -verify -in "./root-x1-cross.csr.pem"
