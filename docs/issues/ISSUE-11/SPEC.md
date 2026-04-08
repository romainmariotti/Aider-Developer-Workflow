# SPEC: Issue 11 - Reject Whitespace-Only Task Titles

## Overview

The POST /tasks endpoint currently accepts task titles that contain only whitespace characters (spaces, tabs, etc.) and creates tasks with these invalid titles. This violates data quality expectations since a title should contain meaningful text content.

## In Scope

- Add validation to reject whitespace-only titles when creating tasks via POST /tasks
- Return HTTP 422 status code with a clear error message when title is empty or whitespace-only
- Prevent creation of tasks with whitespace-only titles
- Ensure validation is consistent with existing search endpoint behavior (which already validates for empty/whitespace titles)

## Out of Scope

- Validation for existing tasks in the database (migration or cleanup)
- Validation on the PUT /tasks/{task_id} endpoint (separate issue if needed)
- Trimming or normalizing whitespace in valid titles
- Validation of description field
- Maximum length validation for title field

## Acceptance Criteria Checklist

- [ ] POST /tasks with title containing only spaces returns HTTP 422
- [ ] POST /tasks with title containing only tabs returns HTTP 422
- [ ] POST /tasks with title containing mixed whitespace (spaces, tabs, newlines) returns HTTP 422
- [ ] POST /tasks with empty string title returns HTTP 422
- [ ] Error response includes detail field explaining the validation failure
- [ ] Error message matches the pattern used in search endpoint: "Title parameter must be a non-empty string" or similar
- [ ] POST /tasks with valid title (contains non-whitespace characters) still works correctly
- [ ] No task is created in the database when validation fails
- [ ] Existing tests continue to pass
- [ ] New tests added to verify whitespace-only title rejection

## Edge Cases

- Title with leading/trailing whitespace but valid content in middle (example: "  valid task  ") should be ACCEPTED (trimming is out of scope)
- Title with only space characters (example: "   ")
- Title with only tab characters (example: "\t\t\t")
- Title with mixed whitespace types (example: " \t \n ")
- Empty string title (example: "")
- Title with single space (example: " ")
- Title with Unicode whitespace characters if applicable

## API Contract

### Endpoint: POST /tasks

**Request format:** JSON body with fields title (required string), description (optional string), completed (optional boolean defaulting to false)

**Success response (HTTP 201):** Returns created Task object with fields id, title, description, completed, created_at

**Validation error response (HTTP 422):** Returns JSON object with detail field containing error message when title is empty or whitespace-only. Example detail message: "Title must be a non-empty string" or "Title parameter must be a non-empty string"

**Validation rules:**
- Title field is required (existing behavior)
- Title must not be empty string (new validation)
- Title must not contain only whitespace characters (new validation)
- Title with leading/trailing whitespace but valid content is acceptable

## Manual Verification Steps

1. Start the API server using: uvicorn app.main:app --reload
2. Test whitespace-only title with spaces - send POST request to /tasks with body containing title field set to three spaces, description field set to "should fail", completed field set to false - verify response is HTTP 422 with validation error message
3. Test whitespace-only title with tabs - send POST request to /tasks with body containing title field set to tab characters, description field set to "should fail", completed field set to false - verify response is HTTP 422 with validation error message
4. Test empty string title - send POST request to /tasks with body containing title field set to empty string, description field set to "should fail", completed field set to false - verify response is HTTP 422 with validation error message
5. Test valid title with whitespace - send POST request to /tasks with body containing title field set to "  valid task  ", description field set to "should succeed", completed field set to false - verify response is HTTP 201 and task is created
6. Verify no invalid tasks created - call GET /tasks and confirm no tasks with whitespace-only titles exist
7. Run test suite using: pytest tests/test_tasks.py -v
8. Verify all existing tests pass and new validation tests pass
