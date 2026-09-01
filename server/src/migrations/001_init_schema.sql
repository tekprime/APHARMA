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
