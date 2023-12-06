#!/bin/bash

# Stop execution on first exception/error
set -e

# Get all input argument as a string
scan_arguments="$*"

# Set directories to be used
base_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
owasp_dir="${base_dir}/dependency-check"
db_path="${owasp_dir}/data"
scanner_path="${owasp_dir}/bin/dependency-check.sh"

# Mark all dependency scripts as executables, because when restoring them as artifacts, permissions are lost
find . -type f -name "*.sh" -exec chmod +x {} \;

# If there's not database yet, unarchive it
if ! compgen -G "${db_path}/*.db" > /dev/null; then

    "${base_dir}/scripts/unarchive_owasp_db.sh"

fi

# Execute OWASP scanner using input arguments and without doing database updates
${scanner_path} ${scan_arguments} -n
