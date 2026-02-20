#!/bin/bash
set -euo pipefail

echo "Job B uploading Step C..."

sleep 5  # helps create timing overlap

cat <<YAML | buildkite-agent pipeline upload
steps:
  - label: "Step C"
    key: step_c
    command: "echo Running Step C && sleep 60"
YAML

echo "Job B finished"
