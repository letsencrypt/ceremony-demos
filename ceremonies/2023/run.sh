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

    # This version was the most recent Boulder release at the time of the
    # 2024-03-13 ceremony.
    CEREMONY_VER="release-2024-03-12"

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


## 1704067201 is Dec 31, 2024
openssl verify \
    -check_ss_sig \
    -attime 1704067201 \
    -CAfile "../2015/root-x1.cert.pem" \
    -purpose sslserver \
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

openssl verify \
    -check_ss_sig \
    -attime 1704067201 \
    -CAfile "../2020/root-x2.cert.pem" \
    -purpose sslserver \
    "./int-e5.cert.pem" \
    "./int-e6.cert.pem" \
    "./int-e7.cert.pem" \
    "./int-e8.cert.pem" \
    "./int-e9.cert.pem"
