# DB_SCHEMA: Task Search by Title Endpoint

## Schema Change Needed?

No

## Why No Schema Change

The existing Task table already contains all required fields for the search functionality:

- Field title (string type) exists and contains the data to search
- Field id (integer, primary key) exists for unique identification
- Field description (optional string) exists and will be included in results
- Field completed (boolean) exists and will be included in results
- Field created_at (datetime) exists and will be included in results

The search endpoint will query existing data using a WHERE clause with LIKE operator for partial matching. No new columns, tables, or constraints are required.

## Current Schema (From app/models.py)

The Task model defines the following structure:

- Table name: task (SQLModel default)
- Column id: Optional integer, primary key, auto-increment
- Column title: String, required (not nullable)
- Column description: Optional string, nullable
- Column completed: Boolean, default False
- Column created_at: Datetime, default to current UTC time

This schema is sufficient for the search functionality.

## Query Impact

The search endpoint will perform a SELECT query with WHERE clause filtering on the title column using case-insensitive LIKE pattern matching. The query will scan the title column for substring matches.

Current database engine is SQLite (from app/database.py: sqlite:///./data/tasks.db). SQLite supports LIKE operator and case-insensitive matching using COLLATE NOCASE or by converting to lowercase.

No schema modifications are needed to support this query pattern.

## Future Optimization Notes

If search performance becomes a concern with large datasets (thousands of tasks), consider these optimizations:

- Add database index on title column to speed up LIKE queries (requires migration)
- Add full-text search index if more advanced search features are needed later (requires SQLite FTS extension or migration to PostgreSQL)
- Add pagination to limit result set size (application-level change, no schema change)
- Add caching layer for frequent searches (application-level change, no schema change)

For current scope and expected dataset size, no optimization is required. The existing schema is adequate.
