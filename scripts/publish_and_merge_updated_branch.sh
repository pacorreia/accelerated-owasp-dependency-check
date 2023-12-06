#!/bin/bash

# Stop execution on first error/exception
set -e

base_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."

find . -type f -name "*.sh" -exec chmod +x {} \;

if [[ $(git status -s | wc -l) -eq 0 ]]; then
    echo "[INFO] Working tree is empty, nothing to do."
    echo "[INFO] Exiting."

    exit 1
fi

# Setting basic identity for this repo
git config user.email "noreply@nhs.net"
git config user.name "Azure Devops build Service"

# Publish new branch to remote
echo "[INFO] Pushing changes to remote branch $(git branch --show-current)"

git add .
git commit -F "$base_dir/commit_msg.txt"
git push -u origin "$(git branch --show-current)"

"$base_dir/scripts/create_pull_request.sh"

echo "[INFO] Done"