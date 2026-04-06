Use ONLY facts from repository files provided via --read for model fields, routes, and file paths. If something is not present in those files, write "Unknown" instead of guessing or inventing.

IMPORTANT RULES (MUST FOLLOW)

- Documentation only. Do NOT implement code.
- Only modify the 3 files passed on the command line (SPEC.md, ARCHITECTURE.md, DB_SCHEMA.md).
- Do NOT ask to add any other files.
- Do NOT create any new files.
- Do NOT output fenced code blocks (no ```...).

CRITICAL FORMATTING RULE (prevents Aider prompts)

- Never write endpoints, SQL, JSON, [], {}, or example outputs on a line by themselves.
- If you include examples, write them as bullet sentences, like:
  - Example request: GET /tasks/search?title=buy
  - Example response: HTTP 200 returns a JSON array of Task objects
    (Do NOT put "GET /tasks/..." alone on its own line.)

OUTPUT FORMAT
Write FULL FILE CONTENT for each file using Markdown headings and bullet lists only.

File 1 = SPEC

- Overview
- In scope / Out of scope
- Acceptance criteria checklist
- Edge cases
- API contract in plain text (no code blocks)
- Manual verification steps

File 2 = ARCHITECTURE

- Overview
- Where to implement (use exact file paths from --read files; otherwise write Unknown)
- Route path and why it avoids conflicts
- DB query approach (describe in words; no SQL blocks)
- Validation/error handling rules (422 for missing/empty/whitespace title)
- Testing strategy (unit + integration)

File 3 = DB_SCHEMA

- Schema change needed? (Yes/No)
- Why
- Future optimization notes (optional)

After writing the 3 files, STOP. No further suggestions.
Now use the GitHub issue below as input and update ONLY the 3 provided docs files.
