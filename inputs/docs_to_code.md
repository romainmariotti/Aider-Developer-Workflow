You are implementing code based on the provided issue documentation.

SOURCE OF TRUTH

- Use ONLY the information in these files as requirements:
  - SPEC.md
  - ARCHITECTURE.md
  - DB_SCHEMA.md
- If something is unclear, make the smallest reasonable assumption and keep changes minimal.

RULES

- Implement the feature described in SPEC.md.
- Follow the file locations and design described in ARCHITECTURE.md.
- Respect DB_SCHEMA.md (do not change schema if it says “No changes”).
- Update/add tests so the test suite passes.
- Do not edit documentation files.

SCOPE OF CHANGES

- You may modify existing code in:
  - app/
  - tests/
  - frontend/
- You MAY create new files if necessary, but ONLY inside app/, tests/, or frontend/ and only with normal code filenames (no weird names).

DELIVERABLE

- Make the code changes directly in the repository.
- Ensure tests pass (we will run pytest after).
