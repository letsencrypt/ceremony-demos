#!/bin/bash -e

function usage() {
    echo -e "Usage:
    This script simulates Let's Encrypt key ceremonies where we previously have
    or eventually will be generating cryptographic material.

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

function setup_softhsm2() {
    # see init-softhsm.sh for slot initialization
    export SOFTHSM2_CONF="${PWD}/softhsm2.conf"
    echo "directories.tokendir = ${PWD}/softhsm/" > ${SOFTHSM2_CONF}
}

function output_human_readable_text_files() {
    for x in $(find ./ceremonies/ -type f -name '*.cert.pem'); do
        openssl x509 -text -noout -out "${x%.*}.txt" -in "${x}" &
    done

    for r in $(find ./ceremonies/ -type f -name '*.cross-csr.pem'); do
        openssl req -text -noout -out "${r%.*}.txt" -in "${r}" &
    done

    for c in $(find ./ceremonies -type f -name '*.crl.pem'); do
        openssl crl -text -noout -out "${c%.*}.txt" -in "${c}" &
    done

    wait
}

function run_ceremonies() {
    ./ceremonies/2015/run.sh || return 1
    ./ceremonies/2000/run.sh || return 1
    ./ceremonies/2020/run.sh || return 1
    ./ceremonies/2021/run.sh || return 1
    ./ceremonies/2023/run.sh || return 1
}

setup_softhsm2
run_ceremonies
output_human_readable_text_files

RETVAL=$?
if [ "${RETVAL}" -eq 0 ]; then
    echo "All done!"
else
    echo "Exited early due to error"
    exit "${RETVAL}"
fi
