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

"${CEREMONY_BIN_HISTORIC}" --config "./root-dst.yaml"
