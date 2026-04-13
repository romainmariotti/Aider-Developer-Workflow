# SPEC: Task Duplication Feature

## Overview

This feature adds the ability to duplicate an existing task, creating a new task with the same title (with a suffix) and description. The duplicated task starts as incomplete with a new timestamp.

## In Scope

- New backend endpoint for duplicating a task by ID
- Frontend UI button to trigger duplication
- Automated tests covering success and error cases
- Swagger/OpenAPI documentation for the new endpoint
- Error handling for non-existent tasks

## Out of Scope

- Bulk duplication of multiple tasks at once
- Duplication of any metadata beyond current Task model fields
- Authentication or authorization checks
- Schema changes to the Task model
- Customization of the "(copy)" suffix

## Acceptance Criteria

- [ ] Backend endpoint POST /tasks/{task_id}/duplicate exists and is functional
- [ ] Duplicating an existing task returns HTTP 201 with the new Task object
- [ ] Duplicating a non-existent task returns HTTP 404 with detail "Task not found"
- [ ] The original task remains unchanged after duplication
- [ ] The duplicated task has title equal to original title plus " (copy)" suffix
- [ ] The duplicated task has description copied from original (can be null)
- [ ] The duplicated task has completed set to false
- [ ] The duplicated task has created_at set to current timestamp
- [ ] The duplicated task has a new unique id different from the original
- [ ] Frontend displays a "Duplicate" button for each task in the list
- [ ] Clicking "Duplicate" calls the backend endpoint and refreshes the task list
- [ ] Frontend shows error message if duplication fails
- [ ] New endpoint appears in Swagger UI documentation
- [ ] All existing endpoints continue to work without changes
- [ ] Tests are written in TDD style (Red-Green)

## Edge Cases

- Duplicating a task with null description: The copy should also have null description
- Duplicating a completed task: The copy should have completed set to false
- Duplicating a task with a very long title: The suffix should still be appended
- Duplicating a task that was already a copy: Title becomes "Original (copy) (copy)"
- Network errors during duplication: Frontend should display error message
- Rapid duplicate clicks: Each click should create a separate copy

## API Contract

The new endpoint follows this contract:

- Method and path: POST to /tasks/{task_id}/duplicate where task_id is an integer
- Request body: None required
- Success response: HTTP 201 with JSON body containing the new Task object with fields id, title, description, completed, and created_at
- Error response for missing task: HTTP 404 with JSON body containing detail field with message "Task not found"
- The title field in the response will be the original title with " (copy)" appended
- The completed field in the response will always be false
- The created_at field in the response will be a new timestamp

## Manual Verification Steps

Using Swagger UI or similar API testing tool:

1. Create a test task using POST /tasks with title "Test Task" and description "Test Description"
2. Note the id of the created task from the response
3. Call POST /tasks/{id}/duplicate using the noted id
4. Verify the response is HTTP 201
5. Verify the response body contains a new task with title "Test Task (copy)"
6. Verify the new task has completed set to false
7. Verify the new task has a different id from the original
8. Call GET /tasks to list all tasks
9. Verify both the original and the duplicated task appear in the list
10. Call POST /tasks/99999/duplicate with a non-existent id
11. Verify the response is HTTP 404 with appropriate error message

Using the web UI:

1. Open the application in a browser
2. Create a new task with any title and description
3. Locate the "Duplicate" button next to the task
4. Click the "Duplicate" button
5. Verify a new task appears in the list with "(copy)" suffix
6. Verify the new task is not marked as completed
7. Verify the original task is still present and unchanged
