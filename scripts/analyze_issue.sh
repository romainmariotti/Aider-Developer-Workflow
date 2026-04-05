# Mac script
# to make it executable -> chmod +x scripts/analyze_issue.sh

#!/usr/bin/env bash
set -euo pipefail

# This script converts a GitHub Issue (stored in inputs/issue.md)
# into documentation files using Aider.

ISSUE_FILE="inputs/issue.md"
PROMPT_FILE="prompts/issue_to_docs.md"

DOC_SPEC="docs/SPEC.md"
DOC_ARCH="docs/ARCHITECTURE.md"
DOC_DB="docs/DB_SCHEMA.md"

# Checks
command -v aider >/dev/null 2>&1 || { echo "❌ aider not found. Install/run aider first."; exit 1; }

if [ ! -f "$PROMPT_FILE" ]; then
  echo "❌ Missing $PROMPT_FILE"
  exit 1
fi

if [ ! -f "$ISSUE_FILE" ]; then
  echo "❌ Missing $ISSUE_FILE"
  echo "Create it and paste the GitHub issue body into it."
  exit 1
fi

# Ensure folders/files exist
mkdir -p docs
touch "$DOC_SPEC" "$DOC_ARCH" "$DOC_DB"

ISSUE_TEXT="$(cat "$ISSUE_FILE")"
PROMPT_TEXT="$(cat "$PROMPT_FILE")"

echo "▶ Generating docs from $ISSUE_FILE using Aider..."
echo "   Output files:"
echo "   - $DOC_SPEC"
echo "   - $DOC_ARCH"
echo "   - $DOC_DB"
echo ""

aider "$DOC_SPEC" "$DOC_ARCH" "$DOC_DB" \
  --message "$PROMPT_TEXT

--- ISSUE INPUT START ---
$ISSUE_TEXT
--- ISSUE INPUT END ---"

echo ""
echo "✅ Done."
echo "Next:"
echo "  1) Review: git diff"
echo "  2) Commit: git commit -am \"Generate docs from issue\" (or stage/commit normally)"