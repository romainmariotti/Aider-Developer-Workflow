# ARCHITECTURE: Task Duplication Feature

## Overview

This feature adds a duplication capability to the task management system. It introduces a new API endpoint that creates a copy of an existing task with modified fields, and extends the frontend UI with a duplication button.

## Implementation Locations

The implementation requires changes to the following repository files:

- Backend route handler: app/routes.py (add new endpoint function)
- Frontend JavaScript: frontend/app.js (add duplicate button handler)
- Frontend HTML: frontend/index.html (add duplicate button to task template)
- Frontend CSS: frontend/style.css (add styling for duplicate button)
- Test file: tests/test_tasks.py (add new test functions)

## Route Implementation

The new route should be added to app/routes.py in the existing router:

- Route decorator: @router.post with path "/{task_id}/duplicate"
- Response model: Task
- Status code: 201 for success
- Function signature: duplicate_task(task_id: int, session: Session = Depends(get_session))
- The route should be placed logically near other single-task operations like get_task or update_task

## Database Query Approach

The implementation should follow this sequence:

1. Query the database to retrieve the original task using session.get(Task, task_id)
2. Check if the task exists, raise HTTPException with status 404 if not found
3. Create a new Task instance with fields copied from the original
4. Modify the title field by appending " (copy)" to the original title
5. Set completed to false regardless of original value
6. Set created_at to current UTC timestamp (using the same pattern as Task model default)
7. Leave description as-is from the original (including null if applicable)
8. Add the new task to the session using session.add
9. Commit the transaction using session.commit
10. Refresh the new task to get the generated id using session.refresh
11. Return the new task object

## Validation and Error Handling

Error handling rules:

- If task_id does not exist in database: Return HTTP 404 with detail "Task not found"
- If task_id is invalid format (non-integer): FastAPI handles automatically with HTTP 422
- No request body validation needed since endpoint takes no body
- Use the same HTTPException pattern as existing endpoints for consistency

Success handling:

- Return HTTP 201 (created) status code
- Return the complete new Task object as JSON
- Ensure all Task fields are populated including the new id

## Frontend Integration

The frontend changes should follow this approach:

In frontend/index.html:

- Add a duplicate button element inside the task-actions div
- Place it near the existing delete button
- Give it appropriate id attribute like "duplicate-{task.id}"
- Add appropriate class for styling

In frontend/app.js:

- Create a new function handleDuplicateTask(taskId) similar to handleDeleteTask
- Make a POST request to /tasks/{taskId}/duplicate endpoint
- On success: reload the task list using loadTasks()
- On error: display error message using showError()
- Attach event listeners to duplicate buttons in renderTasks function
- Disable the duplicate button during API call to prevent double-clicks

In frontend/style.css:

- Add styling for the duplicate button class
- Use a distinct color from delete button (suggestion: blue/green tone)
- Ensure hover and disabled states are styled appropriately

## Testing Strategy

Test coverage should include:

Unit tests in tests/test_tasks.py:

- Test successful duplication returns 201 and creates new task
- Test new task has different id from original
- Test new task title has " (copy)" suffix appended
- Test new task has same description as original
- Test new task has completed set to false even if original was true
- Test new task has valid created_at timestamp
- Test duplicating non-existent task returns 404
- Test duplicating task with null description works correctly
- Test that original task is not modified after duplication
- Test that database contains both original and duplicate after operation

Integration considerations:

- Verify existing tests still pass after adding new endpoint
- Verify GET /tasks returns both original and duplicate
- Verify the new endpoint appears in OpenAPI schema

Manual testing:

- Test via Swagger UI to verify endpoint behavior
- Test via frontend UI to verify button functionality
- Test error scenarios like network failures
- Test rapid clicking of duplicate button
