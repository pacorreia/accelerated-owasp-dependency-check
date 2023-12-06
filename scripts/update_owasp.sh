#!/bin/bash

base_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."
owasp_dir="${base_dir}/dependency-check"
scanner_path="${owasp_dir}/bin/dependency-check.sh"

# Check if input version is valid and in semver format
echo "$1" | grep -E "^(((([0-9]{1,})\.){2}[0-9]{1,})|latest)$" > /dev/null
if [[ $? -eq 1 ]]; then

    echo "Missing/invalid version provided!"
    exit 1
fi

# From here stop execution on first error/exception
set -e

find . -type f -name "*.sh" -exec chmod +x {} \;

version=$1
current_version=null
responseCode=null

if [[ "$version" = "latest" ]]; then
    
    responseCode=$(curl \
            -s \
            -o /tmp/owaspLatestVersion.json \
            -w "%{http_code}" \
            -H "Accept: application/vnd.github+json" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            https://api.github.com/repos/jeremylong/DependencyCheck/releases/latest
    )

    if [[ $? -ne 0 ]]; then
        echo "[WARNING] curl failed with exit code $?" 
        version=null
    elif [[ $responseCode -ge 400 ]] || [[ $responseCode -ge 500 ]]; then
        echo "[WARNING] Failed to get determine OWASP latest version"
        echo "[WARNING] Error message below:"

        echo "[WARNING] $(jq -r '.message' /tmp/owaspLatestVersion.json)"

        version=null
    else
        version=$(jq -r '.name' /tmp/owaspLatestVersion.json | awk '{print $2}')
        echo "[INFO] Latest version is $version"
    fi    

else
    echo "[INFO] Requested version is $version"
fi

# Detect existing version
if [[ -e "$owasp_dir"  ]]; then
    current_version=$($scanner_path -v | awk '{ print $4 }')
    echo "[INFO] Current version is $current_version"

    # If the current version equals the one being requested, exits
    if [[ "$current_version" = "$version" ]]; then
        echo "[INFO] Version $version already exists, nothing to do."
        echo "[INFO] Exiting."

        exit 0
    fi
fi

if [[ $current_version == null ]] && [[ $version == null ]]; then
    echo "[ERROR] No current version and requested version is unavailable, exiting!"
    exit 1
fi

# Check if requested version is available from repository
remote_check_response=$(curl \
    -s \
    -I \
    -o /dev/null \
    -w "%{http_code}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/jeremylong/DependencyCheck/releases/tags/v${version})

# If the requested version does not exist, exits
if [[ $remote_check_response == 404 ]]; then
    echo "[WARNING] Version $version is not available remotely!"
    echo "[WARNING] If you suspect this outcome is wrong, please check OWASP Dependency Github repo manually."
    echo "[INFO] Exiting!"
    exit 0
fi

# If the request on availability returns something different from 200 and 404 then manual action is required
if [[ $remote_check_response != 200 ]]; then
    echo "[WARNING] Was not possbile to check if version $version is available."
    echo "[WARNING] Please try again later or check the OWASP dependency check releases manually."
    echo "[INFO] Exiting!"
    exit 0
fi    

# If the requested version exists, the existing one is going to be removed
if [[ -e "$owasp_dir"  ]]; then
    echo "[INFO] Removing previous version"
    rm -r -f "$owasp_dir"
fi

# Get the download address for requested version
echo "[INFO] Fetching download URL for version $version"
download_url=$(curl \
    -s \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/jeremylong/DependencyCheck/releases/tags/v${version} | \
    jq \
    -r \
    '.assets[] | select(.name| test("^dependency-check-(([0-9])\\.)+[0-9]-release.zip")) |select(.content_type == "application/zip").browser_download_url')

# Normalize output file
filename="owasp_dep_check_${version}.zip"

# Download requested version
echo "[INFO] Downloading OWASP Dependency Check from: $download_url"
wget -q -O "$filename" "$download_url"

# Unzip downloaded file
echo -e "[INFO] Unzipping file $filename"
unzip -q -o "$filename"

# Remove zip file no longer needed
rm -f "$filename"

echo "[INFO] Updated OWASP to version ${version}" > "$base_dir/commit_msg.txt"
echo "[INFO] All done." 