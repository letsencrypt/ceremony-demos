#!/bin/bash -e

function usage() {
    echo -e "Usage:

    ./$(basename "${0}") /path/to/ceremony-binary
    "
}

if [ "${1}" == "-h" ]; then
    usage
    exit 0
fi

if [ "$#" -ne 1 ]; then
    usage
    exit 1
fi

CEREMONY_BIN="${1}"
if [ ! -x "${CEREMONY_BIN}" ]; then
    echo "${CEREMONY_BIN} is not executable. Exiting..."
    exit 1
fi

CEREMONY_YEAR="$(basename "$(dirname "$(readlink -f "${0}")")")"
echo "Running ceremony: ${CEREMONY_YEAR}"

CEREMONY_DIR="$(dirname ${BASH_SOURCE[0]})"
cd ${CEREMONY_DIR}

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

# Verify the root -> intermediate signatures, plus the TLS Server Auth EKU.
# -check_ss_sig means to verify the root certificate's self-signature.

## 1609459200 is Dec 31 2021; this is necessary because we're testing with NotBefore in the future.
openssl verify -check_ss_sig -attime 1609459200 -CAfile "../2015/root-x1.cert.pem" -purpose sslserver \
    "./int-r3.cert.pem" \
    "./int-r4.cert.pem"

openssl verify -check_ss_sig -attime 1609459200 -CAfile "./root-x2.cert.pem" -purpose sslserver \
    "./int-e1.cert.pem" \
    "./int-e2.cert.pem"
