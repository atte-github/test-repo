#!/bin/bash
set -euo pipefail

echo "Retry count: $BUILDKITE_RETRY_COUNT"

# Sequence you want:
# 0 → -1
# 1 → 143
# 2 → -1
# 3 → 143
# 4 → -1

if [ "$BUILDKITE_RETRY_COUNT" -eq 0 ]; then
  echo "First run → failing with -1"
  exit -1
fi

if [ "$BUILDKITE_RETRY_COUNT" -eq 1 ]; then
  echo "Retry 1 → failing with 143"
  exit 143
fi

if [ "$BUILDKITE_RETRY_COUNT" -eq 2 ]; then
  echo "Retry 2 → failing with -1"
  exit -1
fi

if [ "$BUILDKITE_RETRY_COUNT" -eq 3 ]; then
  echo "Retry 3 → failing with 143"
  exit 143
fi

if [ "$BUILDKITE_RETRY_COUNT" -eq 4 ]; then
  echo "Retry 4 → failing with -1"
  exit -1
fi

# Fallback (should never be reached)
echo "Unexpected retry count: $BUILDKITE_RETRY_COUNT"
exit 1
