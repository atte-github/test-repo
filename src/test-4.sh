#!/usr/bin/env bash
set -euo pipefail

echo "Retry count: $$BUILDKITE_RETRY_COUNT"

if [[ "$$BUILDKITE_RETRY_COUNT" == "0" ]]; then
      echo "Run 1 → failing with -1"
      exit -1
elif [[ "$$BUILDKITE_RETRY_COUNT" == "1" ]]; then
       echo "Run 2 → failing with 143"
       exit 143
elif [[ "$$BUILDKITE_RETRY_COUNT" == "2" ]]; then
       echo "Run 3 → failing with 143"
       exit 143
elif [[ "$$BUILDKITE_RETRY_COUNT" == "3" ]]; then
       echo "Run 4 → failing with -1"
       exit -1
 else
       echo "Run 5+ → success"
       exit 0
fi
