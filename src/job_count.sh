#!/bin/bash

BUILDKITE_TOKEN="bkua_382edab54d5e878083ccaf5514cbd4ea03acb4fb"
PIPELINE_SLUG="tonbara/deploy"
START_DATE="2026-01-01T00:00:00Z"
END_DATE="2026-01-16T23:59:59Z"

echo "Counting jobs for: $PIPELINE_SLUG"
echo "Period: $START_DATE to $END_DATE"
echo ""

# Make API request
response=$(curl -s -X POST "https://graphql.buildkite.com/v1" \
  -H "Authorization: Bearer $BUILDKITE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "{ pipeline(slug: \"'$PIPELINE_SLUG'\") { builds(createdAtFrom: \"'$START_DATE'\", createdAtTo: \"'$END_DATE'\", first: 100) { edges { node { number jobs { count } } } } } }"
  }')

# Extract and sum job counts
total_jobs=$(echo "$response" | jq '[.data.pipeline.builds.edges[].node.jobs.count] | add')
total_builds=$(echo "$response" | jq '.data.pipeline.builds.edges | length')

echo "Total Builds: $total_builds"
echo "Total Jobs: $total_jobs"
