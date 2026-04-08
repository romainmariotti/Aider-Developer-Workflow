# DB_SCHEMA: Issue 11 - Reject Whitespace-Only Task Titles

## Schema Change Needed?

No

## Why

This issue addresses validation logic at the application layer, not the database schema layer. The Task model in app/models.py already defines title as a required string field (title: str). No changes to field types, constraints, or table structure are needed.

The validation being added prevents invalid data from reaching the database by rejecting whitespace-only titles at the API endpoint level before any database write operation occurs. This is application-level business logic validation, not a database constraint.

The existing schema is sufficient:
- title field is already defined as str (non-nullable)
- SQLModel/Pydantic already enforces that title must be present and must be a string
- The new validation adds an additional business rule (title must contain non-whitespace characters) that is enforced in the route handler

## Future Optimization Notes

**Optional database constraint consideration:**
If we want to add defense-in-depth and prevent whitespace-only titles from ever being inserted directly into the database (bypassing the API), we could consider adding a CHECK constraint at the database level in the future. However, this is not necessary for resolving the current issue and would require:
- Database migration to add CHECK constraint
- Handling of existing data that might violate the constraint
- Database-specific SQL syntax (SQLite CHECK constraints have limitations)

**Current approach is preferred because:**
- Simpler to implement and test
- Provides clear error messages at the API level
- Consistent with existing validation patterns in the codebase (see search endpoint validation)
- No database migration required
- No risk of constraint violations from existing data

**Index consideration:**
No index changes needed. The title field is used in search queries (ILIKE pattern matching in search endpoint) but adding validation does not change query patterns or performance characteristics.
