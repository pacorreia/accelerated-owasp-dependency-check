#!/bin/bash

# Stop execution on first exception/error
set -e

# Define new branch to be used
update_branch=update/$(date +%Y%m%d_%H%M%S)

# Create new branch and switch to it
echo "[INFO] Creating branch $update_branch"

git branch "$update_branch"
git switch "$update_branch"

echo "[INFO] Done"