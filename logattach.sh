#!/usr/bin/env bash

# extract details from check run
checkDetails=$(gh api --method GET -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" "${CHECK_URL}" | jq -Rnr '[inputs] | join("\\n") | fromjson | .')
logUrl=$(echo -E "$checkDetails" | jq -r '.output.summary' | grep -oP '\[View logs\]\(\K.*(?=\))')
buildId=$(echo "$logUrl" | awk -F/ '{print $(NF)}')
appName=$(echo "$logUrl" | awk -F/ '{print $(NF-1)}')
prNumber=$(echo -E "$checkDetails" | jq '.pull_requests[0].number')

# collect cloudflare logs
url="https://api.cloudflare.com/client/v4/accounts/${ACCOUNTID}/pages/projects/${appName}/deployments/${buildId}/history/logs"

logData=$(curl --request GET \
  --url "$url" \
  --header 'Content-Type: application/json' \
  --header "X-Auth-Email: ${EMAIL}" \
  --header "X-Auth-Key: ${API_KEY}" | jq -r '.result.data | map("\(.ts) | \(.line)")[]' | awk -F ' [|] ' '{printf "%-27s | %s\n", $1, $2}' )

# find PR comment (its technically an issue)
## get first match, should only be one, but this will be safer
issue=$(gh api --method GET -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" "/repos/${GITHUB_REPOSITORY}/issues/${prNumber}/comments" |jq -Rnr '[inputs] | join("\\n") | fromjson | first(.[] | select(.user.login | test("cloudflare")))')
issueUrl=$(echo -E "$issue" | jq -r .url)
body=$(echo -E "$issue" | jq -r .body | sed '/<details>/,/<\/details>/d') # remove previously attached log
newBody="$body
<details><summary>Log Output</summary>

\`\`\`console
$logData
\`\`\`

</details>"
issueReturn=$(gh api --method PATCH -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" "$issueUrl" -f body="$newBody")


echo "========== job complete ========="
echo "----------  Issue Patch Data ----------"
echo "$issueReturn" | jq
echo "---------- Log Output ----------"
echo "$logData"