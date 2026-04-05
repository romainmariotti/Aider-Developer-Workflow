# SPEC: Add Task Search by Title Endpoint

## Overview

Add a new API endpoint that allows searching tasks by title using partial, case-insensitive matching. This enables API consumers to filter tasks without fetching the entire task list.

## In Scope

- New GET endpoint for searching tasks by title with partial match
- Case-insensitive title search
- Return matching tasks as JSON array
- Validation for missing or empty title parameter
- HTTP 422 error for invalid input
- Integration with existing Task model and database
- Swagger/OpenAPI documentation for the new endpoint

## Out of Scope

- Authentication or authorization changes
- Pagination of search results
- Advanced filtering (by description, completed status, date ranges, etc.)
- Full-text search or fuzzy matching
- UI or frontend implementation
- Changes to existing endpoints or models
- Performance optimization (indexing, caching)

## Acceptance Criteria Checklist

- [ ] New endpoint exists at GET /tasks/search with query parameter title
- [ ] When title query parameter is provided, endpoint returns HTTP 200 with JSON array of matching Task objects
- [ ] Title matching is case-insensitive and supports partial matches (substring search)
- [ ] When no tasks match the search query, endpoint returns HTTP 200 with empty array
- [ ] When title parameter is missing, endpoint returns HTTP 422 with validation error detail
- [ ] When title parameter is empty string, endpoint returns HTTP 422 with validation error detail
- [ ] When title parameter contains only whitespace, endpoint returns HTTP 422 with validation error detail
- [ ] Existing endpoints continue to work without changes (GET /tasks, GET /tasks/{task_id}, POST /tasks, PUT /tasks/{task_id}, DELETE /tasks/{task_id})
- [ ] New endpoint appears in Swagger UI documentation at /docs
- [ ] Response format matches existing Task model schema (id, title, description, completed, created_at)
- [ ] All existing tests continue to pass
- [ ] New tests cover success cases, empty results, and validation errors

## Edge Cases

- Empty search results: When title query matches no tasks, return HTTP 200 with empty array (not 404)
- Whitespace-only title: Treat as invalid input and return HTTP 422
- Special characters in title: Should work normally (no escaping issues)
- Very long title query string: Should work within reasonable limits (no specific length validation required)
- Case sensitivity: Search for "Task" should match "task", "TASK", "TaSk", etc.
- Partial matches: Search for "buy" should match "buy milk", "buying groceries", "I will buy"
- Multiple word search: Search for "buy milk" should match tasks containing that substring

## API Contract

### Endpoint

- Method and path: GET /tasks/search
- Query parameters: title (string, required, must be non-empty and non-whitespace)
- Tags: tasks (same as other task endpoints)

### Success Response

- Status code: HTTP 200 OK
- Response body: JSON array of Task objects, each containing fields id (integer), title (string), description (string or null), completed (boolean), created_at (datetime string in ISO format)
- Example: Search with title=buy returns HTTP 200 with array containing Task objects where title contains "buy"

### Validation Error Response

- Status code: HTTP 422 Unprocessable Entity
- Response body: JSON object with detail field describing the validation error
- Triggered when: title parameter is missing, empty string, or contains only whitespace
- Example: GET /tasks/search without title parameter returns HTTP 422 with detail explaining title is required

### Empty Results Response

- Status code: HTTP 200 OK
- Response body: Empty JSON array
- Triggered when: Valid title provided but no tasks match the search criteria
- Example: Search with title=nonexistent returns HTTP 200 with empty array

## Manual Verification Steps

1. Start the FastAPI application and ensure database is initialized with test data
2. Open Swagger UI at /docs and verify new endpoint GET /tasks/search appears under tasks tag
3. Create sample tasks with titles: "Buy groceries", "buy milk", "BUYING supplies", "Sell old items"
4. Test successful search: Send GET /tasks/search?title=buy and verify response is HTTP 200 with array containing the three tasks with "buy" in title (case-insensitive)
5. Test empty results: Send GET /tasks/search?title=xyz123notfound and verify response is HTTP 200 with empty array
6. Test missing parameter: Send GET /tasks/search without title parameter and verify response is HTTP 422 with validation error
7. Test empty string: Send GET /tasks/search?title= (empty value) and verify response is HTTP 422 with validation error
8. Test whitespace only: Send GET /tasks/search?title=%20%20 (URL-encoded spaces) and verify response is HTTP 422 with validation error
9. Test partial match: Send GET /tasks/search?title=gro and verify it matches "Buy groceries"
10. Test existing endpoints: Verify GET /tasks, GET /tasks/1, POST /tasks, PUT /tasks/1, DELETE /tasks/1 still work correctly
11. Run all existing tests and verify they pass
12. Run new integration tests for the search endpoint
