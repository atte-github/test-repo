#!/bin/bash
set -euo pipefail

 RETRY_COUNT=${BUILDKITE_RETRY_COUNT:-0}
6      
7      echo "================================================"
8      echo "Attempt: $((RETRY_COUNT + 1))"
9      echo "BUILDKITE_RETRY_COUNT: $RETRY_COUNT"
10      echo "================================================"
11      
12      # Pattern: 143, -1, 143, -1
13      # Retry 0 (first attempt): exit 143
14      # Retry 1: exit -1 (255)
15      # Retry 2: exit 143
16      # Retry 3: exit -1 (255)
17      
18      case $RETRY_COUNT in
19        0)
20          echo "❌ First attempt - Failing with exit 143 (SIGTERM)"
21          sleep 1
22          kill -TERM $$
23          ;;
24        1)
25          echo "❌ Second attempt (retry 1) - Failing with exit -1"
26          sleep 1
27          exit 255
28          ;;
29        2)
30          echo "❌ Third attempt (retry 2) - Failing with exit 143 (SIGTERM)"
31          sleep 1
32          kill -TERM $$
33          ;;
34        3)
35          echo "❌ Fourth attempt (retry 3) - Failing with exit -1"
36          sleep 1
37          exit 255
38          ;;
39        *)
40          echo "✅ Unexpected retry count, passing..."
41          exit 0
42          ;;
43      esac
