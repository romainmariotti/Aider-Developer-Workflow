#!/usr/bin/env bash

# Mac Script

# Reads docs/issues/ISSUE-<id>/{SPEC,ARCHITECTURE,DB_SCHEMA}.md and implement the feature using Aider.

set -euo pipefail

# Usage:
#   chmod +x scripts/implement_issue.sh
#   ./scripts/implement_issue.sh 6
# Optional:
#   ./scripts/implement_issue.sh 6 --auto-yes

if [ $# -lt 1 ]; then
  echo "Usage: ./scripts/implement_issue.sh <issue-id> [--auto-yes]"
  exit 1
fi

ISSUE_ID="$1"
AUTO_YES="${2:-}"

command -v aider >/dev/null 2>&1 || { echo "❌ aider not found"; exit 1; }

ISSUE_DIR="docs/issues/ISSUE-${ISSUE_ID}"
SPEC="${ISSUE_DIR}/SPEC.md"
ARCH="${ISSUE_DIR}/ARCHITECTURE.md"
DB="${ISSUE_DIR}/DB_SCHEMA.md"
PROMPT="prompts/docs_to_code.md"

[ -f "$SPEC" ] || { echo "❌ Missing $SPEC"; exit 1; }
[ -f "$ARCH" ] || { echo "❌ Missing $ARCH"; exit 1; }
[ -f "$DB" ]   || { echo "❌ Missing $DB"; exit 1; }
[ -f "$PROMPT" ] || { echo "❌ Missing $PROMPT"; exit 1; }

TMP_MSG="$(mktemp)"
cat "$PROMPT" > "$TMP_MSG"
echo "" >> "$TMP_MSG"
echo "--- DOCS INPUT START ---" >> "$TMP_MSG"
echo "Issue: $ISSUE_ID" >> "$TMP_MSG"
echo "" >> "$TMP_MSG"
echo "[SPEC]" >> "$TMP_MSG"
cat "$SPEC" >> "$TMP_MSG"
echo "" >> "$TMP_MSG"
echo "[ARCHITECTURE]" >> "$TMP_MSG"
cat "$ARCH" >> "$TMP_MSG"
echo "" >> "$TMP_MSG"
echo "[DB_SCHEMA]" >> "$TMP_MSG"
cat "$DB" >> "$TMP_MSG"
echo "" >> "$TMP_MSG"
echo "--- DOCS INPUT END ---" >> "$TMP_MSG"

# Collect editable files
EDIT_FILES=()
[ -d "app" ] && while IFS= read -r f; do EDIT_FILES+=("$f"); done < <(find app -type f)
[ -d "tests" ] && while IFS= read -r f; do EDIT_FILES+=("$f"); done < <(find tests -type f)
[ -d "frontend" ] && while IFS= read -r f; do EDIT_FILES+=("$f"); done < <(find frontend -type f)

if [ "${#EDIT_FILES[@]}" -eq 0 ]; then
  echo "❌ No editable files found (expected app/ and/or tests/ and/or frontend/)."
  exit 1
fi

READ_ARGS=()
[ -f "app/models.py" ] && READ_ARGS+=(--read "app/models.py")
[ -f "app/routes.py" ] && READ_ARGS+=(--read "app/routes.py")
[ -f "app/main.py" ] && READ_ARGS+=(--read "app/main.py")
[ -f "app/database.py" ] && READ_ARGS+=(--read "app/database.py")
[ -f "tests/test_tasks.py" ] && READ_ARGS+=(--read "tests/test_tasks.py")

AUTO_ARGS=()
[ "$AUTO_YES" = "--auto-yes" ] && AUTO_ARGS+=(--yes-always)

echo "▶ Implementing ISSUE-$ISSUE_ID from $ISSUE_DIR"
aider \
  --edit-format diff \
  --map-tokens 0 \
  --map-refresh manual \
  --no-detect-urls \
  ${AUTO_ARGS[@]+"${AUTO_ARGS[@]}"} \
  ${READ_ARGS[@]+"${READ_ARGS[@]}"} \
  --message-file "$TMP_MSG" \
  "${EDIT_FILES[@]}"

rm -f "$TMP_MSG"

echo ""
echo "▶ Running tests..."
source .venv/bin/activate
pytest tests/ -v
echo "✅ Done."