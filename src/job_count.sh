#!/bin/bash

# Configuration
BUILDKITE_TOKEN="bkua_aecde0da59e7500d4c534ff80e1333fd30dd7fd4"
ORG_SLUG="atte-test-org-1"
PIPELINES=("first" "hello")
START_DATE="2025-11-01T00:00:00Z"
END_DATE="2025-11-07T23:59:59Z"

GRAPHQL_URL="https://graphql.buildkite.com/v1"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

count_jobs_for_pipeline() {
    local pipeline_slug="$1"
    local start_date="$2"
    local end_date="$3"
    
    local total_jobs=0
    local total_builds=0
    local cursor="null"
    local has_next_page="true"
    
    echo -e "${BLUE}Processing pipeline: ${pipeline_slug}${NC}"
    echo "------------------------------------------------------------"
    
    while [ "$has_next_page" = "true" ]; do
        # Build the GraphQL query
        local query=$(cat <<EOF
{
  "query": "query CountJobs(\$pipelineSlug: ID!, \$startDate: DateTime!, \$endDate: DateTime!, \$cursor: String) { pipeline(slug: \$pipelineSlug) { name builds( createdAtFrom: \$startDate, createdAtTo: \$endDate, first: 100, after: \$cursor ) { pageInfo { hasNextPage endCursor } edges { node { number createdAt jobs(type: COMMAND) { count } } } } } }",
  "variables": {
    "pipelineSlug": "${pipeline_slug}",
    "startDate": "${start_date}",
    "endDate": "${end_date}",
    "cursor": ${cursor}
  }
}
EOF
)
        
        # Make the API request
        local response=$(curl -s -X POST "${GRAPHQL_URL}" \
            -H "Authorization: Bearer ${BUILDKITE_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "${query}")
        
        # Check for errors
        if echo "$response" | jq -e '.errors' > /dev/null 2>&1; then
            echo "Error in GraphQL response:"
            echo "$response" | jq '.errors'
            return 1
        fi
        
        # Extract pagination info
        has_next_page=$(echo "$response" | jq -r '.data.pipeline.builds.pageInfo.hasNextPage')
        local end_cursor=$(echo "$response" | jq -r '.data.pipeline.builds.pageInfo.endCursor')
        
        # Set cursor for next iteration (with proper null handling)
        if [ "$end_cursor" != "null" ] && [ -n "$end_cursor" ]; then
            cursor="\"${end_cursor}\""
        else
            cursor="null"
        fi
        
        # Count jobs in this batch
        local builds=$(echo "$response" | jq -c '.data.pipeline.builds.edges[]')
        
        while IFS= read -r build; do
            if [ -n "$build" ]; then
                local build_number=$(echo "$build" | jq -r '.node.number')
                local job_count=$(echo "$build" | jq -r '.node.jobs.count')
                
                echo "  Build #${build_number}: ${job_count} jobs"
                
                total_jobs=$((total_jobs + job_count))
                total_builds=$((total_builds + 1))
            fi
        done <<< "$builds"
        
        # Break if no next page
        if [ "$has_next_page" != "true" ]; then
            break
        fi
    done
    
    echo ""
    echo -e "${GREEN}Summary for ${pipeline_slug}:${NC}"
    echo "  Total Builds: ${total_builds}"
    echo "  Total Jobs: ${total_jobs}"
    
    if [ $total_builds -gt 0 ]; then
        local avg=$(echo "scale=2; $total_jobs / $total_builds" | bc)
        echo "  Average Jobs per Build: ${avg}"
    fi
    echo ""
    
    # Return values by echoing them (bash doesn't have return for complex data)
    echo "${total_jobs},${total_builds}"
}

main() {
    echo "============================================================"
    echo "Buildkite Job Counter"
    echo "Period: ${START_DATE} to ${END_DATE}"
    echo "============================================================"
    echo ""
    
    local grand_total_jobs=0
    local grand_total_builds=0
    
    for pipeline in "${PIPELINES[@]}"; do
        local pipeline_slug="${ORG_SLUG}/${pipeline}"
        
        # Capture the output
        local result=$(count_jobs_for_pipeline "$pipeline_slug" "$START_DATE" "$END_DATE")
        
        # Extract the last line which contains our counts
        local counts=$(echo "$result" | tail -n 1)
        local jobs=$(echo "$counts" | cut -d',' -f1)
        local builds=$(echo "$counts" | cut -d',' -f2)
        
        # Only add if we got valid numbers
        if [[ "$jobs" =~ ^[0-9]+$ ]] && [[ "$builds" =~ ^[0-9]+$ ]]; then
            grand_total_jobs=$((grand_total_jobs + jobs))
            grand_total_builds=$((grand_total_builds + builds))
        fi
        
        # Print everything except the last line (which was our data line)
        echo "$result" | head -n -1
    done
    
    echo "============================================================"
    echo -e "${YELLOW}GRAND TOTAL across all pipelines:${NC}"
    echo "  Total Builds: ${grand_total_builds}"
    echo "  Total Jobs (git clones): ${grand_total_jobs}"
    echo "============================================================"
}

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    echo "Install it with: brew install jq (macOS) or apt-get install jq (Linux)"
    exit 1
fi

# Check if bc is installed (for calculations)
if ! command -v bc &> /dev/null; then
    echo "Error: bc is required but not installed."
    echo "Install it with: brew install bc (macOS) or apt-get install bc (Linux)"
    exit 1
fi

# Run main function
main
