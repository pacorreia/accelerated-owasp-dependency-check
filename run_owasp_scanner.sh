#!/bin/sh

# Stop execution on first exception/error
set -e

# Get all input argument as a string
scan_arguments="$*"

# Set directories to be used
base_dir="$( cd "$( dirname "$0" )" && pwd )/.."

if grep -q docker /proc/1/cgroup; then
    owasp_dir="/usr/share/dependency-check"
else
    owasp_dir="${base_dir}/dependency-check"
    # Mark all dependency scripts as executables, because when restoring them as artifacts, permissions are lost
    find "${base_dir}/scripts" -type f -name "*.sh" -exec chmod +x {} \;
fi

db_path="${owasp_dir}/data"
scanner_path="${owasp_dir}/bin/dependency-check.sh"

# If there's not database yet, unarchive it
if ! find "${db_path}" -name "*.db" -print -quit > /dev/null 2>&1; then

    "${base_dir}/scripts/unarchive_owasp_db.sh"

fi

# Execute OWASP scanner using input arguments and without doing database updates
${scanner_path} ${scan_arguments} -n
