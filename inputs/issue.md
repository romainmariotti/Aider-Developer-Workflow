Summary
Add a “Duplicate” feature that creates a new task by copying an existing one (same title/description), via a dedicated API endpoint and a button in the frontend.

Context / problem
Current situation: Users can create, list, update, and delete tasks.
Pain point: Users often want to reuse an existing task as a template (same title/description) without retyping it.
Target users: Web UI users and API consumers who want fast task cloning.
User story
As a user, I want to duplicate a task so that I can quickly create a copy and then edit it instead of recreating it from scratch.

Acceptance criteria
Backend (API)
A new endpoint exists: POST /tasks/{task_id}/duplicate
If the original task exists, the endpoint returns HTTP 201 with the newly created Task object.
If the original task does not exist, the endpoint returns HTTP 404 (same style as other “not found” cases).
The original task is not modified.
The duplicated task fields:
title is copied from the original, but with a suffix (copy) appended (example: “Buy milk” → “Buy milk (copy)”)
description is copied as-is (can be null)
completed is set to false (so the copy starts as a new actionable task)
created_at is set to “now” (new timestamp for the copy)
The endpoint appears in Swagger/OpenAPI docs.
Frontend (UI)
Each task item in the list shows a Duplicate button (near Edit/Delete).
Clicking Duplicate calls POST /tasks/{id}/duplicate.
After success, the UI refreshes and shows the new duplicated task in the list.
On error, show an error message using the existing frontend error handling.
Tests (TDD)
Add tests that initially fail (Red), then pass after implementation (Green):
Duplicating an existing task returns 201 and creates a new task with a different id.
The new title ends with (copy).
The new task has the same description, completed=false, and a valid created_at.
Duplicating a non-existent task returns 404.
Existing endpoints still work unchanged.
Priority
P2 - Medium

Estimated size (T-shirt)
M

Risk level
Low

Constraints / assumptions
Must reuse the existing Task model and SQLite database (no schema changes).
Keep backward compatibility (no changes to existing endpoints’ contracts).
No new dependencies.
Out of scope
No bulk duplication (only one task at a time).
No duplication of extra metadata beyond current Task fields.
No authentication/authorization.
Dependencies / related issues
Depends on current Task CRUD endpoints and DB session setup.
Target milestone (optional)
Sprint-01

Additional notes / screenshots / files
Manual API test: create a task, then call POST /tasks/{id}/duplicate and verify a new task appears in GET /tasks.
Manual UI test: click Duplicate and verify a new “(copy)” task appears and is not completed.
