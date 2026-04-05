Summary
Add a new API endpoint to search tasks by title (partial match) and return matching tasks.

Context / problem
Current situation: The API supports listing all tasks (GET /tasks) and fetching by id (GET /tasks/{task_id}), but there is no way to filter tasks by title.
Pain point: A client has to fetch all tasks and filter locally, which is inefficient and not scalable.
Target users: API consumers (frontend / other services) who need to find tasks by title quickly.
User story
As an API consumer, I want to search tasks by title so that I can quickly find relevant tasks without downloading the entire list.

Acceptance criteria

A new endpoint exists: GET /tasks/search?title=

When title is provided, the endpoint returns HTTP 200 and a JSON array of tasks whose title contains the query (case-insensitive).

If no tasks match, it returns HTTP 200 with an empty array [].

If title is missing or empty, it returns HTTP 422 (validation error).

The endpoint does not break existing endpoints (/tasks, /tasks/{task_id}, etc.).

The endpoint appears in Swagger/OpenAPI documentation.
Priority
P1 - High

Estimated size (T-shirt)
S

Risk level
Low

Constraints / assumptions
Must keep the existing API unchanged (backward compatible).
Must use the existing database and models (no new database).
Should be implemented using existing FastAPI + SQLModel patterns.
Out of scope
No authentication/authorization changes.
No pagination or advanced filtering (only title search for now).
No UI/frontend work.
Dependencies / related issues
Related to usability of existing task CRUD endpoints.
No external dependencies.
Target milestone (optional)
Sprint-01

Additional notes / screenshots / files
Swagger currently shows: GET /tasks and GET /tasks/{task_id} but no search endpoint.
This issue is created to validate the Requirement intake template + later demo Aider generating spec/design and implementing the endpoint.
