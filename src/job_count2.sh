#!/usr/bin/env bash
set -euo pipefail

# Set your API token in the environment:
BUILDKITE_TOKEN="bkua_382edab54d5e878083ccaf5514cbd4ea03acb4fb"

PIPELINE_SLUG="tonbara/deploy"
START_DATE="2026-01-07T00:00:00Z"
END_DATE="2026-01-16:T23:59:59Z"

echo "Counting jobs for pipeline: $PIPELINE_SLUG"
echo "Date range: $START_DATE → $END_DATE"
echo

after="null"
total_jobs=0
total_builds=0

while :; do
  payload=$(jq -n \
    --arg slug "$PIPELINE_SLUG" \
    --arg from "$START_DATE" \
    --arg to "$END_DATE" \
    --argjson after "$after" \
    '{
      query: "query($slug: ID!, $from: DateTime!, $to: DateTime!, $after: String) { pipeline(slug: $slug) { builds(first: 100, after: $after, createdAtFrom: $from, createdAtTo: $to) { pageInfo { hasNextPage endCursor } edges { node { number jobs { count } } } } } }",
      variables: { slug: $slug, from: $from, to: $to, after: $after }
    }')

  response=$(curl -sS -X POST https://graphql.buildkite.com/v1 \
    -H "Authorization: Bearer $BUILDKITE_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$payload")

  page_builds=$(echo "$response" | jq '.data.pipeline.builds.edges | length')
  page_jobs=$(echo "$response" | jq '[.data.pipeline.builds.edges[].node.jobs.count] | add // 0')

  total_builds=$(( total_builds + page_builds ))
  total_jobs=$(( total_jobs + page_jobs ))

  has_next=$(echo "$response" | jq -r '.data.pipeline.builds.pageInfo.hasNextPage')
  end_cursor=$(echo "$response" | jq -r '.data.pipeline.builds.pageInfo.endCursor // empty')

  if [[ "$has_next" != "true" || -z "$end_cursor" ]]; then
    break
  fi

  after=$(jq -n --arg c "$end_cursor" '$c')
done

echo "Total builds: $total_builds"
echo "Total jobs started: $total_jobs"

