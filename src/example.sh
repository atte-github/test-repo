#!/bin/bash

BUILDKITE_TOKEN="bkua_aecde0da59e7500d4c534ff80e1333fd30dd7fd4"
PIPELINE_SLUG="atte-test-org-1/first"
START_DATE="2025-11-01T00:00:00Z"
END_DATE="2025-11-07T23:59:59Z"

echo "Testing API call..."
echo ""

curl -X POST "https://graphql.buildkite.com/v1" \
  -H "Authorization: Bearer $BUILDKITE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "{ pipeline(slug: \"'$PIPELINE_SLUG'\") { builds(createdAtFrom: \"'$START_DATE'\", createdAtTo: \"'$END_DATE'\", first: 100) { edges { node { number jobs { count } } } } } }"
  }'

echo ""
