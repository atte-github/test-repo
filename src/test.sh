buildkite-agent pipeline upload pipeline.yml

export timeout_in_minutes=23
echo timeout_in_minutes

# Define variables
ORG_NAME="atte-test-org-1"
PIPELINE_NAME="first"
API_TOKEN="bkua_63fa9fec9d119f650e8b00a2b5f0c5c20036cc65"

build_id="9053"
#cooldown_seconds=610133 # 1 hour cooldownss

build_status=$(curl -s -H "Authorization: Bearer $API_TOKEN" -X GET "https://api.buildkite.com/v2/organizations/$ORG_NAME/pipelines/$PIPELINE_NAME/builds/$build_id" | jq -r '.state')

