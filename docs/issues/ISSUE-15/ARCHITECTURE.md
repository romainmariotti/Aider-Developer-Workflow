# Architecture: Web Frontend for Task Manager API

## Overview

The frontend will be a static web application consisting of HTML, CSS, and JavaScript files served from a /frontend folder at the project root. It will communicate with the existing FastAPI backend via HTTP requests to the documented API endpoints. The frontend will be lightweight, using vanilla JavaScript or a minimal framework like Alpine.js or HTMX to avoid heavy dependencies.

## Where to Implement

Based on the repository structure, the following changes are needed:

- Create new folder: /frontend at the project root (same level as /app, /tests, /docs)
- Create new file: /frontend/index.html for the main HTML structure
- Create new file: /frontend/style.css for styling
- Create new file: /frontend/app.js for JavaScript logic (API calls, DOM manipulation, event handlers)
- Modify existing file: app/main.py to add CORS middleware if the frontend is served from a different origin
- Modify existing file: README.md to add documentation about the frontend setup and usage
- Optionally modify: Dockerfile or create docker-compose.yml to serve the frontend alongside the API

## Route Path and Conflict Avoidance

The frontend will be served as static files, not as API routes. Possible deployment approaches:

- Serve frontend on a different port (e.g., API on port 8000, frontend on port 8080 via a separate web server)
- Serve frontend at the root path / and API at /api prefix (requires modifying app/main.py to mount the router at /api and serve static files at /)
- Serve frontend via Nginx or another reverse proxy that routes / to static files and /tasks to the API

Recommended approach: Serve frontend at / and keep API routes at /tasks, /docs, etc. This requires adding static file serving to app/main.py using FastAPI's StaticFiles middleware. The root route GET / currently returns a welcome message and would need to be removed or moved to avoid conflict with serving index.html at /.

## API Communication Approach

The frontend JavaScript will use the Fetch API to make HTTP requests to the backend:

- On page load: Call fetch with GET method to /tasks endpoint, parse JSON response, and render tasks in the DOM
- On form submit: Call fetch with POST method to /tasks endpoint, include JSON body with title, description, and completed fields, parse response, and add new task to the DOM
- On checkbox click: Get the task ID from the DOM element, fetch current task data, call fetch with PUT method to /tasks/{id} endpoint with toggled completed value, parse response, and update DOM
- On delete button click: Get the task ID from the DOM element, call fetch with DELETE method to /tasks/{id} endpoint, check for 204 status, and remove task from DOM
- Error handling: Wrap all fetch calls in try-catch blocks, check response.ok property, parse error JSON if available, and display user-friendly messages

## Validation and Error Handling Rules

Frontend validation:

- Before submitting the create task form, check if title is empty or contains only whitespace, show inline error message if invalid
- Disable submit button during API call to prevent duplicate submissions
- Disable delete and toggle buttons during API calls to prevent race conditions

Backend error handling (already implemented in app/routes.py):

- HTTP 422 with detail "Title must be a non-empty string" when creating a task with empty or whitespace-only title
- HTTP 404 with detail "Task not found" when getting, updating, or deleting a non-existent task
- HTTP 422 with detail about missing required fields when request body is invalid

Frontend error display:

- Show error messages in a dedicated error container at the top of the page or as inline messages near the relevant UI element
- Clear error messages after successful operations
- For network errors (fetch throws exception), show "Unable to connect to the API"
- For 404 errors, show "Task not found or already deleted"
- For 422 errors, show the detail message from the API response
- For other errors, show "An unexpected error occurred. Please try again."

## CORS Configuration

If the frontend is served from a different origin than the API (different domain, port, or protocol), CORS must be configured in app/main.py:

- Add CORSMiddleware from fastapi.middleware.cors
- Configure allowed origins to include the frontend URL (e.g., http://localhost:8080 for local development)
- Allow credentials if needed (likely not required for this simple use case)
- Allow all methods (GET, POST, PUT, DELETE) and headers (Content-Type)

If the frontend is served from the same origin as the API (e.g., both at tasks.mberchtold.ch), CORS is not needed.

## Testing Strategy

Unit tests (frontend JavaScript):

- Test API call functions in isolation using mock fetch responses
- Test DOM manipulation functions with mock HTML elements
- Test error handling logic with various error scenarios
- Use a testing framework like Jest or Vitest if desired, or keep it simple with manual testing

Integration tests (end-to-end):

- Use Playwright or Selenium to automate browser interactions
- Test the full user flow: load page, create task, toggle completion, delete task
- Test error scenarios: API unreachable, invalid input, task not found
- Verify DOM updates correctly after each operation

Manual testing:

- Follow the manual verification steps in SPEC.md
- Test in multiple browsers (Chrome, Firefox, Safari) to ensure compatibility
- Test with network throttling to simulate slow connections
- Test with browser developer tools to check for console errors and network issues

Backend tests (already exist in tests/test_tasks.py):

- No changes needed to existing backend tests
- Backend API is already fully tested and working correctly
