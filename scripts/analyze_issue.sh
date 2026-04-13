#!/usr/bin/env bash
set -euo pipefail

# Docs-only: Convert a GitHub issue (inputs/issue.md) into docs/issues/ISSUE-<id>/{SPEC,ARCHITECTURE,DB_SCHEMA}.md
# No interaction. No code implementation.
#
# Usage:
#   chmod +x scripts/analyze_issue.sh
#   ./scripts/analyze_issue.sh 6

if [ $# -ne 1 ]; then
  echo "Usage: ./scripts/analyze_issue.sh <issue-id>"
  exit 1
fi

ISSUE_ID="$1"
ISSUE_FILE="inputs/issue.md"
PROMPT_FILE="prompts/issue_to_docs.md"

# --- Checks ---
command -v aider >/dev/null 2>&1 || { echo "❌ aider not found. Install/run aider first."; exit 1; }
[ -f "$PROMPT_FILE" ] || { echo "❌ Missing $PROMPT_FILE"; exit 1; }
[ -f "$ISSUE_FILE" ] || { echo "❌ Missing $ISSUE_FILE (paste issue body into it)"; exit 1; }

ISSUE_TEXT="$(cat "$ISSUE_FILE")"
if [ -z "$(echo "$ISSUE_TEXT" | tr -d '[:space:]')" ]; then
  echo "❌ inputs/issue.md is empty. Paste the GitHub issue body into it."
  exit 1
fi

# --- Output folder per issue ---
ISSUE_DIR="docs/issues/ISSUE-${ISSUE_ID}"
mkdir -p "$ISSUE_DIR"

DOC_SPEC="${ISSUE_DIR}/SPEC.md"
DOC_ARCH="${ISSUE_DIR}/ARCHITECTURE.md"
DOC_DB="${ISSUE_DIR}/DB_SCHEMA.md"

# Ensure output files exist
: > "$DOC_SPEC"
: > "$DOC_ARCH"
: > "$DOC_DB"

echo "▶ Generating docs for ISSUE-${ISSUE_ID} into ${ISSUE_DIR}"
echo "   - $DOC_SPEC"
echo "   - $DOC_ARCH"
echo "   - $DOC_DB"
echo ""

echo "Pre-check (file sizes before Aider):"
wc -c "$DOC_SPEC" "$DOC_ARCH" "$DOC_DB" || true
echo ""

# --- Build a temp message file (avoids quoting/parsing issues) ---
TMP_MSG="$(mktemp)"
{
  cat "$PROMPT_FILE"
  echo ""
  echo "--- ISSUE INPUT START ---"
  echo "Issue ID: $ISSUE_ID"
  echo ""
  cat "$ISSUE_FILE"
  echo ""
  echo "--- ISSUE INPUT END ---"
} > "$TMP_MSG"

# --- Minimal read-only context (prevents inventing fields/paths) ---
READ_ARGS=()
for f in app/models.py app/routes.py app/main.py app/database.py tests/test_tasks.py frontend/app.js frontend/index.html frontend/style.css; do
  [ -f "$f" ] && READ_ARGS+=(--read "$f")
done

# --- Run Aider in docs-only mode ---
# Notes:
# - We pass ONLY the 3 docs files as editable arguments.
# - We DO NOT pass app/ or tests/ as editable.
# - --no-suggest-shell-commands prevents "Run shell command?" prompts.
# - --no-detect-urls + prompt formatting rules reduce "Create new file?" prompts.
aider "$DOC_SPEC" "$DOC_ARCH" "$DOC_DB" \
  --edit-format whole \
  --map-tokens 0 \
  --map-refresh manual \
  --no-detect-urls \
  --no-suggest-shell-commands \
  "${READ_ARGS[@]}" \
  --message-file "$TMP_MSG"

rm -f "$TMP_MSG"

echo ""
echo "Post-check (file sizes after Aider):"
wc -c "$DOC_SPEC" "$DOC_ARCH" "$DOC_DB" || true
echo ""

# Fail fast if any doc is empty
if [ ! -s "$DOC_SPEC" ] || [ ! -s "$DOC_ARCH" ] || [ ! -s "$DOC_DB" ]; then
  echo "❌ Aider finished but one or more docs are still empty. Do NOT commit."
  exit 1
fi

echo "✅ Done. Docs generated in ${ISSUE_DIR}"
echo "Next:"
echo "  1) Review: git diff"
echo "  2) Stage:  git add ${ISSUE_DIR}"
echo "  3) Commit: git commit -m \"Generate docs for ISSUE-${ISSUE_ID}\""