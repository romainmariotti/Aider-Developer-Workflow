#!/usr/bin/env bash
set -Eeuo pipefail

# Strict TDD runner for an ISSUE:
# 1) RED: tests only (expected FAIL)
# 2) GREEN: code only (app/frontend) until tests PASS
# 3) REFACTOR: code only cleanup, then tests must still PASS
#
# Usage:
#   chmod +x scripts/implement_issue.sh
#   ./scripts/implement_issue.sh 18
# Optional:
#   ./scripts/implement_issue.sh 18 --auto-yes

if [ $# -lt 1 ]; then
  echo "Usage: ./scripts/implement_issue.sh <issue-id> [--auto-yes]"
  exit 1
fi

ISSUE_ID="$1"
AUTO_YES="${2:-}"

# -------------------------
# Activate venv early (Git Bash on Windows + mac/linux)
# -------------------------
if [ -f ".venv/bin/activate" ]; then
  source .venv/bin/activate
elif [ -f ".venv/Scripts/activate" ]; then
  source .venv/Scripts/activate
elif [ -f ".venv/Scripts/Activate" ]; then
  source .venv/Scripts/Activate
fi

# -------------------------
# Pick aider executable (prefer venv)
# -------------------------
if [ -x ".venv/bin/aider" ]; then
  AIDER_BIN=".venv/bin/aider"
elif [ -x ".venv/Scripts/aider.exe" ]; then
  AIDER_BIN=".venv/Scripts/aider.exe"
elif [ -x ".venv/Scripts/aider" ]; then
  AIDER_BIN=".venv/Scripts/aider"
else
  AIDER_BIN="aider"
fi

command -v "$AIDER_BIN" >/dev/null 2>&1 || { echo "❌ aider not found"; exit 1; }
command -v pytest >/dev/null 2>&1 || { echo "❌ pytest not found"; exit 1; }

# -------------------------
# Inputs
# -------------------------
ISSUE_DIR="docs/issues/ISSUE-${ISSUE_ID}"
SPEC="${ISSUE_DIR}/SPEC.md"
ARCH="${ISSUE_DIR}/ARCHITECTURE.md"
DB="${ISSUE_DIR}/DB_SCHEMA.md"
PROMPT="prompts/docs_to_code.md"

[ -f "$SPEC" ] || { echo "❌ Missing $SPEC"; exit 1; }
[ -f "$ARCH" ] || { echo "❌ Missing $ARCH"; exit 1; }
[ -f "$DB" ]   || { echo "❌ Missing $DB"; exit 1; }
[ -f "$PROMPT" ] || { echo "❌ Missing $PROMPT"; exit 1; }

# -------------------------
# Build base docs message
# -------------------------
TMP_MSG="$(mktemp)"
trap 'rm -f "$TMP_MSG" 2>/dev/null || true' EXIT

cat "$PROMPT" > "$TMP_MSG"
{
  echo ""
  echo "--- DOCS INPUT START ---"
  echo "Issue: $ISSUE_ID"
  echo ""
  echo "[SPEC]"
  cat "$SPEC"
  echo ""
  echo "[ARCHITECTURE]"
  cat "$ARCH"
  echo ""
  echo "[DB_SCHEMA]"
  cat "$DB"
  echo ""
  echo "--- DOCS INPUT END ---"
} >> "$TMP_MSG"

# -------------------------
# Collect files
# -------------------------
TEST_FILES=()
CODE_FILES=()

[ -d "tests" ] && while IFS= read -r f; do TEST_FILES+=("$f"); done < <(find tests -type f)
[ -d "app" ] && while IFS= read -r f; do CODE_FILES+=("$f"); done < <(find app -type f)
[ -d "frontend" ] && while IFS= read -r f; do CODE_FILES+=("$f"); done < <(find frontend -type f)

if [ "${#TEST_FILES[@]}" -eq 0 ]; then
  echo "❌ No test files found in tests/"
  exit 1
fi
if [ "${#CODE_FILES[@]}" -eq 0 ]; then
  echo "❌ No code files found (expected app/ and/or frontend/)"
  exit 1
fi

# Read-only context to reduce prompts
READ_ARGS=()
[ -f "app/models.py" ] && READ_ARGS+=(--read "app/models.py")
[ -f "app/routes.py" ] && READ_ARGS+=(--read "app/routes.py")
[ -f "app/main.py" ] && READ_ARGS+=(--read "app/main.py")
[ -f "app/database.py" ] && READ_ARGS+=(--read "app/database.py")
[ -f "tests/test_tasks.py" ] && READ_ARGS+=(--read "tests/test_tasks.py")
[ -f "frontend/index.html" ] && READ_ARGS+=(--read "frontend/index.html")
[ -f "frontend/app.js" ] && READ_ARGS+=(--read "frontend/app.js")
[ -f "frontend/style.css" ] && READ_ARGS+=(--read "frontend/style.css")

AUTO_ARGS=()
[ "$AUTO_YES" = "--auto-yes" ] && AUTO_ARGS+=(--yes-always)

# -------------------------
# Helper: run pytest and capture exit code + output
# -------------------------
PYTEST_OUTPUT=""
PYTEST_EXIT=0
run_pytest() {
  set +e
  PYTEST_OUTPUT="$(pytest tests/ -v 2>&1)"
  PYTEST_EXIT=$?
  set -e
}

echo "▶ Implementing ISSUE-$ISSUE_ID from $ISSUE_DIR"
echo ""

# =========================================================
# RED PHASE — tests only
# =========================================================
echo "🔴 RED phase: add/update tests ONLY (expected FAIL)..."

RED_MSG="$(mktemp)"
cat "$TMP_MSG" > "$RED_MSG"
{
  echo ""
  echo "RED PHASE (STRICT):"
  echo "- Modify ONLY files under tests/."
  echo "- Do NOT modify app/ or frontend/."
  echo "- Add tests for the SPEC acceptance criteria."
  echo "- Tests should fail initially because the feature is not implemented."
} >> "$RED_MSG"

"$AIDER_BIN" \
  --edit-format diff \
  --map-tokens 0 \
  --map-refresh manual \
  --no-detect-urls \
  --no-suggest-shell-commands \
  ${AUTO_ARGS[@]+"${AUTO_ARGS[@]}"} \
  ${READ_ARGS[@]+"${READ_ARGS[@]}"} \
  --message-file "$RED_MSG" \
  "${TEST_FILES[@]}"

rm -f "$RED_MSG"

echo ""
echo "Running tests (RED expects FAIL)..."
run_pytest
echo "$PYTEST_OUTPUT"
echo ""

if [ "$PYTEST_EXIT" -eq 0 ]; then
  echo "⚠️ Warning: Tests passed in RED phase (feature may already exist, or tests are not asserting the new behavior)."
  echo "   Continuing to GREEN anyway."
fi

# =========================================================
# GREEN PHASE — code only until tests pass
# =========================================================
echo "🟢 GREEN phase: implement CODE ONLY until tests pass..."

MAX_TRIES=3
TRY=1

while [ $TRY -le $MAX_TRIES ]; do
  echo ""
  echo "GREEN attempt $TRY/$MAX_TRIES"

  run_pytest
  echo "$PYTEST_OUTPUT"
  echo ""

  if [ "$PYTEST_EXIT" -eq 0 ]; then
    echo "✅ Tests pass after GREEN."
    break
  fi

  echo "❌ Tests failing -> asking Aider to implement code (tests are read-only in this phase)."

  GREEN_MSG="$(mktemp)"
  cat "$TMP_MSG" > "$GREEN_MSG"
  {
    echo ""
    echo "GREEN PHASE (STRICT):"
    echo "- You are NOT allowed to modify tests in this phase."
    echo "- Modify ONLY app/ and/or frontend/ code to make the existing tests pass."
    echo "- Keep changes minimal and follow ARCHITECTURE.md."
    echo ""
    echo "PYTEST FAILURES:"
    echo "$PYTEST_OUTPUT"
  } >> "$GREEN_MSG"

  "$AIDER_BIN" \
    --edit-format diff \
    --map-tokens 0 \
    --map-refresh manual \
    --no-detect-urls \
    --no-suggest-shell-commands \
    ${AUTO_ARGS[@]+"${AUTO_ARGS[@]}"} \
    ${READ_ARGS[@]+"${READ_ARGS[@]}"} \
    --message-file "$GREEN_MSG" \
    "${CODE_FILES[@]}"

  rm -f "$GREEN_MSG"
  TRY=$((TRY + 1))
done

run_pytest
if [ "$PYTEST_EXIT" -ne 0 ]; then
  echo "❌ Still failing after GREEN attempts."
  exit 1
fi

# =========================================================
# REFACTOR PHASE — code only cleanup, tests must stay green
# =========================================================
echo ""
echo "🔵 REFACTOR phase: refactor CODE ONLY (no behavior change), then tests must still pass..."

REFACTOR_MSG="$(mktemp)"
cat "$TMP_MSG" > "$REFACTOR_MSG"
{
  echo ""
  echo "REFACTOR PHASE (STRICT):"
  echo "- Refactor ONLY app/ and/or frontend/ code for readability/maintainability."
  echo "- Do NOT change behavior."
  echo "- Do NOT modify tests."
  echo "- Keep changes minimal."
} >> "$REFACTOR_MSG"

"$AIDER_BIN" \
  --edit-format diff \
  --map-tokens 0 \
  --map-refresh manual \
  --no-detect-urls \
  --no-suggest-shell-commands \
  ${AUTO_ARGS[@]+"${AUTO_ARGS[@]}"} \
  ${READ_ARGS[@]+"${READ_ARGS[@]}"} \
  --message-file "$REFACTOR_MSG" \
  "${CODE_FILES[@]}"

rm -f "$REFACTOR_MSG"

echo ""
echo "Running tests after refactor..."
run_pytest
echo "$PYTEST_OUTPUT"
echo ""

if [ "$PYTEST_EXIT" -ne 0 ]; then
  echo "❌ Refactor broke tests -> fixing code (still no test edits)."

  FIX_MSG="$(mktemp)"
  cat "$TMP_MSG" > "$FIX_MSG"
  {
    echo ""
    echo "FIX AFTER REFACTOR (STRICT):"
    echo "- Tests are failing after refactor."
    echo "- Modify ONLY app/ and/or frontend/ to restore passing tests."
    echo "- Do NOT modify tests."
    echo ""
    echo "PYTEST FAILURES:"
    echo "$PYTEST_OUTPUT"
  } >> "$FIX_MSG"

  "$AIDER_BIN" \
    --edit-format diff \
    --map-tokens 0 \
    --map-refresh manual \
    --no-detect-urls \
    --no-suggest-shell-commands \
    ${AUTO_ARGS[@]+"${AUTO_ARGS[@]}"} \
    ${READ_ARGS[@]+"${READ_ARGS[@]}"} \
    --message-file "$FIX_MSG" \
    "${CODE_FILES[@]}"

  rm -f "$FIX_MSG"

  run_pytest
  echo "$PYTEST_OUTPUT"
  echo ""
  [ "$PYTEST_EXIT" -eq 0 ] || { echo "❌ Still failing after fix."; exit 1; }
fi

echo "✅ Done: GREEN + REFACTOR completed with passing tests."