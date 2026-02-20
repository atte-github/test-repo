#!/bin/bash

BUILDKITE_TOKEN="bkua_382edab54d5e878083ccaf5514cbd4ea03acb4fb"

echo "Listing all pipelines you have access to..."
echo ""

curl -X POST "https://graphql.buildkite.com/v1" \
  -H "Authorization: Bearer $BUILDKITE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "{ viewer { user { name } organizations(first: 10) { edges { node { name slug pipelines(first: 50) { edges { node { name slug } } } } } } } }"
  }' | jq '.'
