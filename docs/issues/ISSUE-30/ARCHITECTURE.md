# ISSUE-30: Architecture Design

## Overview

This feature adds a task counter display and bulk delete functionality to clear all tasks. The implementation requires changes to the backend API (new endpoint), frontend JavaScript (counter logic and clear button handler), and frontend HTML/CSS (counter display and button).

## Implementation Locations

Backend changes:

- File: app/routes.py
- Add a new route handler function for DELETE /tasks endpoint
- The function should delete all Task records from the database
- Return HTTP 204 status with no content

Frontend changes:

- File: frontend/index.html
- Add a task counter element near the tasks section heading
- Add a "Clear all" button in the tasks section
- File: frontend/app.js
- Add a function to update the task counter based on current task count
- Add an event handler for the "Clear all" button
- Implement confirmation dialog logic
- Implement API call to DELETE /tasks endpoint
- Update counter after all task operations (create, delete, duplicate, clear)
- File: frontend/style.css
- Add styles for the task counter display
- Add styles for the "Clear all" button

Test changes:

- File: tests/test_tasks.py
- Add test function for DELETE /tasks returning 204
- Add test function verifying all tasks are deleted from database
- Add test function verifying GET /tasks returns empty array after clear
- Add test function for clearing when database is already empty

## Route Implementation

The new endpoint path is DELETE /tasks (note: no task ID parameter, unlike DELETE /tasks/{task_id}).

Route handler approach:

- Use the APIRouter instance already defined in app/routes.py
- Add a new function decorated with @router.delete with path "" (empty string, since router already has prefix "/tasks")
- Function signature: def delete_all_tasks(session: Session = Depends(get_session))
- Return status code 204 explicitly
- No response model needed (204 means no content)

## Database Query Approach

The delete operation should remove all Task records efficiently:

- Use SQLModel session.exec with a delete statement
- Construct a delete statement for the Task model
- Execute the statement to delete all rows
- Commit the transaction
- No need to fetch tasks first, use bulk delete directly
- Alternative simpler approach: iterate through all tasks and delete each, but bulk delete is more efficient

## Validation and Error Handling

This endpoint has minimal validation needs:

- No request body to validate
- No path parameters to validate
- Always return 204 even if no tasks exist (idempotent operation)
- Database errors should propagate as 500 errors (FastAPI default handling)
- No 404 error needed since we're not looking up a specific resource

## Frontend Logic

Task counter implementation:

- Store a reference to the counter DOM element
- Create an updateTaskCounter function that accepts a count number
- Call updateTaskCounter after loadTasks completes with the task array length
- Call updateTaskCounter after successful create (increment by 1)
- Call updateTaskCounter after successful delete (decrement by 1)
- Call updateTaskCounter after successful duplicate (increment by 1)
- Call updateTaskCounter after successful clear (set to 0)

Clear all button implementation:

- Add click event listener to the "Clear all" button
- Handler function: handleClearAllTasks
- Show browser confirm dialog with message like "Are you sure you want to delete all tasks?"
- If user cancels, return early
- If user confirms, disable the button and show loading state
- Make DELETE request to /tasks endpoint
- On success (204), call loadTasks to refresh the UI
- On error, show error message using existing showError function
- Re-enable button in finally block

## Testing Strategy

Test coverage should include:

- Happy path: DELETE /tasks successfully clears all tasks and returns 204
- Verify database state: after calling DELETE /tasks, query database to confirm zero tasks remain
- Integration check: call GET /tasks after DELETE /tasks and verify empty array response
- Edge case: calling DELETE /tasks when database is already empty returns 204
- Idempotency: calling DELETE /tasks multiple times in succession all return 204
- Use existing test fixtures (session_fixture and client_fixture)
- Follow existing test patterns in tests/test_tasks.py for consistency

## Error Scenarios

Frontend error handling:

- Network failure during DELETE request: show error message, keep existing tasks visible
- Non-204 response from server: show error message, keep existing tasks visible
- Use existing errorContainer element and showError function
- Button should be re-enabled after error so user can retry

Backend error handling:

- Database connection errors: let FastAPI handle with default 500 response
- No special error handling needed for this simple operation
