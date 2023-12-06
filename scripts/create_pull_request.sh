#!/bin/bash

repositoryId=$BUILD_REPOSITORY_ID

echo  "[INFO] Repository Id is $repositoryId"

# construct base URLs
apisUrl="${SYSTEM_TEAMFOUNDATIONCOLLECTIONURI}${SYSTEM_TEAMPROJECT}/_apis"
projectUrl="${apisUrl}/git/repositories/${repositoryId}"

echo "[INFO] Project URL is $projectUrl"

# create common headers
authorization_header="Authorization: Bearer $SYSTEM_ACCESSTOKEN"
content_type_header="Content-Type: application/json"

currentBranch=$(git branch --show-current)

# Create a Pull Request
pullRequestUrl="${projectUrl}/pullrequests?api-version=5.1"

build_pullrequest_body()
{
    cat <<EOF
{
    "sourceRefName": "refs/heads/$currentBranch",
    "targetRefName": "refs/heads/main",
    "title": "Pull from $currentBranch to main",
    "description": ""
}
EOF
}

pullRequestJson=$(build_pullrequest_body)

echo "[INFO] Sending a REST call to create a new pull request from $currentBranch to main"

# REST call to create a Pull Request
pullRequestResult=$(curl \
    -s \
    -X POST \
    -w "%{http_code}" \
    -o /tmp/pullRequestResult.json \
    -H "$authorization_header" \
    -H "$content_type_header" \
    --data "$pullRequestJson" \
    "$pullRequestUrl"
)

if [[ $pullRequestResult -ge 400  ]] || [[ $pullRequestResult -ge 500 ]]; then
    echo "Failed to create pull request!"
    echo "Message bellow:"

    jq -r '.message' /tmp/pullRequestResult.json

    exit 1
else
   pullRequestResult=$(cat /tmp/pullRequestResult.json)
fi

pullRequestId=$(echo "$pullRequestResult" | jq -r '.pullRequestId')

echo "[INFO] Pull request created. Pull Request Id: $pullRequestId"

# Set PR to auto-complete
build_autocomplete_body()
{
    cat <<EOF
{
    "autoCompleteSetBy": {
        "id": "$(echo "$pullRequestResult" | jq -r '.createdBy.id')"
    },
    "completionOptions": {       
        "deleteSourceBranch": true,
        "bypassPolicy": false,
        "mergeStrategy": "rebase"
    }    
}
EOF
}

setAutoCompleteJson=$(build_autocomplete_body)

echo "[INFO] Sending a REST call to set auto-complete on the newly created pull request"

# REST call to set auto-complete on Pull Request
pullRequestUpdateUrl="${projectUrl}/pullRequests/${pullRequestId}?api-version=5.1"

setAutoCompleteResult=$(curl \
    -s \
    -o /tmp/setAutoCompleteResult.json \
    -w "%{http_code}" \
    -X PATCH \
    -H "$authorization_header" \
    -H "$content_type_header" \
    --data "$setAutoCompleteJson" \
    "$pullRequestUpdateUrl"
)

if [[ $setAutoCompleteResult -ge 400  ]] && [[ $setAutoCompleteResult -ge 500 ]]; then
    echo "Failed to set auto-complete, please open your pull-request set auto-complete."
    echo "Error bellow:"

    jq -r '.message' /tmp/setAutoCompleteResult.json

    exit 1
fi

echo "[INFO] Pull request set to auto-complete"