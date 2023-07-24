#!/bin/bash -e

function usage() {
    echo -e "Usage:
    This script simulates key ceremonies where we previously have
    or will be generating cryptographic material.

    ./$(basename "${0}") [-h]
        -h | Outputs this help text"
}

if [ "${1}" == "-h" ]; then
    usage
    exit 0
fi

if [ "$#" -ne 0 ]; then
    usage
    exit 1
fi

# see init-softhsm.sh for slot initialization
export SOFTHSM2_CONF="${PWD}/softhsm2.conf"
echo "directories.tokendir = ${PWD}/softhsm/" > ${SOFTHSM2_CONF}

# Store the output in a ramdisk so we don't chew up my disk endlessly running this tooling.
RAMDISK_DIR="/run/shm/ceremonies"
mkdir -p "${RAMDISK_DIR}"
for ceremonyYear in $(find ./ceremonies/ -maxdepth 1 -type d -printf '%P '); do
    mkdir -p "${RAMDISK_DIR}/${ceremonyYear}"
done
if [ ! -L "ceremony-output" ]; then
    ln -s "${RAMDISK_DIR}/" ceremony-output
fi

function setup_ceremony_tools() {
    TMPDIR="/tmp/ceremony-tools"
    mkdir -p "${TMPDIR}/bin/PRE_2023/"
    if [ ! -d "${TMPDIR}/boulder" ]; then
        git clone https://github.com/letsencrypt/boulder/ "${TMPDIR}/boulder"
    fi

    if [ ! -x "${TMPDIR}/boulder/bin/ceremony" ]; then
        # Build ceremony from main and store it
        cd "${TMPDIR}/boulder"
        make
        cd -
    else
        if [ -z "${_CEREMONY_BIN}" ]; then
            export _CEREMONY_BIN="${TMPDIR}/boulder/bin/ceremony"
        fi
        echo "Found executable ceremony tool built for the 2023 ceremony at ${_CEREMONY_BIN}"
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
    else
        if [ -z "${_CEREMONY_BIN_HISTORIC}" ]; then
            export _CEREMONY_BIN_HISTORIC="${TMPDIR}/bin/PRE_2023/ceremony"
        fi
        echo "Found executable ceremony tool built for ceremonies prior to 2023 at ${_CEREMONY_BIN_HISTORIC}"
    fi


}

function _output_human_readable_text_files() {
    # Generate human-readable text files from all of ceremony output files.
    for x in $(find -L ${RAMDISK_DIR} -type f -name '*.cert.pem'); do
        openssl x509 -text -noout -out "${x%.*}.txt" -in "${x}" &
    done

    for r in $(find -L ${RAMDISK_DIR} -type f -name '*.cross-csr.pem'); do
        openssl req -text -noout -verify -out "${r%.*}.txt" -in "${r}" &
    done

    for c in $(find -L ${RAMDISK_DIR} -type f -name '*.crl.pem'); do
        openssl crl -text -noout -out "${c%.*}.txt" -in "${c}" &
    done

    wait
}

function run_ceremonies() {
    ./ceremonies/2015/run.sh "${_CEREMONY_BIN_HISTORIC}" "${RAMDISK_DIR}"
    ./ceremonies/2000/run.sh "${_CEREMONY_BIN_HISTORIC}" "${RAMDISK_DIR}"
    ./ceremonies/2020/run.sh "${_CEREMONY_BIN_HISTORIC}" "${RAMDISK_DIR}"
    ./ceremonies/2021/run.sh "${_CEREMONY_BIN_HISTORIC}" "${RAMDISK_DIR}"
    ./ceremonies/2023/run.sh "${_CEREMONY_BIN}" "${RAMDISK_DIR}"

    _output_human_readable_text_files
}

setup_ceremony_tools
run_ceremonies

echo "All done!"
