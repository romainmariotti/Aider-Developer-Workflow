#!/bin/bash

# Configuration
THRESHOLD=${1:-80} # 80% by default
COVERAGE_FILE="temp/coverage.xml"

# Create temp folder
mkdir -p temp

echo "Generating coverage report..."

# Run pytest with XML coverage report
pytest --cov=app --cov-report=xml:$COVERAGE_FILE --cov-report=term
STATUS=$?

# Stop if pytest fails
if [ $STATUS -ne 0 ]; then
  echo "Pytest failed — stopping coverage check."
  exit 1
fi

# Ensure coverage.xml exists
if [ ! -f "$COVERAGE_FILE" ]; then
  echo "Coverage report not found: $COVERAGE_FILE"
  exit 1
fi

# Extract coverage percentage
COVERAGE=$(python - <<EOF
import xml.etree.ElementTree as ET
tree = ET.parse("$COVERAGE_FILE")
root = tree.getroot()
print(int(float(root.attrib["line-rate"]) * 100))
EOF
)

echo "Actual coverage: ${COVERAGE}%"

#  Skip Aider in CI environments to avoid infinite loops
if [ "${CI}" = "true" ]; then
  echo "Running in CI — skipping Aider auto-fix."
  exit 0
fi

# Trigger Aider if below the threshold
if [ "${COVERAGE}" -lt "${THRESHOLD}" ]; then
  echo "Coverage < ${THRESHOLD}%. Asking Aider to improve tests..."
  aider app/ --message "Improve tests to reach at least ${THRESHOLD}% coverage"
else
  echo "Coverage is above threshold (${THRESHOLD}%). No action needed"
fi

# Clean up temp file
rm -f "$COVERAGE_FILE"