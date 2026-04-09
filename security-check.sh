#!/usr/bin/env bash

# Safety flags:
# -e  : exit immediately if any command exits with a non‑zero status
# -u  : treat unset variables as errors
# -o pipefail : cause pipelines to fail if any command in the pipeline fails
set -euo pipefail

# Create a temporary directory to store scan results
TMP_DIR="$(mktemp -d)"
REPORT_FILE="$TMP_DIR/pip_audit.txt"

ISSUE_FILE="inputs/issue.md"

# Ensure temporary files are always cleaned up on exit
trap 'rm -rf "$TMP_DIR"' EXIT

# Run dependency scan
echo "Running pip-audit..."

# If no vulnerabilities are found, exit
if pip-audit > "$REPORT_FILE" 2>&1; then
  echo "No vulnerable dependencies found"
  exit 0
fi

echo "Vulnerabilities detected !"
echo ""

# Truncate the report to avoid sending too much data to Aider
SHORT_REPORT=$(head -n 50 "$REPORT_FILE")

# Generate issue content with Aider
echo "Generating GitHub issue with Aider..."

PROMPT="Analyze the following dependency vulnerability report.

Generate a concise GitHub issue in markdown with:

## Title
<short title>

## Summary
<short summary>

## Severity
<Low/Medium/High>

## Affected packages
<bullet list>

## Recommended fixes
<bullet list>

Be short and actionable.

Report:
$SHORT_REPORT
"

aider --message "$PROMPT" "$ISSUE_FILE"

echo ""
echo "Issue successfully generated at $ISSUE_FILE !"

# Preview
cat "$ISSUE_FILE"