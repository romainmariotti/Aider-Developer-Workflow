# Docs-only issue analysis (STRICT)

You are converting a GitHub issue into documentation ONLY.

SOURCE OF TRUTH

- Use the GitHub issue text provided below as the requirement input.
- Use repository files provided as read-only context ONLY for:
  - exact model fields (e.g., Task fields)
  - exact file paths (e.g., app/routes.py)
    Do not invent fields or file locations.

ABSOLUTE RULES (MUST FOLLOW)

- Documentation only. DO NOT implement code.
- DO NOT propose code patches or diffs.
- DO NOT request to add any files to the chat.
- DO NOT create any new files.
- ONLY modify the 3 files passed on the command line:
  - SPEC.md
  - ARCHITECTURE.md
  - DB_SCHEMA.md
- DO NOT edit anything under app/, tests/, frontend/, .github/, etc.
- DO NOT output fenced code blocks (no ```).

CRITICAL FORMATTING RULE (prevents Aider prompts)

- Never put endpoints, SQL, JSON, [], {}, or example outputs on a line by themselves.
- If you include examples, write them as bullet sentences, like:
  - Example request: GET /tasks/search?title=buy
  - Example response: HTTP 200 returns a JSON array of Task objects
    (Do NOT write: GET /tasks/... on its own line.)

OUTPUT FORMAT (VERY IMPORTANT)
Write FULL FILE CONTENT for each of the 3 docs files using:

- Markdown headings
- Bullet lists
- Short paragraphs
  Only.

Each file must contain:

1. SPEC.md

- Title
- Overview
- In scope / Out of scope
- Acceptance criteria (checklist)
- Edge cases
- API contract (in plain text, no standalone endpoint lines)
- Manual verification steps (Swagger-oriented)

2. ARCHITECTURE.md

- Overview
- Where to implement (exact repo file paths)
- Route path (in plain text)
- DB query approach (described in words)
- Validation/error handling rules (422/404 etc.)
- Testing strategy (high level)

3. DB_SCHEMA.md

- Schema change needed? (Yes/No)
- Why
- Future optimization notes (optional)

After writing the 3 files, STOP immediately. No extra suggestions.

--- ISSUE INPUT START ---
(see below)
--- ISSUE INPUT END ---
