#!/bin/bash
set -euo pipefail

THRESHOLD=${1:-80}
TMP_DIR="temp"
REPORT_FILE="$TMP_DIR/coverage_recommendations.md"

mkdir -p "$TMP_DIR"

echo "Running tests with coverage..."

OUTPUT=$(pytest --cov=app --cov-report=term || true)

echo "$OUTPUT"

# Extract coverage %
COVERAGE=$(echo "$OUTPUT" | grep -Eo '[0-9]+%' | tail -1 | tr -d '%')

if [ -z "$COVERAGE" ]; then
  echo "Could not extract coverage"
  exit 1
fi

echo "Coverage: ${COVERAGE}%"

# Ok case (clean exit)
if [ "$COVERAGE" -ge "$THRESHOLD" ]; then
  echo "Coverage sufficient (${COVERAGE}% ≥ ${THRESHOLD}%)."

  # Cleanup
  rm -f .coverage

  exit 0
fi

# Fail case
GAP=$((THRESHOLD - COVERAGE))

echo "Coverage below threshold. Generating AI recommendations..."

PROMPT="Give recommendation to improve coverage and reach target.

Coverage is below target.

Current coverage: ${COVERAGE}%
Target: ${THRESHOLD}%
Gap: ${GAP}%

Your task:
- ONLY provide recommendations
- DO NOT write any code
- DO NOT include pytest examples
- DO NOT include snippets or pseudo-code
- DO NOT include implementation details

Return a clean markdown report with:

## Summary
## Key issues in test coverage
## Missing test areas (conceptual only)
## Risk areas in the codebase
## Prioritized action plan

Be concise, practical, and non-technical in terms of code.
Focus on WHAT to test, not HOW to write tests.
"

aider --message "$PROMPT" "$REPORT_FILE"

echo "Aider report generated:"
cat "$REPORT_FILE"

# Final cleanup
rm -f .coverage