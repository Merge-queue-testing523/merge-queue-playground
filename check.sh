#!/usr/bin/env bash
# The required check. Slow enough to watch the queue, and able to fail on purpose.
set -euo pipefail
sleep "${CI_DELAY:-90}"

# A PR that is simply broken.
if grep -rl 'FAIL' items/ 2>/dev/null; then
  echo "A file in items/ contains FAIL"; exit 1
fi

# PRs that pass alone but break once combined.
count=$(find items -type f ! -name .gitkeep | wc -l)
max=$(cat max-items)
echo "items=$count max=$max"
if [ "$count" -gt "$max" ]; then
  echo "Too many items"; exit 1
fi
