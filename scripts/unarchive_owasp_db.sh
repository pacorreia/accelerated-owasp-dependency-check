#!/bin/bash

# Stop execution on first error/exception
set -e

# Set directories to be used
base_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
owasp_dir="${base_dir}/dependency-check"
db_path="${owasp_dir}/data"


if [[ ! -e $base_dir/owasp_db.tar.gz ]]; then

    echo "[ERROR] Missing H2 database archive owasp_db.tar.gz"
    echo "[ERROR] Run [schedule]-owasp-update pipeline manually to create it!"

    exit 1
fi

# Untar database file do data folder
echo "[INFO] Unpacking H2 database"

if [[ ! -e $db_path ]]; then

    mkdir "$db_path"

fi

tar -C "$db_path" -xzf owasp_db.tar.gz

echo "[INFO] Done"