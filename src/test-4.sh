#!/bin/bash
set -euo pipefail

 RETRY_COUNT=${BUILDKITE_RETRY_COUNT:-0}
echo "================================================"
echo "Attempt: $((RETRY_COUNT + 1))"
echo "BUILDKITE_RETRY_COUNT: $RETRY_COUNT"
echo "================================================"

# Pattern: 143, -1, 143, -1
# Retry 0 (first attempt): exit 143
# Retry 1: exit -1 (255)
# Retry 2: exit 143
# Retry 3: exit -1 (255)

case $RETRY_COUNT in
  0)
    echo "❌ First attempt - Failing with exit 143 (SIGTERM)"
    sleep 1
    kill -TERM $$
    ;;
  1)
    echo "❌ Second attempt (retry 1) - Failing with exit -1"
    sleep 1
    exit 255
    ;;
  2)
    echo "❌ Third attempt (retry 2) - Failing with exit 143 (SIGTERM)"
    sleep 1
    kill -TERM $$
    ;;
  3)
    echo "❌ Fourth attempt (retry 3) - Failing with exit -1"
    sleep 1
    exit 255
    ;;
  *)
    echo "✅ Unexpected retry count, passing..."
    exit 0
    ;;
esac
