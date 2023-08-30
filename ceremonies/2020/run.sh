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
    TMPDIR="/tmp/ceremony-tools"
    
    if [ -z "${CEREMONY_BIN_HISTORIC}" ]; then
        export CEREMONY_BIN_HISTORIC="${TMPDIR}/bin/PRE_2023/ceremony"
    else
        if [ -x "${CEREMONY_BIN_HISTORIC}" ]; then
            return 0
        fi
    fi
    
    mkdir -p "${TMPDIR}/bin/PRE_2023/"
    if [ ! -d "${TMPDIR}/boulder" ]; then
        git clone https://github.com/letsencrypt/boulder/ "${TMPDIR}/boulder"
    fi

    if [ ! -x "${TMPDIR}/bin/PRE_2023/ceremony" ]; then
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
if [ $? -ne 0 ]; then
    exit 1
fi

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

# Verify the root -> intermediate signatures, plus the TLS Server Auth EKU.
# -check_ss_sig means to verify the root certificate's self-signature.

## 1609459200 is Dec 31 2021; this is necessary because we're testing with NotBefore in the future.
openssl verify -check_ss_sig -attime 1609459200 -CAfile "../2015/root-x1.cert.pem" -purpose sslserver \
    "./int-r3.cert.pem" \
    "./int-r4.cert.pem"

openssl verify -check_ss_sig -attime 1609459200 -CAfile "./root-x2.cert.pem" -purpose sslserver \
    "./int-e1.cert.pem" \
    "./int-e2.cert.pem"
