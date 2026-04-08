Summary
POST /tasks accepts a title that contains only whitespace and creates an invalid task

Steps to reproduce
Start the API locally: uvicorn app.main:app --reload

Call the endpoint:

Method: POST /tasks
Body:
{
"title": " ",
"description": "should not be allowed",
"completed": false
}
Observe the response and then call GET /tasks to confirm the task was created.
Expected behavior
The API should reject a whitespace-only title.
Response should be HTTP 422 with a validation error explaining that title must not be empty or whitespace-only.
No task should be created.
Actual behavior
The API returns HTTP 200/201 (success) and creates a task with a whitespace-only title.
The task appears in GET /tasks.
Severity
S2 - Minor (workaround exists)

Environment (optional)
OS: Windows 11
Python: 3.12.x
Branch/commit: (your current branch)
Docker/local: local
Logs / stack trace (optional)
No crash; request succeeds and invalid task is created.
Screenshots / additional context (optional)
No crash; request succeeds and invalid task is created.
