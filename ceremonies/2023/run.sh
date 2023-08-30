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

function _echo() {
    echo "$(date +'%Y/%m/%d %H:%M:%S') ${@}"
}

function setup_ceremony_tool() {
    TMPDIR="/tmp/ceremony-tools"
    
    if [ -z "${_CEREMONY_BIN_2023}" ]; then
        export _CEREMONY_BIN_2023="${TMPDIR}/bin/2023/ceremony"
    else
        if [ -x "${_CEREMONY_BIN_2023}" ]; then
            return 0
        fi
    fi
    
    mkdir -p "${TMPDIR}/bin/2023/"
    if [ ! -d "${TMPDIR}/boulder" ]; then
        git clone https://github.com/letsencrypt/boulder/ "${TMPDIR}/boulder"
    fi

    if [ ! -x "${TMPDIR}/bin/2023/ceremony" ]; then
        # Build ceremony on the commit prior to removing configuration of Policy OIDs.
        # This will allow all ceremonies prior to 2023 to complete successfully without
        # requiring backporting changes to those ceremonies and losing the historical
        # representation of the ceremony.
        cd "${TMPDIR}/boulder"
        git checkout 72e01b337abccc9b849a3063666943489bcc573d
        make
        cd -
        cp "${TMPDIR}/boulder/bin/ceremony" "${TMPDIR}/bin/2023/"
    fi
}

setup_ceremony_tool
if [ $? -ne 0 ]; then
    exit 1
fi

_CEREMONY_BIN="${_CEREMONY_BIN_2023}"
CEREMONY_YEAR="$(basename "$(dirname "$(readlink -f "${0}")")")"
_echo "Running ${CEREMONY_YEAR} ceremony with tooling at ${_CEREMONY_BIN}"

CEREMONY_DIR="$(dirname ${BASH_SOURCE[0]})"
cd "${CEREMONY_DIR}"

"${_CEREMONY_BIN}" --config "./e5-key.yaml"
"${_CEREMONY_BIN}" --config "./e6-key.yaml"
"${_CEREMONY_BIN}" --config "./e7-key.yaml"
"${_CEREMONY_BIN}" --config "./e8-key.yaml"
"${_CEREMONY_BIN}" --config "./e9-key.yaml"
"${_CEREMONY_BIN}" --config "./i1-key.yaml"
"${_CEREMONY_BIN}" --config "./r10-key.yaml"
"${_CEREMONY_BIN}" --config "./r11-key.yaml"
"${_CEREMONY_BIN}" --config "./r12-key.yaml"
"${_CEREMONY_BIN}" --config "./r13-key.yaml"
"${_CEREMONY_BIN}" --config "./r14-key.yaml"

"${_CEREMONY_BIN}" --config "./e5-cert.yaml"
"${_CEREMONY_BIN}" --config "./e6-cert.yaml"
"${_CEREMONY_BIN}" --config "./e7-cert.yaml"
"${_CEREMONY_BIN}" --config "./e8-cert.yaml"
"${_CEREMONY_BIN}" --config "./e9-cert.yaml"
"${_CEREMONY_BIN}" --config "./i1-cert.yaml"
"${_CEREMONY_BIN}" --config "./r10-cert.yaml"
"${_CEREMONY_BIN}" --config "./r11-cert.yaml"
"${_CEREMONY_BIN}" --config "./r12-cert.yaml"
"${_CEREMONY_BIN}" --config "./r13-cert.yaml"
"${_CEREMONY_BIN}" --config "./r14-cert.yaml"

"${_CEREMONY_BIN}" --config "./e5-cross-cert.yaml"
"${_CEREMONY_BIN}" --config "./e6-cross-cert.yaml"
"${_CEREMONY_BIN}" --config "./e7-cross-cert.yaml"
"${_CEREMONY_BIN}" --config "./e8-cross-cert.yaml"
"${_CEREMONY_BIN}" --config "./e9-cross-cert.yaml"

# Verify the root -> intermediate signatures, plus the TLS Server Auth EKU.
# -check_ss_sig means to verify the root certificate's self-signature.

## 1704067201 is Dec 31 2024; this is necessary because we're testing with NotBefore in the future.
openssl verify -check_ss_sig -attime 1704067201 -CAfile "../2015/root-x1.cert.pem" -purpose sslserver \
    "./int-e5-cross.cert.pem" \
    "./int-e6-cross.cert.pem" \
    "./int-e7-cross.cert.pem" \
    "./int-e8-cross.cert.pem" \
    "./int-e9-cross.cert.pem" \
    "./int-r10.cert.pem" \
    "./int-r11.cert.pem" \
    "./int-r12.cert.pem" \
    "./int-r13.cert.pem" \
    "./int-r14.cert.pem"

openssl verify -check_ss_sig -attime 1704067201 -CAfile "../2020/root-x2.cert.pem" -purpose sslserver \
    "./int-e5.cert.pem" \
    "./int-e6.cert.pem" \
    "./int-e7.cert.pem" \
    "./int-e8.cert.pem" \
    "./int-e9.cert.pem"

## 1695168000 is Sept 26, 2023
openssl verify -check_ss_sig -attime 1695686400 -CAfile "../2020/root-x2.cert.pem" -purpose sslserver \
    "./int-i1.cert.pem"

# Intermediate I1 is to be revoked after issuance and never used. It's purpose is to
# give us operational experience revoking an intermediate. In production we'll need to
# update a CRL.
"${_CEREMONY_BIN}" --config "./root-x2.crl.yaml"
openssl crl -inform PEM -in "./root-x2.crl.pem" -noout -crlnumber | grep -q crlNumber=0x6F || echo "Did not find expected CRL version"
