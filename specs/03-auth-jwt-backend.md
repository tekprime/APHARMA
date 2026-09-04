# Spec 03 — Auth JWT Backend

## Goal

Add username and password login on the Express API. On success, sign a JWT whose payload includes the user's `role` from the existing `user_role_enum` column on `erp_users`.

This section must stay small. It should prove that a seeded user can log in and receive a signed token. It does not complete Google OAuth, frontend login pages, or route guards.

## Current State Assumed

- Section 01 backend foundation is complete.
- Section 02 database and migrations are complete.
- `server/src/server.ts` exists.
- `server/src/routes/index.ts` exists and is mounted by the server.
- `server/src/db/pool.ts` exists.
- `server/.env.example` exists.
- `erp_users` already has `username`, `password_hash`, and `role user_role_enum`.
- Seed data in `server/src/migrations/seed.sql` already includes bcrypt hashes for password `password123`.
- Root `docker-compose.yml` and Postgres setup already exist.

## Files Allowed to Change

- `server/package.json`
- `server/.env.example`
- `server/src/lib/jwt.ts`
- `server/src/controllers/auth.controller.ts`
- `server/src/routes/auth.routes.ts`
- `server/src/routes/index.ts`

Allowed tracking file:

- `context/tracker.md`

## Files Not Allowed to Change

- Frontend files inside `client/`
- Database migration files
- Seed SQL
- Repository files
- Test-only endpoints
- Auth middleware / route guards for other APIs

## Implementation Steps

### 1. Keep package changes minimal

Inside `server/`, add only what login needs.

Runtime dependencies:

```txt
bcryptjs
jsonwebtoken
```

Dev dependencies:

```txt
@types/bcryptjs
@types/jsonwebtoken
```

Do not add Google SDKs, Passport, or session stores.

Preserve existing scripts from Sections 01 and 02. Do not add register, seed, or auth-test scripts.

### 2. Update `server/.env.example`

Add only these auth-related values if missing:

```env
JWT_SECRET=change-me-in-local-env
JWT_EXPIRES_IN=1d
```

Keep existing `PORT`, `DATABASE_URL`, and `FRONTEND_URL`.

Do not add Google OAuth keys, OpenAI keys, or future feature env variables.

### 3. Create `server/src/lib/jwt.ts`

Create a small JWT helper module.

Required exports:

- `signAuthToken(payload: AuthTokenPayload): string`
- `verifyAuthToken(token: string): AuthTokenPayload`

Expected payload shape:

```ts
{
  userId: number
  username: string
  role: "ADMIN" | "EXECUTIVE" | "WAREHOUSE_MANAGER" | "SALES_REP" | "PHARMACIST"
}
```

Rules:

- Read `JWT_SECRET` from `process.env`.
- Read `JWT_EXPIRES_IN` from `process.env`, defaulting to `1d` if missing.
- Throw a clear error if `JWT_SECRET` is missing.
- Put `userId`, `username`, and `role` in the signed token.
- Do not put `password` or `password_hash` in the token.
- Do not query the database here.

### 4. Create `server/src/controllers/auth.controller.ts`

Create one login controller function.

Required export:

- `login(req, res)`

Request JSON body:

```json
{
  "username": "admin_system",
  "password": "password123"
}
```

Behavior:

- Reject with `400` if `username` or `password` is missing or not a non-empty string.
- Load the user with a parameterized `pg` query against `erp_users` using the shared pool.
- Select only `user_id`, `username`, `password_hash`, and `role`.
- If no row is found, respond `401` with `{ "error": "Invalid username or password" }`.
- Compare the submitted password to `password_hash` with `bcryptjs`.
- If the password does not match, respond `401` with the same error message as a missing user.
- On success, call `signAuthToken` with `userId`, `username`, and `role` from the database row.
- Respond `200` with:

```json
{
  "token": "<signed-jwt>",
  "user": {
    "userId": 1,
    "username": "admin_system",
    "role": "ADMIN"
  }
}
```

Rules:

- Use the database `role` value. Do not hard-code a role.
- Do not return `password_hash`.
- Do not create users, reset passwords, or implement logout.
- Do not set cookies in this section.
- Keep the handler beginner-readable. Do not add a service layer.

### 5. Create `server/src/routes/auth.routes.ts`

Create an Express router with only:

```txt
POST /login
```

Behavior:

- Calls `login` from the auth controller.
- Does not implement register, logout, `/auth/me`, or Google OAuth routes.

### 6. Mount auth routes

Update `server/src/routes/index.ts` so the auth router is mounted at:

```txt
/auth
```

The login URL becomes:

```txt
POST /auth/login
```

Do not remove the existing health route.

## Verification

After implementation, start Postgres if needed, then:

```bash
cd server
npm install
npm run build
npm run dev
```

Then test login with a seeded user:

```bash
curl.exe -X POST http://localhost:5000/auth/login -H "Content-Type: application/json" -d "{\"username\":\"admin_system\",\"password\":\"password123\"}"
```

Expected:

- `200` JSON with `token` and `user.role` equal to `ADMIN`.
- Wrong password returns `401`.
- Existing `/health` still works.

Do not add a test endpoint.

Do not require frontend login testing in this section.

## Tracker Update

After implementation, update `context/tracker.md`:

- Mark Section 03 as completed.
- Set next section to Section 03A if Google OAuth start is still pending, otherwise the next unbuilt auth section.
- Keep notes short. Mention that username/password login signs a JWT that includes `userId`, `username`, and database `role`.
