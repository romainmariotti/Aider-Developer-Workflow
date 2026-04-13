#!/bin/bash

# Run ruff linting on app directory
echo "Running Ruff lint check..."
ruff check app/

# Check if Ruff found issues
if [ $? -ne 0 ]; then
    echo "Lint errors detected. Attempting auto-fix..."

    # Try to automatically fix lint issues
    ruff check app/ --fix

    # Run lint again to verify if all issues are fixed
    echo "Re-running lint..."
    ruff check app/

    # If there are still errors after auto-fix
    if [ $? -ne 0 ]; then
        echo "Ruff could not fix everything. Sending to Aider..."

        # Save lint output to a temporary file
        ruff check app/ > /tmp/lint-errors.txt 2>&1

        # Send remaining issues to Aider for fixes
        aider app/ --message-file /tmp/lint-errors.txt \
        --message "Fix the following Ruff lint issues without changing functionality."
    else
        # All issues were fixed automatically by Ruff
        echo "All lint issues fixed automatically"
    fi
else
    # No lint issues found
    echo "Lint passed !"
fi