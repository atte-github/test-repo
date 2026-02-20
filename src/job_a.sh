#!/bin/bash
set -euo pipefail

echo "Retry count: ${BUILDKITE_RETRY_COUNT:-0}"

if [ "${BUILDKITE_RETRY_COUNT:-0}" -gt 0 ]; then
  echo "Retry detected → uploading with --replace"

  cat <<YAML | buildkite-agent pipeline upload --replace
steps:
  - label: "Step A (retry)"
    key: step_a
    command: "echo Running Step A after retry && sleep 30"
YAML

else
  echo "First run → normal upload"

  cat <<YAML | buildkite-agent pipeline upload
steps:
  - label: "Step A"
    key: step_a
    command: "echo Running Step A first time && sleep 30"
YAML

  echo "Simulating failure so you can retry"
  exit 1
fi
