#!/bin/bash

echo "Running tests..."
TEST_OUTPUT=$(pytest tests/ -v 2>&1)
EXIT_CODE=$?

echo "$TEST_OUTPUT"
echo ""

if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ All tests pass!"
else
    echo "❌ Tests failed. Feeding errors to Aider..."
    echo ""
    aider \
        app/main.py app/models.py app/routes.py app/database.py tests/test_tasks.py \
        --message "Fix the following test failures:

$TEST_OUTPUT"
    
    echo ""
    echo "Aider finished. Running tests again..."
    pytest tests/ -v
fi
