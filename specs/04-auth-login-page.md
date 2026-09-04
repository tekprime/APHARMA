# Spec 04 — Auth Login Page

## Goal

Build the public frontend login page inside a Next.js `(auth)` route group.

The page shows a centered shadcn `Card` with username, password, and a login button. On submit it calls the existing backend `POST /auth/login`. After a successful response, the app stores the JWT in an **http-only cookie** (not `localStorage`), then redirects.

This section is frontend-focused. Register, logout, and forgot-password pages are intentionally excluded.

## Current State Assumed

- Section 01 backend foundation is complete.
- Section 02 database and migrations are complete.
- Section 03 Auth JWT Backend is complete.
- Backend `POST /auth/login` exists and returns JSON:

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

- Section 03 login does **not** set cookies yet. The token comes back in the JSON body.
- Browser JavaScript cannot create a real `httpOnly` cookie by itself. This section therefore adds a small Next.js route handler that sets the cookie after login succeeds.
- `client/` already exists with Next.js App Router and shadcn/ui installed.
- Theme tokens already exist in `client/src/app/globals.css`.
- Manual project setup from `manual-work/00-initial-project-setup.md` is already done.

## Files Allowed to Change

- `client/.env.example`
- `client/src/lib/client.ts`
- `client/src/app/(auth)/layout.tsx`
- `client/src/app/(auth)/login/page.tsx`
- `client/src/components/login-form.tsx`
- `client/src/app/api/auth/session/route.ts`

Allowed tracking file:

- `context/tracker.md`

If a required shadcn component is missing, you may add only these generated UI files through the normal shadcn CLI:

- `client/src/components/ui/card.tsx`
- `client/src/components/ui/input.tsx`
- `client/src/components/ui/label.tsx`
- `client/src/components/ui/button.tsx`

## Files Not Allowed to Change

- Backend files inside `server/`
- `client/src/app/page.tsx` content and marketing/home behavior
- Auth middleware / route guards for protected pages
- Register page
- Logout page or logout button
- Forgot-password page

## Page Route

```txt
/login
```

Use a Next.js route group so the URL stays `/login`:

```txt
client/src/app/(auth)/login/page.tsx
```

The `(auth)` group does not appear in the URL.

## Behavior

### Public page

This page is public.

- Do not call `/auth/me`.
- Do not redirect unauthenticated users away from `/login`.
- Do not build protected-route middleware in this section.

### Login flow

In the client form:

1. Collect `username` and `password`.
2. Prevent default form submit.
3. Validate both fields are non-empty strings.
4. Call the Express backend:

```ts
clientApiFetch<{
  token: string;
  user: {
    userId: number;
    username: string;
    role: string;
  };
}>("/auth/login", {
  method: "POST",
  body: JSON.stringify({ username, password }),
});
```

5. On success, call the Next.js session route so the browser receives an http-only cookie:

```ts
await fetch("/api/auth/session", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ token }),
});
```

6. On success:
   - do **not** store the JWT in `localStorage` or `sessionStorage`
   - redirect to `/`
7. On failure:
   - show a simple error message above the form
   - keep the entered username
   - do not crash the page
8. While submitting:
   - disable the login button
   - button text: `Signing in...`

Use `useRouter` from `next/navigation`.

## Components

### 1. `client/src/app/(auth)/layout.tsx`

Create a simple layout for the auth group.

Layout behavior:

- full-height centered shell
- no navbar
- no dashboard chrome
- children rendered in the center of the viewport

Suggested layout classes:

```txt
min-h-screen bg-background flex items-center justify-center px-4
```

Keep this layout beginner-friendly and small.

### 2. `client/src/app/(auth)/login/page.tsx`

Render the page shell for `/login`.

Page content:

- render `<LoginForm />`
- do not submit from a Server Component
- keep the page itself thin

Suggested page wrapper:

```txt
w-full max-w-md
```

### 3. `client/src/components/login-form.tsx`

Create a client component.

Add `"use client"` at the top.

Use a shadcn `Card` centered in the auth layout.

Card contents:

| Field    | Input type            | Required |
| -------- | --------------------- | -------- |
| Username | text input            | yes      |
| Password | password input        | yes      |
| Login    | primary submit button | yes      |

Suggested card structure:

- `Card`
- `CardHeader`
  - title: `Sign in`
  - description: short text such as `Enter your username and password to continue.`
- `CardContent`
  - form with username, password, error message, and submit button

Form field names:

```txt
username
password
```

Request body must match the backend:

```json
{
  "username": "admin_system",
  "password": "password123"
}
```

## Cookie Session Route

### `client/src/app/api/auth/session/route.ts`

Create a small Next.js Route Handler that sets the http-only auth cookie.

Required behavior for `POST`:

1. Read JSON body `{ token: string }`.
2. Reject with `400` if `token` is missing or not a non-empty string.
3. Set a cookie with:

```txt
name: apharma_token
httpOnly: true
path: /
sameSite: lax
secure: true only in production
maxAge: 1 day (86400 seconds)
```

4. Respond `200` with a simple JSON body such as `{ "ok": true }`.

Rules:

- This route exists only to set the http-only cookie after backend login succeeds.
- Do not re-implement username/password verification here.
- Do not call Postgres from this route.
- Do not implement logout/clear-cookie in this section.
- Do not create other Next.js API proxy routes.

## API Helper

### `client/src/lib/client.ts`

Create a small client-side fetch helper if it does not already exist.

Required export:

- `clientApiFetch<T>(path: string, init?: RequestInit): Promise<T>`

Rules:

- Read base URL from `process.env.NEXT_PUBLIC_API_URL`
- Default base URL to `http://localhost:5000` if missing
- Set `Content-Type: application/json` when a body is present
- Throw a readable error when the response is not ok
- Prefer reading `{ error: string }` from failed JSON responses when available
- Do not put the JWT into `localStorage`

### `client/.env.example`

Add only:

```env
NEXT_PUBLIC_API_URL=http://localhost:5000
```

Do not add OpenAI, Google OAuth, or future feature env variables.

## Styling Rules

Use only installed theme tokens from `globals.css`.

Allowed examples:

- `bg-background`
- `bg-card`
- `bg-muted`
- `text-foreground`
- `text-muted-foreground`
- `border-border`
- `bg-primary`
- `text-primary-foreground`

Avoid random Tailwind colors such as:

- `bg-blue-600`
- `text-slate-500`
- `bg-green-100`
- `text-red-600`
- `bg-zinc-900`

Form styling guidance:

- card: use shadcn `Card` with theme tokens
- page background: `bg-background`
- labels: readable and close to inputs
- inputs: use shadcn `Input`
- submit button: primary `Button`
- error message: keep simple and token-based; do not invent strong random red utility classes

## Scope Limits

Do not build:

- register page
- logout button or logout route
- forgot-password page
- Google OAuth button
- protected route middleware
- `/auth/me` client flow
- dashboard redirects based on role
- toast libraries
- form validation libraries
- backend cookie changes in `server/`

Those come later or are intentionally excluded.

## Verification

Run from `client/`:

```bash
npm run build
```

With the backend running, manually verify:

```txt
http://localhost:3000/login
```

Expected:

- `/login` page builds and renders a centered card.
- Username and password fields are visible.
- Submit calls Express `POST /auth/login`.
- Successful login calls `POST /api/auth/session` and sets an `httpOnly` cookie named `apharma_token`.
- Successful login redirects to `/`.
- Failed login shows an error and stays on `/login`.
- JWT is not stored in `localStorage`.
- No register, logout, or forgot-password pages are added.
- No backend files are changed.

If backend auth is temporarily broken locally because of seed hash mismatch, build verification is still required for this section.

## Tracker Update

After implementation, update `context/tracker.md`:

- Mark Section 04 as completed.
- Set next section to the next unbuilt frontend or auth section.
- Keep notes short.
- Mention that `/login` is public, calls `POST /auth/login`, and stores the JWT in an http-only `apharma_token` cookie.
