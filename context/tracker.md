# APHARMA Tracker

## Completed
- Section 01 — Project Foundation
- Section 02 — Database and Migrations
- Section 03 — Auth JWT Backend
- Section 04 — Auth Login Page
- Section 05 — Dashboard Layout

## Current / Next
- First nested area or statistics section

## Notes
- Login redirects to the role dashboard (`/admin`, `/executive`, `/inventory`, `/sales`, `/pharmacist`).
- `(dashboard)` has a shared layout, role-based sidebar, and Overview placeholder pages.
- `GET /auth/me` returns the JWT payload. Logout clears the http-only `apharma_token` cookie.
