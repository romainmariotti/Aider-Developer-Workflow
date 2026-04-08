# ARCHITECTURE: Issue 11 - Reject Whitespace-Only Task Titles

## Overview

This issue requires adding validation logic to the POST /tasks endpoint to reject titles that are empty or contain only whitespace characters. The validation should occur before the task is persisted to the database and should return HTTP 422 with a descriptive error message.

## Where to Implement

**Primary implementation file:** app/routes.py

**Specific function:** create_task function (currently at line 42 based on read-only reference)

**Test file:** tests/test_tasks.py

**Models file:** app/models.py (may need to review TaskCreate model but likely no changes needed there)

## Route Path and Conflict Avoidance

**Route:** POST /tasks (existing route, no new route needed)

**No conflicts:** This is an enhancement to existing endpoint behavior, not a new endpoint. The route already exists and handles task creation. We are adding validation logic within the existing handler function.

## Validation Approach

**Location:** Add validation at the beginning of the create_task function in app/routes.py, after receiving task_data parameter but before creating the Task object.

**Validation logic:**
- Check if task_data.title is None or empty string
- Check if task_data.title.strip() results in empty string (this catches whitespace-only titles)
- If either condition is true, raise HTTPException with status_code 422
- Use detail message consistent with search endpoint: "Title must be a non-empty string" or similar

**Validation order:**
1. First validate that title exists and is not None (may already be handled by Pydantic)
2. Then validate that title is not empty string
3. Then validate that title.strip() is not empty (catches whitespace-only)

**Why this approach:** The strip() method removes leading and trailing whitespace. If the result is empty, the original string contained only whitespace. This is a simple and reliable check that handles all whitespace characters (spaces, tabs, newlines, etc.).

## Error Handling Rules

**HTTP status code:** 422 Unprocessable Entity (consistent with search endpoint validation)

**Error response format:** JSON object with detail field containing string message

**Error message:** "Title must be a non-empty string" or "Title parameter must be a non-empty string" (align with existing search endpoint message for consistency)

**When to raise error:**
- Title is None (may be caught by Pydantic already)
- Title is empty string
- Title contains only whitespace characters (spaces, tabs, newlines, etc.)

**When NOT to raise error:**
- Title contains valid characters even with leading/trailing whitespace (example: "  valid  ")
- Title contains special characters or numbers (these are valid)

## DB Query Approach

**No database query needed for validation.** The validation occurs before any database interaction.

**Database interaction flow:**
1. Receive request with task_data
2. Perform validation on task_data.title (new step)
3. If validation fails, raise HTTPException and return immediately (no DB interaction)
4. If validation passes, create Task object from task_data (existing behavior)
5. Add task to session (existing behavior)
6. Commit session (existing behavior)
7. Refresh task (existing behavior)
8. Return task (existing behavior)

**No task is persisted if validation fails** because the HTTPException is raised before session.add() is called.

## Testing Strategy

**Unit tests to add in tests/test_tasks.py:**

1. Test whitespace-only title with spaces - verify POST /tasks with title containing only spaces returns HTTP 422 with appropriate error message
2. Test whitespace-only title with tabs - verify POST /tasks with title containing only tabs returns HTTP 422
3. Test whitespace-only title with mixed whitespace - verify POST /tasks with title containing spaces, tabs, and newlines returns HTTP 422
4. Test empty string title - verify POST /tasks with empty string title returns HTTP 422
5. Test single space title - verify POST /tasks with single space returns HTTP 422
6. Test valid title with surrounding whitespace - verify POST /tasks with title like "  valid task  " returns HTTP 201 and creates task successfully
7. Test that no task is created when validation fails - verify database does not contain invalid task after failed request

**Integration testing:**
- Verify existing test_create_task still passes (tests valid task creation)
- Verify all other existing tests continue to pass
- Run full test suite to ensure no regressions

**Test fixtures:** Use existing session and client fixtures from tests/test_tasks.py

**Assertion strategy:**
- Assert response status code is 422 for invalid titles
- Assert response JSON contains detail field with error message
- Assert response status code is 201 for valid titles
- Assert task is created in database for valid requests
- Assert task is NOT created in database for invalid requests (query database after failed request)

## Implementation Notes

**Consistency with existing code:**
- The search endpoint in app/routes.py already validates for empty/whitespace titles using similar logic (lines 20-25 in read-only reference)
- Reuse the same validation pattern and error message format for consistency
- Use HTTPException with status_code 422 matching the search endpoint behavior

**Pydantic validation:**
- TaskCreate model in app/models.py has title as required str field
- Pydantic already handles type validation and required field validation
- Our validation adds business logic on top of Pydantic's type validation

**No model changes needed:**
- TaskCreate model does not need modification
- Validation is implemented in route handler, not in model
- This keeps validation logic centralized and easier to test
