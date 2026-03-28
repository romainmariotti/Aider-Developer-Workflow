#!/bin/bash

DOCS_DIR="docs"
SPEC_FILE="$DOCS_DIR/spec.md"

# Create docs folder if not exist
mkdir -p "$DOCS_DIR"

echo "Enter the client requirements:"
read -r REQ

PROMPT="Transform the following vague client requirements into a clear software specification.

Rules:
- If spec.md exists, append the new specification.
- If it does not exist, create it.
- Write structured markdown.

Structure:
- Project Overview
- Features
- User Stories
- Constraints

Client requirements:
$REQ
"

echo "Generating spec..."

aider --message "$PROMPT" "$SPEC_FILE"

echo ""
echo "Spec file updated at $SPEC_FILE"