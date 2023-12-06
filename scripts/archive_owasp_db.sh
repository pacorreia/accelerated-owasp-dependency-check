#!/bin/bash

# Stop executin on first error
set -e

# Set directories to be used
base_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
owasp_dir="${base_dir}/dependency-check"
db_path="${owasp_dir}/data"

# Check if OWASP folder exists
if [[ ! -e $owasp_dir ]]; then
    echo "[ERROR] Missing OWASP folder!"
    exit 1
fi

# Check there's a database in data folder
if ! compgen -G "${db_path}/*.db" > /dev/null; then
    echo "[ERROR] There's no H2 database present to be archived!"
    exit 1
fi

# Archive database using gzip compression
echo "[INFO] Archiving H2 database"

tar -C "$db_path" -czf owasp_db.tar.gz "odc.mv.db"

echo "[INFO] Done"