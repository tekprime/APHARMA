# APHARMA Tracker

## Completed
- Section 01 — Project Foundation
- Section 02 — Database and Migrations
- Section 03 — Auth JWT Backend

## Current / Next
- Section 03 —Auth JWT Backend

## Notes
- `POST /auth/login` signs a JWT with `userId`, `username`, and database `role`.
- Copy `server/.env.example` to `server/.env` and set `JWT_SECRET` before running the API.
- Seeded `erp_users` bcrypt hashes match password `password123`. Re-apply the users section of `seed.sql` if login still returns 401.
