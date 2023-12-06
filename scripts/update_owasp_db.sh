#!/bin/sh

# Stop execution on first error/exception
set -e

# Set directories to be used
base_dir="$( cd "$( dirname "$0" )" && pwd )/.."

if grep -q docker /proc/1/cgroup; then
    owasp_dir="/usr/share/dependency-check"
else
    owasp_dir="${base_dir}/dependency-check"
fi

db_path="${owasp_dir}/data"
scanner_path="${owasp_dir}/bin/dependency-check.sh"
nvdApiKey="$1"

echo ${nvdApiKey}


find . -type f -name "*.sh" -exec chmod +x {} \;

# Get current script version to determine if the NVD API key is needed
version_requiring_nvd="9.0.0"
current_version=$($scanner_path -v | awk '{ print $4 }')

if [ -e "${base_dir}/owasp_db.tar.gz" ] && ! find "${db_path}" -name "*.db" -print -quit 2>/dev/null; then
    echo "[INFO] Found previous H2 database!"
    echo "[INFO] Unarchiving H2 database to avoid full update."
    "$base_dir/scripts/unarchive_owasp_db.sh"

    echo "[INFO] Database restored."
else
    echo "[INFO] No previous H2 database found."
    echo "[INFO] Will run a full update."
fi

# Run OWASP in update only mode

if [ "$(printf "%s\n%s" "${version_requiring_nvd}" "${current_version}" | sort -V | head -n1)" = "${version_requiring_nvd}" ]; then
    if [ -z "${nvdApiKey}" ]; then
        echo "[ERROR]: NVD API key is required starting from version 9.0.0!"
        exit 1
    fi
    if ${scanner_path} --updateonly --nvdApiKey "${nvdApiKey}"; then
        echo "[INFO] Updated OWASP database"
    fi
else
    if ${scanner_path} --updateonly; then
        echo "[INFO] Updated OWASP database"
    fi
fi