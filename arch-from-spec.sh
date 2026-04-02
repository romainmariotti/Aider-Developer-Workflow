#!/bin/bash

SPEC_FILE="docs/spec.md"
ARCH_FILE="docs/architecture.md"

# Ensure docs folder exists
mkdir -p docs

# Check if spec exists
if [ ! -f "$SPEC_FILE" ]; then
    echo "Spec file not found : $SPEC_FILE"
    exit 1
fi

# Create architecture file if missing
if [ ! -f "$ARCH_FILE" ]; then
    echo "Creating $ARCH_FILE..."
    touch "$ARCH_FILE"
fi

echo "Generating architecture from specification..."

aider "$SPEC_FILE" "$ARCH_FILE" --message "
Based on the user stories and constraints in this specification :

1. Propose a clear system architecture
2. Define components (API, services, database, etc.)
3. Describe responsibilities of each component
4. Suggest a clean and scalable project structure
5. Suggest appropriate technologies
6. Explain data flow between components
7. Include a Mermaid diagram

IMPORTANT :
- Replace the entire content of the file
- Write clean structured Markdown
"

echo "Architecture generated in $ARCH_FILE"