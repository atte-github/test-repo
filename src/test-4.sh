#!/bin/bash
set -euo pipefail

RETRY_COUNT="${BUILDKITE_RETRY_COUNT:-0}"

echo "================================================"
echo "Attempt: $((RETRY_COUNT + 1))"
echo "BUILDKITE_RETRY_COUNT: $RETRY_COUNT"
echo "================================================"

case $RETRY_COUNT in
  0)
    echo "❌ First attempt - exiting with 255"
    sleep 1
    # exit 255
    exit 255
    ;;
  1)
    echo "❌ Second attempt - exiting with 2"
    sleep 1
    # exit 2
    exit 2
    ;;
  2)
    echo "❌ Third attempt - exiting with 255"
    sleep 1
    # exit 255
    exit 255
    ;;
  3)
    echo "❌ Fourth attempt - exiting with 2"
    sleep 1
    exit 2
    ;;
  4)
    echo "❌ Fifth attempt - exiting with -1"
    sleep 1
    exit -1
    ;;
  *)
    echo "✅ Unexpected retry count, passing..."
    exit 0
    ;;
esac
