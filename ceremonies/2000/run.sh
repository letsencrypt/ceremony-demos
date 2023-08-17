#!/bin/bash -e

function usage() {
    echo -e "Usage:

    ./$(basename "${0}") /path/to/ceremony-binary /path/to/key-material
    "
}

if [ "${1}" == "-h" ]; then
    usage
    exit 0
fi

if [ "$#" -ne 2 ]; then
    usage
    exit 1
fi

CEREMONY_BIN="${1}"
if [ ! -x "${CEREMONY_BIN}" ]; then
    echo "${CEREMONY_BIN} is not executable. Exiting..."
    exit 1
fi

RAMDISK_DIR="${2}"
if [ ! -d "${RAMDISK_DIR}" ]; then
    echo "${RAMDISK_DIR} does not exist. Exiting..."
    exit 1
fi

CEREMONY_YEAR="$(basename "$(dirname "$(readlink -f "${0}")")")"
echo "Running ceremony: ${CEREMONY_YEAR}"

CEREMONY_DIR="$(dirname ${BASH_SOURCE[0]})"
cd "${CEREMONY_DIR}"

"${CEREMONY_BIN}" --config "./root-dst.yaml"
