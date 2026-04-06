# ARCHITECTURE: Task Search by Title Endpoint

## Overview

Implement a new search endpoint in the existing FastAPI task management application. The endpoint will query the SQLite database for tasks matching a title substring (case-insensitive) and return results using the existing Task model. Implementation follows established patterns in the codebase: route handler in app/routes.py, database session dependency from app/database.py, and response model using app/models.py Task class.

## Where to Implement

### Primary Implementation File

- File path: app/routes.py
- Reason: All task-related endpoints are defined in this file using the APIRouter with prefix /tasks
- Location in file: Add new route handler function after existing get_tasks function and before get_task function (to maintain logical grouping of GET endpoints)
- Function name: search_tasks (follows naming convention of other route handlers)

### Model Files (No Changes Required)

- File path: app/models.py
- Changes needed: None (will reuse existing Task model for response)
- Reason: Task model already contains all required fields (id, title, description, completed, created_at)

### Database Files (No Changes Required)

- File path: app/database.py
- Changes needed: None (will use existing get_session dependency)
- Reason: Existing session management and engine configuration are sufficient

### Main Application File (No Changes Required)

- File path: app/main.py
- Changes needed: None (router is already included)
- Reason: New route will automatically be included via existing router inclusion

### Test File (New Tests Required)

- File path: tests/test_tasks.py
- Changes needed: Add new test functions for search endpoint
- Test functions to add: test_search_tasks_success, test_search_tasks_empty_results, test_search_tasks_missing_title, test_search_tasks_empty_title, test_search_tasks_whitespace_title, test_search_tasks_case_insensitive

## Route Path and Conflict Avoidance

### Chosen Path

- Route path: GET /tasks/search
- Full URL pattern: /tasks/search (with router prefix)
- Query parameter: title (required string)

### Why This Path Avoids Conflicts

- Existing routes use /tasks (list all), /tasks/{task_id} (get by ID), so /tasks/search is a distinct literal path segment
- FastAPI route matching prioritizes literal paths over path parameters, so /tasks/search will match before /tasks/{task_id} attempts to parse "search" as an integer task_id
- The word "search" cannot be confused with a valid task ID (integer) so no ambiguity exists
- Query parameter approach (title=value) keeps the path clean and follows REST conventions for filtering
- Alternative rejected: /search/tasks would require a new router or prefix change, breaking consistency with existing /tasks prefix

## Database Query Approach

### Query Strategy

- Use SQLModel select statement with where clause for filtering
- Apply case-insensitive LIKE operator for partial matching
- Convert both database title field and search query to lowercase for comparison
- Return all matching rows as a list

### Query Construction Steps

1. Import col function from sqlalchemy for column operations
2. Create select statement for Task model
3. Add where clause using col(Task.title).ilike() method with search pattern
4. Format search pattern as percent-query-percent to match substring anywhere in title
5. Execute query using session.exec() method
6. Convert result to list using .all() method
7. Return list directly (FastAPI serializes to JSON array)

### Performance Considerations

- Query performs table scan with string comparison (no index on title column currently)
- Acceptable for small to medium datasets (current scope)
- Future optimization: Add database index on title column if performance becomes an issue
- No pagination implemented in this iteration (out of scope)

## Validation and Error Handling Rules

### Input Validation

- Title parameter is required: Use FastAPI Query parameter with ellipsis (...) to make it required
- Empty string validation: Check if title is empty string after receiving and return HTTP 422
- Whitespace-only validation: Check if title.strip() is empty and return HTTP 422
- Validation error response: Use HTTPException with status_code=422 and descriptive detail message

### Validation Logic Flow

1. FastAPI automatically validates title parameter exists (returns 422 if missing)
2. In route handler, check if title is empty string or whitespace-only
3. If invalid, raise HTTPException with status 422 and detail message explaining title must be non-empty
4. If valid, proceed with database query

### Error Response Format

- Status code: 422 Unprocessable Entity
- Body structure: JSON object with detail field (FastAPI default format)
- Detail message: Clear explanation like "Title parameter must be a non-empty string"

### Success Cases

- Valid title with matches: Return HTTP 200 with array of Task objects
- Valid title with no matches: Return HTTP 200 with empty array (not an error condition)
- No exception handling needed for database errors (let FastAPI default handlers manage)

## Testing Strategy

### Unit Testing Approach

- Test file location: tests/test_tasks.py
- Use existing test fixtures: session_fixture for database, client_fixture for API client
- Follow existing test patterns: create test data in session, make request via client, assert response

### Integration Tests to Add

1. test_search_tasks_success: Create tasks with various titles, search with query that matches some, verify HTTP 200 and correct tasks returned
2. test_search_tasks_case_insensitive: Create task with mixed case title, search with different case, verify match found
3. test_search_tasks_partial_match: Create task with long title, search with substring, verify match found
4. test_search_tasks_empty_results: Search with query that matches no tasks, verify HTTP 200 with empty array
5. test_search_tasks_missing_title: Make request without title parameter, verify HTTP 422 with validation error
6. test_search_tasks_empty_title: Make request with empty string title, verify HTTP 422 with validation error
7. test_search_tasks_whitespace_title: Make request with whitespace-only title, verify HTTP 422 with validation error

### Test Data Setup

- Use session fixture to create test tasks with known titles
- Include variety: different cases, partial matches, special characters
- Clean database between tests (handled by session fixture)

### Assertion Strategy

- Assert response status code matches expected (200 or 422)
- Assert response body structure (array for success, object with detail for errors)
- Assert correct tasks returned (check IDs, titles, or count)
- Assert existing endpoints still work (regression testing)

### Coverage Goals

- All success paths: valid search with results, valid search with no results
- All error paths: missing parameter, empty string, whitespace-only
- Edge cases: case sensitivity, partial matching, special characters
- Regression: existing tests continue to pass
