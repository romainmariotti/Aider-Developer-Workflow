#!/usr/bin/env bash

# Safety flags
set -euo pipefail

echo "Running Ruff lint check..."

# Temporary workspace
TMP_DIR="$(mktemp -d)"
RUFF_REPORT="$TMP_DIR/ruff_report.txt"

# Cleanup
trap 'rm -rf "$TMP_DIR"' EXIT

# First Ruff check
if ruff check app/ > "$RUFF_REPORT" 2>&1; then
    echo "Lint passed"
    exit 0
fi

echo "Lint issues detected – attempting auto-fix..."

# Try auto-fix
ruff check app/ --fix >> "$RUFF_REPORT" 2>&1 || true

# Second check
if ruff check app/ >> "$RUFF_REPORT" 2>&1; then
    echo "All issues fixed automatically"
    exit 0
fi

echo "Ruff still reports issues it cannot fix"
echo "Generating analysis report with Aider..."

# Truncate report to keep prompt reasonable
SHORT_REPORT="$(head -n 80 "$RUFF_REPORT")"

PROMPT="Analyze the following Ruff lint report.

Ruff has already auto-fixed all possible issues.

Now fix ONLY the remaining Ruff issues below.

RULES:
- Only modify code to fix listed issues
- Do NOT introduce new refactors
- Do NOT change unrelated code
- Do NOT fix anything not in the report

Your task:
- Summarize the issues that Ruff detected but could not auto-fix
- Group issues by category (e.g. exceptions, logic, design, style)
- Explain *why* Ruff cannot fix them automatically
- Provide high-level recommendations (do NOT modify code)
- Be concise and actionable

Output format (markdown):

## Summary

## Issue categories
- ...

## Why Ruff cannot auto-fix

## Recommended actions (human or refactor)

Ruff report:
$SHORT_REPORT
"

aider \
  --message "$PROMPT"

echo "====== Done ======"
