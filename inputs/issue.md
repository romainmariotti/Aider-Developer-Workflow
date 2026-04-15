Summary
Add a task counter and a “Clear all tasks” button in the UI, backed by a new API endpoint to delete all tasks.

Context / problem
Current situation: Users can delete tasks one by one, but there is no quick way to reset the list.
Pain point: During demos/testing, we often need to remove all tasks and start fresh.
Target users: Demo users and developers testing the workflow.
User story
As a user, I want to see how many tasks exist and be able to clear all tasks at once so that I can reset the app quickly during demos.

Acceptance criteria

The UI displays a task counter (example: “Tasks: 5”) near the “Tasks” section title.

The counter updates after: create task, delete task, duplicate task, and clear all tasks.

A new button “Clear all” is visible in the UI near the tasks list.

Clicking “Clear all” asks for confirmation (browser confirm dialog is enough).

If confirmed, the frontend calls a new backend endpoint that deletes all tasks.

Backend endpoint exists: DELETE /tasks

DELETE /tasks returns HTTP 204 on success (no body).

After a successful clear, the UI refreshes and shows the empty state message.

If the API fails, the UI shows an error message using the existing error mechanism.

Automated tests are added/updated to cover:
DELETE /tasks clears the database and returns 204
After clearing, GET /tasks returns an empty list
Priority
P1 - High

Estimated size (T-shirt)
S

Risk level
Low

Constraints / assumptions
Must not add new dependencies.
Must not change the database schema.
Frontend is plain HTML/CSS/JS served by FastAPI.
Use existing FastAPI + SQLModel patterns and existing test fixture style.
Out of scope
No undo feature.
No bulk deletion by filters.
No authentication/authorization.
Dependencies / related issues
None.

Target milestone (optional)
Demo

Additional notes / screenshots / files
Keep UI minimal: counter text + one button. This is mainly for demo/testing convenience.
