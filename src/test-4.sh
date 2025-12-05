#!/usr/bin/env bash
set -euo pipefail

# Track attempt count across retries
ATTEMPT_FILE=".attempt-count"

if [[ ! -f "$ATTEMPT_FILE" ]]; then
  echo 1 > "$ATTEMPT_FILE"
else
  ATTEMPT=$(( $(cat "$ATTEMPT_FILE") + 1 ))
  echo "$ATTEMPT" > "$ATTEMPT_FILE"
fi

ATTEMPT=$(cat "$ATTEMPT_FILE")
echo "Running attempt: $ATTEMPT"

case "$ATTEMPT" in
  1)
    echo "Exiting with -1"
    exit -1
    ;;
  2)
    echo "Exiting with 143"
    exit 143
    ;;
  3)
    echo "Exiting with 143"
    exit 143
    ;;
  4)
    echo "Exiting with -1"
    exit -1
    ;;
  *)
    echo "No more retries expected. Exiting successfully."
    exit 0
    ;;
esac
