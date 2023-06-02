#!/usr/bin/env bash

echo "EMAIL: $EMAIL"
echo "ACCOUNTID: $ACCOUNTID"
echo "APP_NAME: ${APP_NAME}"
echo "PR_URL: ${PR_URL}"
echo "DETAILS_URL: ${DETAILS_URL}"
echo "CHECK_URL: ${CHECK_URL}"

url="https://api.cloudflare.com/client/v4/accounts/${ACCOUNTID}/pages/projects/${APP_NAME}/deployments/90075c2d-ffd3-44c2-a516-cf962416884a/history/logs"

logData=$(curl --request GET \
  --url $url \
  --header 'Content-Type: application/json' \
  --header "X-Auth-Email: ${EMAIL}" \
  --header "X-Auth-Key: ${API_KEY}" | jq -r '.result.data | map("\(.ts) | \(.line)")[]')

echo "Log data"
echo "------------"
echo "$logData"

#gh api --method GET -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" /repos/cyralinc/cyral-docs-v2/check-runs/13378092863 | jq '.output.summary' | grep -o -P '(?<=\[View logs\]\().*?(?=\))'

#var1=$(echo "$url" | awk -F/ '{print $(NF-1)}')
#var2=$(echo "$url" | awk -F/ '{print $NF}')