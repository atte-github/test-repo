#!/bin/bash

BUILDKITE_TOKEN="bkua_aecde0da59e7500d4c534ff80e1333fd30dd7fd4"
PIPELINE_SLUG="atte-test-org-1/first"
START_DATE="2025-11-01T00:00:00Z"
END_DATE="2025-11-07T23:59:59Z"

# GraphQL query
QUERY='query {
  pipeline(slug: "'$PIPELINE_SLUG'") {
    builds(createdAtFrom: "'$START_DATE'", createdAtTo: "'$END_DATE'", first: 100) {
      edges {
        node {
          number
          jobs(type: COMMAND) {
            count
          }
        }
      }
    }
  }
}'

# Make API request
response=$(curl -s -X POST "https://graphql.buildkite.com/v1" \
  -H "Authorization: Bearer $BUILDKITE_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"query\": $(echo "$QUERY" | jq -Rs .)}")

# Check for errors
if echo "$response" | jq -e '.errors' >/dev/null 2>&1; then
  echo "Error:"
  echo "$response" | jq '.errors'
  exit 1
fi

# Count total jobs
echo "Builds and Jobs:"
echo "----------------"

total_jobs=0
total_builds=0

echo "$response" | jq -r '.data.pipeline.builds.edges[] | "\(.node.number),\(.node.jobs.count)"' | while IFS=',' read -r build_num job_count; do
  echo "Build #$build_num: $job_count jobs"
  total_jobs=$((total_jobs + job_count))
  total_builds=$((total_builds + 1))
  echo "$total_jobs" > /tmp/buildkite_total_jobs
  echo "$total_builds" > /tmp/buildkite_total_builds
done

# Read totals from temp files
total_jobs=$(cat /tmp/buildkite_total_jobs 2>/dev/null || echo 0)
total_builds=$(cat /tmp/buildkite_total_builds 2>/dev/null || echo 0)

echo ""
echo "Summary:"
echo "--------"
echo "Total Builds: $total_builds"
echo "Total Jobs: $total_jobs"

# Cleanup
rm -f /tmp/buildkite_total_jobs /tmp/buildkite_total_builds

