# Section 02 — Database and Migrations

## Goal
Add the PostgreSQL data core foundation for the multi-manufacturer, multi-drug Iromed ERP system. This section must make the local database container usable, instantiate our 9 core tracking tables, and provide a repeatable, transactional TypeScript migration runner script.

## Current State
Assume Section 01 is already completed. 
The project workspace already has:
- `client/` created manually with Next.js and Tailwind CSS
- `server/` created manually with `package.json`, `tsconfig.json`, and `src/` foundations
- Minimal Express backend foundation and `/health` route verified from Section 01
- An empty root `docker-compose.yml` file already present
- Cursor project rules initialized in `.cursorrules`
- `context/tracker.md` active

## Scope
Build only the relational database foundation, container environment, and schema initialization.
Do not add:
- Auth or login frontend pages
- JWT authentication middleware guards
- Master batch drag-and-drop CSV parser logic
- Sales territory reporting views or prescription lookup endpoints
- Pharmacist 3-tap counter POS components

## Files to Create or Update
Allowed root file:
- `docker-compose.yml`

Allowed backend files (Whitelist):
- `server/package.json`
- `server/.env.example`
- `server/src/db/pool.ts`
- `server/src/db/migrate.ts`
- `server/src/migrations/001_init_schema.sql`

Allowed tracking file:
- `context/tracker.md`

Strict Blacklist: Do not modify any files inside the `/client` directory.

## Implementation Requirements

### 1. PostgreSQL Docker Compose Configuration
Update the root `docker-compose.yml` file so it runs our isolated relational database container.
Use these parameters:
- service name: `postgres`
- image: `postgres:16-alpine`
- container name: `apharma_postgres`
- database: `apharma_local_db`
- user: `apharma_admin`
- password: `LocalDevPass123!`
- port: `5432:5432`
- named volume: `pg_data` mapped to `/var/lib/postgresql/data` for persistent safety
Keep this file simple. Do not add backend api or frontend application boxes yet.

### 2. Backend Environment Configuration Example
Create or update `server/.env.example` with only the connection keys needed so far:
```env
PORT=5000
DATABASE_URL=postgresql://apharma_admin:LocalDevPass123!@localhost:5432/apharma_local_db
FRONTEND_URL=http://localhost:3000
```
Do not append JWT secret keys or third-party notification keys yet.

### 3. Backend Package Dependencies Update
Update `server/package.json` carefully.
Add database driver libraries only if missing:
- `pg`
Add TypeScript/development type-definitions only if missing:
- `@types/pg`
Add a dedicated task runner script:
```json
"migrate": "tsx src/db/migrate.ts"
```
Preserve all existing scripts from Section 01. Do not overwrite or clear dependencies unnecessarily.

### 4. Shared Database Pool Engine
Create `server/src/db/pool.ts`.
Requirements:
- Import `Pool` natively from `pg`.
- Read `DATABASE_URL` directly from `process.env.DATABASE_URL`.
- Throw an explicit structural error if the database connection string is completely missing.
- Export a single shared `Pool` instance.
- Keep the code footprint small; do not introduce abstract ORMs or data-repository models yet.

### 5. Transactional Migration Runner Script
Create `server/src/db/migrate.ts`.
Requirements:
- Load system environment variables using `dotenv/config`.
- Create a structural `_migrations` tracking schema table if it does not exist.
- Read raw `.sql` files from the directory `src/migrations/`.
- Sort all discovered migration script names alphabetically to ensure sequential table loading.
- Skip execution for filenames already safely logged inside the `_migrations` table registry.
- Wrap individual migration scripts inside SQL `BEGIN` and `COMMIT` transactions to ensure database consistency.
- Log each newly applied schema filename to the terminal log.
- Close the database pool handle at the conclusion of the execution sequence.
- Exit with a non-zero code (`process.exit(1)`) if any table generation throws an error.

### 6. Master Schema Migration Asset Configuration
Create exactly one unified SQL migration schema asset file at:
`server/src/migrations/001_init_schema.sql`

Write clean, raw PostgreSQL DDL scripts to execute the following relational structural architecture block exactly as written:

```sql
-- Enable uuid module for primary keys
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create multi-role security enum
CREATE TYPE user_role_enum AS ENUM ('ADMIN', 'EXECUTIVE', 'WAREHOUSE_MANAGER', 'SALES_REP', 'PHARMACIST');

-- 1. Cities Table
CREATE TABLE IF NOT EXISTS cities (
    city_id SERIAL PRIMARY KEY,
    city_name VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Regions Table
CREATE TABLE IF NOT EXISTS regions (
    region_id SERIAL PRIMARY KEY,
    city_id INT NOT NULL REFERENCES cities(city_id) ON DELETE CASCADE,
    region_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_city_region UNIQUE(city_id, region_name)
);

-- 3. Distributors Table
CREATE TABLE IF NOT EXISTS distributors (
    distributor_id SERIAL PRIMARY KEY,
    distributor_name VARCHAR(150) NOT NULL UNIQUE,
    phone VARCHAR(30),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Pharmacies Table (Using secure UUIDs for dynamic QR URL parameters)
CREATE TABLE IF NOT EXISTS pharmacies (
    pharmacy_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    region_id INT REFERENCES regions(region_id) ON DELETE SET NULL,
    pharmacy_name VARCHAR(150) NOT NULL,
    phone VARCHAR(30),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 5. Doctors Table
CREATE TABLE IF NOT EXISTS doctors (
    doctor_id SERIAL PRIMARY KEY,
    region_id INT REFERENCES regions(region_id) ON DELETE SET NULL,
    doctor_name VARCHAR(150) NOT NULL,
    specialty VARCHAR(100) DEFAULT 'Ophthalmologist',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 6. Manufacturers Table
CREATE TABLE IF NOT EXISTS manufacturers (
    manufacturer_id SERIAL PRIMARY KEY,
    manufacturer_name VARCHAR(150) NOT NULL UNIQUE,
    country_of_origin VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 7. Products Catalogue Table
CREATE TABLE IF NOT EXISTS products (
    product_id SERIAL PRIMARY KEY,
    manufacturer_id INT NOT NULL REFERENCES manufacturers(manufacturer_id) ON DELETE RESTRICT,
    product_name VARCHAR(150) NOT NULL,
    scientific_name VARCHAR(255) NOT NULL,
    dosage_form VARCHAR(100) DEFAULT 'Drops',
    strength VARCHAR(50) NOT NULL,
    barcode_prefix VARCHAR(20) UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_manufacturer_product UNIQUE(manufacturer_id, product_name)
);

-- 8. Inventory Batches Table
CREATE TABLE IF NOT EXISTS inventory_batches (
    batch_id SERIAL PRIMARY KEY,
    product_id INT NOT NULL REFERENCES products(product_id) ON DELETE RESTRICT,
    batch_number VARCHAR(50) NOT NULL UNIQUE,
    manufacturing_date DATE NOT NULL,
    expiry_date DATE NOT NULL,
    total_imported_qty INT NOT NULL CHECK (total_imported_qty > 0),
    customs_status VARCHAR(50) DEFAULT 'In Transit',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 9. Serialized Bottles Tracking Ledger (Per-unit tracking)
CREATE TABLE IF NOT EXISTS serialized_bottles (
    bottle_serial_id VARCHAR(100) PRIMARY KEY,
    batch_id INT NOT NULL REFERENCES inventory_batches(batch_id) ON DELETE RESTRICT,
    current_holder_type VARCHAR(50) NOT NULL DEFAULT 'MAIN_WAREHOUSE',
    distributor_id INT REFERENCES distributors(distributor_id) ON DELETE SET NULL,
    pharmacy_id UUID REFERENCES pharmacies(pharmacy_id) ON DELETE SET NULL,
    scanned_at_pharmacy_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 10. Transactions Unified Ledger
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id SERIAL PRIMARY KEY,
    pharmacy_id UUID NOT NULL REFERENCES pharmacies(pharmacy_id) ON DELETE RESTRICT,
    distributor_id INT NOT NULL REFERENCES distributors(distributor_id) ON DELETE RESTRICT,
    doctor_id INT REFERENCES doctors(doctor_id) ON DELETE SET NULL,
    bottle_serial_id VARCHAR(100) REFERENCES serialized_bottles(bottle_serial_id) ON DELETE SET NULL,
    quantity_sold INT NOT NULL CHECK (quantity_sold > 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 11. Security Access Accounts Matrix Table
CREATE TABLE IF NOT EXISTS erp_users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role user_role_enum NOT NULL DEFAULT 'PHARMACIST',
    assigned_region_id INT REFERENCES regions(region_id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

## Verification Steps

After Cursor implements this section, run:

```bash
cd server
npm install
```

Then start PostgreSQL from the project root:

```bash
docker compose up -d
```

Then run migrations:

```bash
cd server
npm run migrate
```

Expected result:

- PostgreSQL container starts
- migration runner logs the three migration files
- running `npm run migrate` again skips already-run migrations
- existing `/health` route from Section 01 still works

## Tracker Update

Update `context/tracker.md` after completion.

Use a short update only:

- mark Section 02 as completed
- set current/next section to Section 03 — Auth JWT Backend
- mention that PostgreSQL, DB pool, migration runner, and three migrations are ready
- list known issues only if any exist
