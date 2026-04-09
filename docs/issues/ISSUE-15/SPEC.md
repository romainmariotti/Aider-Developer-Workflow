# Feature Specification: Web Frontend for Task Manager API

## Overview

Build a minimal web frontend that allows users to view, create, update, and delete tasks through a browser interface. The frontend will interact with the existing Task Manager API endpoints without requiring any backend changes.

## In Scope

- Display all tasks fetched from the API endpoint for listing tasks
- Create new tasks via a form that calls the API endpoint for task creation
- Toggle task completion status by clicking a checkbox that calls the API endpoint for updating tasks
- Delete tasks via a button that calls the API endpoint for task deletion
- Show user-friendly error messages when API requests fail
- Serve the frontend as static files in a /frontend folder at the project root
- Deploy the frontend alongside the API (same server, potentially different port or path)
- Handle CORS if the frontend is served from a different origin than the API

## Out of Scope

- User authentication or login system
- Multi-user support or user-specific task lists
- Task categories, tags, or advanced filtering
- Mobile-specific UI optimizations
- Dark mode or theme switching
- Editing task title or description inline (only completion toggle and delete)
- Pagination or infinite scroll for large task lists
- Real-time updates or WebSocket connections
- Search functionality in the frontend (API has search but frontend won't expose it initially)

## Acceptance Criteria Checklist

- [ ] When the page loads, all existing tasks are fetched from the API and displayed in a list
- [ ] When a user fills in the new task form with title and description and submits it, the API is called to create the task and the new task appears in the list without page reload
- [ ] When a user clicks a checkbox next to a task, the API is called to toggle the completed status and the UI updates to reflect the change
- [ ] When a user clicks a delete button next to a task, the API is called to delete the task and it is removed from the list without page reload
- [ ] When an API request fails (network error, 404, 422, 500, etc.), a user-friendly error message is displayed to the user
- [ ] The frontend files are located in a /frontend folder at the project root
- [ ] The frontend can be served as static files (via Nginx, Python http.server, or similar)
- [ ] CORS is configured correctly if the frontend and API are on different origins

## Edge Cases

- Empty task list: Display a message like "No tasks yet. Create one to get started."
- API is unreachable: Show error message "Unable to connect to the API. Please try again later."
- Creating a task with empty or whitespace-only title: The API returns 422 with detail "Title must be a non-empty string" - display this to the user
- Deleting a task that was already deleted: The API returns 404 - show error "Task not found or already deleted"
- Updating a task that was already deleted: The API returns 404 - show error "Task not found"
- Network timeout: Show error "Request timed out. Please check your connection."
- Rapid clicks on delete or toggle: Disable buttons during API call to prevent duplicate requests

## API Contract

The frontend will interact with the following existing API endpoints:

- Listing all tasks: Send GET request to /tasks endpoint, expect HTTP 200 response with JSON array of Task objects where each Task has id (integer), title (string), description (string or null), completed (boolean), and created_at (datetime string)
- Creating a task: Send POST request to /tasks endpoint with JSON body containing title (string), description (string or null), and completed (boolean), expect HTTP 201 response with the created Task object
- Updating a task: Send PUT request to /tasks/{id} endpoint with JSON body containing title (string), description (string or null), and completed (boolean), expect HTTP 200 response with the updated Task object
- Deleting a task: Send DELETE request to /tasks/{id} endpoint, expect HTTP 204 response with no content
- Error responses: Expect HTTP 404 with JSON body containing detail "Task not found" when task does not exist, expect HTTP 422 with JSON body containing detail message when validation fails

## Manual Verification Steps

1. Start the API server and verify it is running at the expected URL
2. Open the frontend in a browser (navigate to the served static files)
3. Verify the page loads without errors and displays "No tasks yet" or an empty list
4. Create a task by filling in the form with title "Test Task" and description "Test Description" and clicking submit
5. Verify the new task appears in the list with the correct title, description, and unchecked checkbox
6. Click the checkbox next to the task to mark it as completed
7. Verify the checkbox becomes checked and the task visually indicates completion (strikethrough or similar)
8. Click the checkbox again to mark it as incomplete
9. Verify the checkbox becomes unchecked and the visual indication is removed
10. Create another task with title "Task to Delete"
11. Click the delete button next to "Task to Delete"
12. Verify the task is removed from the list
13. Stop the API server
14. Try to create a task in the frontend
15. Verify an error message appears indicating the API is unreachable
16. Restart the API server
17. Try to create a task with an empty title
18. Verify an error message appears indicating the title is required
19. Refresh the page and verify all tasks are loaded correctly
20. Open browser developer tools and verify no console errors
