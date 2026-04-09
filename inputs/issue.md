### Summary

Build a minimal web frontend that lets users view, create, update, and delete tasks via the existing Task API.

### Context / problem

- Current situation: The Task API only exposes endpoints via Swagger UI at /docs, which is a developer tool and not suitable for end users.
- Pain points: Non-technical users cannot interact with the API without manually crafting HTTP requests or using Swagger's technical interface.
- Target users: Anyone who wants to manage their tasks through a clean, browser-based interface without touching the API directly.

### User story

As a user, I want a simple web interface for the Task API so that I can manage my tasks without using Swagger UI or technical tools.

### Acceptance criteria

- [ ] Given the frontend is loaded, when the page opens, then all existing tasks are fetched from GET /tasks and displayed in a list
- [ ] Given a user fills in the "new task" form, when they submit it, then POST /tasks is called and the new task appears in the list
- [ ] Given a task is displayed, when the user clicks a checkbox, then PUT /tasks/{id} toggles its completed status
- [ ] Given a task is displayed, when the user clicks the delete button, then DELETE /tasks/{id} removes it from the list
- [ ] Given the API returns an error, when it occurs, then a user-friendly error message is shown
- [ ] The frontend is served as a static page (HTML + CSS + JS) or as a separate container in docker-compose

### Priority

P2 - Medium

### Estimated size (T-shirt)

L

### Risk level

Low

### Constraints / assumptions

- Must work with the existing Task API without changes to the backend
- Should stay lightweight — no heavy frameworks required (vanilla JS or a small framework like Alpine.js / HTMX is preferred)
- Must handle CORS correctly if served from a different origin than the API
- Assumption: The frontend will be deployed alongside the API on the same server

### Out of scope

- User authentication / login
- Multi-user support
- Task categories, tags, or filtering beyond basic list view
- Mobile-specific optimizations
- Dark/light theme toggle

### Dependencies / related issues

- Depends on: Task API (already implemented)
- Related: CORS configuration may need to be added to the backend if frontend is served on a different origin

### Target milestone (optional)

_No response_

### Additional notes / screenshots / files

Suggested tech: plain HTML/CSS/JS or HTMX for simplicity. Could be deployed as a static site via Nginx in the same docker-compose stack as the API, accessible at tasks.mberchtold.ch or similar.

add changes to the current readme file
The frontend should be in a /frontend folder in the root