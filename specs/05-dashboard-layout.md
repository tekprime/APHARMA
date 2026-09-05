# Spec 05 — Dashboard Layout

## Goal

Build the authenticated Next.js `(dashboard)` layout shell and a simple Overview page in each dashboard area folder.

The layout has a top bar, a shadcn left sidebar, and a right content panel. Sidebar buttons depend on the logged-in user's `role`. The clicked sidebar item is highlighted.

Create these area folders now, each with one Overview page that currently shows the text `Overview` only:

```txt
admin
executive
inventory
sales
pharmacist
```

Change the login page so a successful login goes to that user's role dashboard, not `/`.

Do not pull statistics from the database in this section. Later sections will load overview stats after sending the JWT and authenticating the user on the backend.

Do not create future nested folders now, such as `inventory/batches`. Those come later.

## Current State Assumed

- Section 01 backend foundation is complete.
- Section 02 database and migrations are complete.
- Section 03 Auth JWT Backend is complete.
- Section 04 Auth Login Page is complete.
- `POST /auth/login` returns `token` and `user.role`.
- Known roles:

```txt
ADMIN
EXECUTIVE
WAREHOUSE_MANAGER
SALES_REP
PHARMACIST
```

- Login stores the JWT in an http-only cookie named `apharma_token` via `POST /api/auth/session`.
- `client/src/components/login-form.tsx` currently redirects to `/` after success.
- `client/` already has Next.js App Router, shadcn/ui, and theme tokens in `client/src/app/globals.css`.

## Files Allowed to Change

- `client/src/app/page.tsx`
- `client/src/app/(dashboard)/layout.tsx`
- `client/src/app/(dashboard)/admin/page.tsx`
- `client/src/app/(dashboard)/executive/page.tsx`
- `client/src/app/(dashboard)/inventory/page.tsx`
- `client/src/app/(dashboard)/sales/page.tsx`
- `client/src/app/(dashboard)/pharmacist/page.tsx`
- `client/src/components/dashboard-shell.tsx`
- `client/src/components/dashboard-topbar.tsx`
- `client/src/components/dashboard-sidebar.tsx`
- `client/src/lib/nav.ts`
- `client/src/lib/server.ts`
- `client/src/components/login-form.tsx`
- `client/src/app/api/auth/session/route.ts`
- `server/src/controllers/auth.controller.ts`
- `server/src/routes/auth.routes.ts`

Allowed tracking file:

- `context/tracker.md`

If a required shadcn component is missing, you may add only these generated UI files through the normal shadcn CLI:

- `client/src/components/ui/sidebar.tsx`
- `client/src/components/ui/avatar.tsx`
- `client/src/components/ui/dropdown-menu.tsx`
- `client/src/components/ui/separator.tsx`
- `client/src/components/ui/button.tsx`

## Files Not Allowed to Change

- Database migration files
- Seed SQL
- Register page
- Forgot-password page
- Google OAuth
- Overview statistics endpoints
- Future nested area pages such as batches

## Routes

The `(dashboard)` group does not appear in the URL.

Create exactly these area Overview routes:

```txt
/admin
/executive
/inventory
/sales
/pharmacist
```

Files:

```txt
client/src/app/(dashboard)/layout.tsx
client/src/app/(dashboard)/admin/page.tsx
client/src/app/(dashboard)/executive/page.tsx
client/src/app/(dashboard)/inventory/page.tsx
client/src/app/(dashboard)/sales/page.tsx
client/src/app/(dashboard)/pharmacist/page.tsx
```

Each `page.tsx` is the Overview page for that area. The visible text is:

```txt
Overview
```

Do not add charts, tables, counts, or API calls on these pages in this section.

### Role to area mapping

| Role | Area folder | Dashboard path |
| ---- | ----------- | -------------- |
| `ADMIN` | `admin` | `/admin` |
| `EXECUTIVE` | `executive` | `/executive` |
| `WAREHOUSE_MANAGER` | `inventory` | `/inventory` |
| `SALES_REP` | `sales` | `/sales` |
| `PHARMACIST` | `pharmacist` | `/pharmacist` |

Use this mapping in `client/src/lib/nav.ts` and reuse it from the login form.

### Reserved for later

Do not create these now. Later specs may add nested folders under an area, for example:

```txt
client/src/app/(dashboard)/inventory/batches/
```

## Login Redirect

This is required in this section.

Update `client/src/components/login-form.tsx`.

Current success behavior:

```ts
router.push("/");
```

New success behavior:

1. Keep the existing `POST /auth/login` call.
2. Keep the existing `POST /api/auth/session` cookie step.
3. Read `result.user.role` from the login response.
4. Resolve that role to a dashboard path with the mapping above.
5. Redirect to that path. Examples:
   - `ADMIN` → `/admin`
   - `WAREHOUSE_MANAGER` → `/inventory`
   - `PHARMACIST` → `/pharmacist`
6. If the role is missing or unknown, stay on `/login` and show a simple error.

Do not redirect to `/` after a successful login.

## Auth Behavior

The dashboard is authenticated.

In `client/src/app/(dashboard)/layout.tsx`:

1. Read the `apharma_token` http-only cookie.
2. If the cookie is missing, redirect to `/login`.
3. Call backend `GET /auth/me` with:

```txt
Authorization: Bearer <token>
```

4. If `/auth/me` fails, redirect to `/login`.
5. If the user is returned, render the dashboard shell with that user.

Use Next.js `redirect` from `next/navigation`.

### Home redirect

Update `client/src/app/page.tsx` so `/` is not a dashboard page.

Behavior:

- If no auth cookie, redirect to `/login`.
- If the user is authenticated, redirect to that role's dashboard path from the table above.

`/` is only a fallback hop. Login itself must go straight to the role dashboard.

## Backend Addition

Add one small endpoint. Do not add overview statistics.

```txt
GET /auth/me
```

Behavior:

- Read the Bearer token from the `Authorization` header.
- Verify it with `verifyAuthToken`.
- Respond `200` with:

```json
{
  "userId": 1,
  "username": "admin_system",
  "role": "ADMIN"
}
```

- Respond `401` if the header is missing or the token is invalid.
- The JWT payload is enough. Do not query the database in this section.
- Do not add logout on the Express API in this section.

## Logout

Logout is frontend session cleanup only.

Extend `client/src/app/api/auth/session/route.ts` with `DELETE`:

1. Clear the `apharma_token` cookie.
2. Respond `200` with `{ "ok": true }`.

Top-bar avatar menu:

- show the logged-in username
- include a `Log out` action
- on click, call `DELETE /api/auth/session`
- then send the user to `/login`

Do not add a dedicated logout page.

## Layout

### Top navigation bar

Create a full-width top bar.

Required contents:

- **Left:** text logo `APHARMA`
- **Right:** user avatar with a dropdown that can log out

Follow that left/right placement exactly.

Suggested top-bar classes:

```txt
flex h-14 items-center justify-between border-b border-border bg-background px-4
```

Use shadcn `Avatar` and `DropdownMenu`.

### Left sidebar

Use the shadcn `Sidebar` component.

Sidebar buttons are generated from the logged-in `role`.

Keep labels beginner-readable. Use this nav map in `client/src/lib/nav.ts`:

| Role | Sidebar items |
| ---- | ------------- |
| `ADMIN` | Overview, Users, Inventory, Reports |
| `EXECUTIVE` | Overview, Reports |
| `WAREHOUSE_MANAGER` | Overview, Inventory, Batches |
| `SALES_REP` | Overview, Pharmacies, Doctors |
| `PHARMACIST` | Overview, Scan, Sales |

Each item needs a stable `id` such as `overview`, `users`, `inventory`.

Rules:

- Overview is always the first item.
- Overview is the default selected / highlighted item on each area Overview page.
- Clicking Overview navigates to that role's dashboard path (`/admin`, `/inventory`, and so on).
- Clicking any other item highlights it. Do not create extra folders for those items in this section. The right panel may show a short “coming later” note, or stay on Overview until a later spec adds the real nested route.
- Selected item uses theme tokens such as `bg-muted` and `text-foreground`.
- Inactive items use a quieter style such as ghost or muted text.

### Right content panel

The layout's right panel renders `{children}`.

For this section, each area page only needs the text `Overview`.

Later sections will replace that text with statistics loaded from the backend after the request sends the token and the user is authorized.

## Components

### 1. `client/src/app/(dashboard)/layout.tsx`

Server layout.

- Load the current user as described in Auth Behavior.
- Wrap children with the dashboard chrome.
- Pass `user` into the shell.

### 2. Area Overview pages

Each area `page.tsx` is a thin placeholder. Keep the body to the text `Overview`.

Do not fetch data. Do not add cards, charts, or tables unless needed for basic readable layout. Prefer a single heading or paragraph that says `Overview`.

### 3. `client/src/components/dashboard-shell.tsx`

Wrapper that composes:

- top bar
- sidebar
- right content panel

Suggested body layout:

```txt
flex min-h-screen flex-col bg-background
```

Below the top bar:

```txt
flex flex-1
```

### 4. `client/src/components/dashboard-topbar.tsx`

Top bar with `APHARMA` on the left and the user avatar on the right.

### 5. `client/src/components/dashboard-sidebar.tsx`

Role-based sidebar buttons. Overview is highlighted by default on each area Overview route.

### 6. `client/src/lib/server.ts`

Create a small server-side fetch helper if it does not already exist.

Required export:

- `serverApiFetch<T>(path: string, init?: RequestInit): Promise<T>`

Rules:

- Read base URL from `process.env.NEXT_PUBLIC_API_URL`
- Default base URL to `http://localhost:5000` if missing
- Attach `Authorization: Bearer <apharma_token>` when the cookie exists
- Do not store the JWT in `localStorage`

### 7. `client/src/lib/nav.ts`

Export:

- role-to-dashboard-path mapping
- role-to-sidebar-item map

The login form must use the same path mapping. Do not hard-code role paths in more than one place.

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

Layout guidance:

- top bar and sidebar use `border-border`
- content panel uses readable padding
- selected sidebar item uses theme tokens, not random colors

## Scope Limits

Do not build:

- overview statistics or other database reads
- real users, inventory, reports, scan, sales, or batches screens
- nested folders such as `inventory/batches`
- register or forgot-password pages
- Google OAuth
- JWT cookie changes on Express
- toast libraries
- complex permission engines beyond the nav map above

Those come later or are intentionally excluded.

## Verification

Run from `client/`:

```bash
npm run build
```

Then verify in the browser:

```txt
http://localhost:3000/login
```

Expected:

- Successful `ADMIN` login goes to `/admin`.
- Successful `WAREHOUSE_MANAGER` login goes to `/inventory`.
- Successful `PHARMACIST` login goes to `/pharmacist`.
- Login does not redirect to `/`.
- Unauthenticated visit to `/` redirects to `/login`.
- Top bar has `APHARMA` on the left and the avatar on the right.
- Sidebar buttons match the logged-in role.
- Overview is highlighted by default.
- Each of `/admin`, `/executive`, `/inventory`, `/sales`, and `/pharmacist` shows the text `Overview`.
- Clicking another sidebar button highlights it.
- Log out clears `apharma_token` and returns to `/login`.
- No `batches` folder exists under `inventory` yet.

## Tracker Update

After implementation, update `context/tracker.md`:

- Mark Section 05 as completed.
- Set next section to the first nested area or statistics section.
- Keep notes short.
- Mention that login now redirects to the role dashboard, and `(dashboard)` has Overview placeholders for admin, executive, inventory, sales, and pharmacist.
