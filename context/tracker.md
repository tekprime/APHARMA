# APHARMA Tracker

## Completed
- Section 01 — Project Foundation
- Section 02 — Database and Migrations
- Section 03 — Auth JWT Backend
- Section 04 — Auth Login Page

## Current / Next
- Next unbuilt frontend or auth section

## Notes
- `/login` is public, calls `POST /auth/login`, and stores the JWT in an http-only `apharma_token` cookie via `POST /api/auth/session`.
- Copy `client/.env.example` to `client/.env.local` if you need a custom API URL.
