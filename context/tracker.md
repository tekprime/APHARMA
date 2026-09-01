# APHARMA Tracker

## Completed
- Section 01 — Project Foundation
- Section 02 — Database and Migrations

## Current / Next
- Section 03 — Auth JWT Backend

## Notes
- PostgreSQL Docker Compose, DB pool, migration runner, and `001_init_schema.sql` are ready.
- Copy `server/.env.example` to `server/.env` before running migrations.
- Known issue: if a local PostgreSQL service already uses port 5432, `npm run migrate` from the host may fail auth until that service is stopped or the compose port mapping is adjusted.
