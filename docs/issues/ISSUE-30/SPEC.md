# ISSUE-30: Task Counter and Clear All Tasks Feature

## Overview

Add a task counter display and a "Clear all" button to the UI that allows users to delete all tasks at once. This feature is backed by a new backend endpoint that removes all tasks from the database in a single operation.

## In Scope

- Display a task counter in the UI showing the total number of tasks
- Add a "Clear all" button in the tasks section
- Implement confirmation dialog before clearing all tasks
- Create a new backend endpoint for deleting all tasks at once
- Update the task counter dynamically after create, delete, duplicate, and clear operations
- Show appropriate success and error messages
- Add automated tests for the new endpoint

## Out of Scope

- Undo functionality for cleared tasks
- Bulk deletion with filters or conditions
- Authentication or authorization checks
- Soft delete or task archiving
- Confirmation modal with custom styling (browser confirm is sufficient)

## Acceptance Criteria

- [ ] The UI displays a task counter showing the current number of tasks (format example: "Tasks: 5")
- [ ] The counter is positioned near the "Tasks" section heading
- [ ] The counter updates automatically after creating a task
- [ ] The counter updates automatically after deleting a single task
- [ ] The counter updates automatically after duplicating a task
- [ ] The counter updates automatically after clearing all tasks
- [ ] A "Clear all" button is visible in the tasks section
- [ ] Clicking "Clear all" shows a browser confirmation dialog
- [ ] If user cancels the confirmation, no action is taken
- [ ] If user confirms, the frontend calls the backend delete endpoint
- [ ] Backend endpoint exists at path DELETE /tasks (no task ID in path)
- [ ] The endpoint deletes all tasks from the database
- [ ] The endpoint returns HTTP status 204 with no response body on success
- [ ] After successful clear, the UI refreshes the task list
- [ ] After successful clear, the UI shows the empty state message
- [ ] If the API call fails, the UI displays an error message using the existing error container
- [ ] Automated test verifies DELETE /tasks returns 204
- [ ] Automated test verifies DELETE /tasks removes all tasks from database
- [ ] Automated test verifies GET /tasks returns empty array after clear
- [ ] Automated test verifies clearing when no tasks exist returns 204

## Edge Cases

- Clearing when the task list is already empty should succeed with 204 status
- If a task is created while the confirmation dialog is open, it should still be deleted if confirmed
- Network errors during the clear operation should show appropriate error messages
- The counter should show 0 when no tasks exist
- Rapid clicks on "Clear all" should be handled gracefully (button disabled during operation)

## API Contract

The new endpoint follows this contract:

- Method and path: DELETE /tasks (note: no task ID parameter)
- Request body: none required
- Success response: HTTP 204 No Content with empty body
- Error responses: HTTP 500 for server errors (though unlikely with this simple operation)
- The endpoint deletes all Task records from the database using a bulk delete operation
- After deletion, subsequent GET /tasks calls return an empty JSON array

## Manual Verification Steps

Use Swagger UI or manual testing to verify:

- Navigate to the application homepage and observe the task counter displays correctly
- Create several tasks and verify the counter increments each time
- Delete a single task and verify the counter decrements
- Duplicate a task and verify the counter increments
- Click "Clear all" button and cancel the confirmation, verify no tasks are deleted
- Click "Clear all" button and confirm, verify all tasks are removed
- Verify the empty state message appears after clearing
- Verify the counter shows "Tasks: 0" after clearing
- Use Swagger UI to call DELETE /tasks directly and verify 204 response
- Use Swagger UI to call GET /tasks after clearing and verify empty array response
- Call DELETE /tasks when database is already empty and verify 204 response
- Simulate network error and verify error message appears in UI
