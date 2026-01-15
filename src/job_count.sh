#!/bin/bash

BUILDKITE_TOKEN="bkua_aecde0da59e7500d4c534ff80e1333fd30dd7fd4"
PIPELINE_SLUG="atte-test-org-1/first"
START_DATE="2025-11-01T00:00:00Z"
END_DATE="2025-11-07T23:59:59Z"

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
```

That's it! Save as `count_jobs.sh`, make executable with `chmod +x count_jobs.sh`, and run `./count_jobs.sh`

**Key changes:**
- Removed the complex loop - just use `jq` to sum all the counts in one line
- Uses `jq '[.data.pipeline.builds.edges[].node.jobs.count] | add'` to extract all counts and add them up

This should give you:
```
Total Builds: 25
Total Jobs: 68
