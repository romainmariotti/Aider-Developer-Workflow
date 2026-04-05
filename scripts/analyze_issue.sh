#!/usr/bin/env bash
set -euo pipefail

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

# Checks
command -v aider >/dev/null 2>&1 || { echo "❌ aider not found. Install/run aider first."; exit 1; }
[ -f "$PROMPT_FILE" ] || { echo "❌ Missing $PROMPT_FILE"; exit 1; }
[ -f "$ISSUE_FILE" ] || { echo "❌ Missing $ISSUE_FILE (paste issue body into it)"; exit 1; }

ISSUE_TEXT="$(cat "$ISSUE_FILE")"
if [ -z "$(echo "$ISSUE_TEXT" | tr -d '[:space:]')" ]; then
  echo "❌ inputs/issue.md is empty. Paste the GitHub issue body into it."
  exit 1
fi

# Output folder per issue
ISSUE_DIR="docs/issues/ISSUE-${ISSUE_ID}"
mkdir -p "$ISSUE_DIR"

DOC_SPEC="${ISSUE_DIR}/SPEC.md"
DOC_ARCH="${ISSUE_DIR}/ARCHITECTURE.md"
DOC_DB="${ISSUE_DIR}/DB_SCHEMA.md"

touch "$DOC_SPEC" "$DOC_ARCH" "$DOC_DB"

echo "▶ Generating docs for ISSUE-${ISSUE_ID} into ${ISSUE_DIR}"
echo "   - $DOC_SPEC"
echo "   - $DOC_ARCH"
echo "   - $DOC_DB"
echo ""

echo "Pre-check (file sizes before Aider):"
wc -c "$DOC_SPEC" "$DOC_ARCH" "$DOC_DB" || true
echo ""

# Build temporary message file (reliable, avoids quoting issues)
TMP_MSG="$(mktemp)"
cat "$PROMPT_FILE" > "$TMP_MSG"
echo "" >> "$TMP_MSG"
echo "--- ISSUE INPUT START ---" >> "$TMP_MSG"
echo "Issue ID: $ISSUE_ID" >> "$TMP_MSG"
cat "$ISSUE_FILE" >> "$TMP_MSG"
echo "" >> "$TMP_MSG"
echo "--- ISSUE INPUT END ---" >> "$TMP_MSG"

# Build --read args only if files exist (prevents errors)
READ_ARGS=()
[ -f "app/models.py" ] && READ_ARGS+=(--read "app/models.py")
[ -f "app/routes.py" ] && READ_ARGS+=(--read "app/routes.py")
[ -f "app/main.py" ] && READ_ARGS+=(--read "app/main.py")
[ -f "app/database.py" ] && READ_ARGS+=(--read "app/database.py")
[ -f "tests/test_tasks.py" ] && READ_ARGS+=(--read "tests/test_tasks.py")

# Run Aider
# --map-tokens 0 disables repo-map (less exploration/prompts)
# --edit-format whole makes writing reliable
# --no-detect-urls reduces endpoint/url weirdness
aider "$DOC_SPEC" "$DOC_ARCH" "$DOC_DB" \
  --edit-format whole \
  --map-tokens 0 \
  --map-refresh manual \
  --no-detect-urls \
  "${READ_ARGS[@]}" \
  --message-file "$TMP_MSG"

rm -f "$TMP_MSG"

echo ""
echo "Post-check (file sizes after Aider):"
wc -c "$DOC_SPEC" "$DOC_ARCH" "$DOC_DB" || true
echo ""

# Fail fast if empty
if [ ! -s "$DOC_SPEC" ] || [ ! -s "$DOC_ARCH" ] || [ ! -s "$DOC_DB" ]; then
  echo "❌ Aider finished but one or more docs are still empty. Do NOT commit."
  exit 1
fi

echo "✅ Done. Docs generated in ${ISSUE_DIR}"
echo "Next:"
echo "  1) Review: git diff"
echo "  2) Stage:  git add ${ISSUE_DIR}"
echo "  3) Commit: git commit -m \"Generate docs for ISSUE-${ISSUE_ID}\""