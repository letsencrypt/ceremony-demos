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
    if [ -n "${CEREMONY_BIN_2026}" ] && [ -x "${CEREMONY_BIN_2026}" ]; then
        export CEREMONY_BIN="${CEREMONY_BIN_2026}"
        return 0
    fi

    TOOLS="/tmp/ceremony-tools"

    # This version was the most recent Boulder release at the time we prepared
    # this ceremony demo.
    CEREMONY_VER="v0.20260902.0"

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

# Produce the cross-signs and new CRLs.
"${CEREMONY_BIN}" --config "./root-x2-by-x1.yaml"
"${CEREMONY_BIN}" --config "./root-ye-by-x2.yaml"
"${CEREMONY_BIN}" --config "./root-yr-by-x1.yaml"
"${CEREMONY_BIN}" --config "./root-x1.crl.yaml"
"${CEREMONY_BIN}" --config "./root-x2.crl.yaml"

# Check that all the existing Gen Y intermediates (issued in 2025) still
# validate up to the existing Gen X roots (issued in 2015 and 2020) via the new
# cross-signs.
# 1767142861 is Dec 31, 2026.
openssl verify \
    -check_ss_sig \
    -attime 1767142861 \
    -trusted "../2015/root-x1.cert.pem" \
    -untrusted "./root-yr-by-x1.cert.pem" \
    -purpose sslserver \
    "../2025/int-yr1.cert.pem" \
    "../2025/int-yr2.cert.pem" \
    "../2025/int-yr3.cert.pem"

openssl verify \
    -check_ss_sig \
    -attime 1767142861 \
    -trusted "../2020/root-x2.cert.pem" \
    -untrusted "./root-ye-by-x2.cert.pem" \
    -purpose sslserver \
    "../2025/int-ye1.cert.pem" \
    "../2025/int-ye2.cert.pem" \
    "../2025/int-ye3.cert.pem"

openssl verify \
    -check_ss_sig \
    -attime 1767142861 \
    -trusted "../2015/root-x1.cert.pem" \
    -untrusted <(cat "./root-x2-by-x1.cert.pem" "./root-ye-by-x2.cert.pem") \
    -purpose sslserver \
    "../2025/int-ye1.cert.pem" \
    "../2025/int-ye2.cert.pem" \
    "../2025/int-ye3.cert.pem"
