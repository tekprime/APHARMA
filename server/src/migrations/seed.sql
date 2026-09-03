-- =============================================================================
-- SPECFORGE / IROMED ERP SYSTEM - DATA SEEDING SCRIPT
-- Target Engine: PostgreSQL (Version 15+)
-- Dialect: PostgreSQL
-- =============================================================================

-- Clean up any existing data in correct topological order to prevent constraint violations
TRUNCATE TABLE transactions, serialized_bottles, inventory_batches, erp_users, 
               pharmacies, doctors, distributors, regions, products, manufacturers, cities CASCADE;

-- -----------------------------------------------------------------------------
-- 1. SEED GEOGRAPHY MATRIX (Cities & Local Tracking Regions)
-- -----------------------------------------------------------------------------
INSERT INTO cities (city_id, city_name) VALUES 
(1, 'Damascus'), 
(2, 'Aleppo') 
ON CONFLICT (city_id) DO UPDATE SET city_name = EXCLUDED.city_name;

-- Reset SERIAL sequence counter for cities
SELECT setval('cities_city_id_seq', (SELECT MAX(city_id) FROM cities));

INSERT INTO regions (region_id, city_id, region_name) VALUES 
(1, 1, 'Shaalan'), 
(2, 1, 'Malki'), 
(3, 2, 'Shahbaa') 
ON CONFLICT (region_id) DO UPDATE SET region_name = EXCLUDED.region_name;

SELECT setval('regions_region_id_seq', (SELECT MAX(region_id) FROM regions));

-- -----------------------------------------------------------------------------
-- 2. SEED CORPORATE LOGISTICS PARTNERS (Distributors)
-- -----------------------------------------------------------------------------
INSERT INTO distributors (distributor_id, distributor_name, phone) VALUES 
(1, 'MedEx Syria', '+963-11-555111'), 
(2, 'Aleppo Logistics Group', '+963-21-555222') 
ON CONFLICT (distributor_id) DO UPDATE SET distributor_name = EXCLUDED.distributor_name;

SELECT setval('distributors_distributor_id_seq', (SELECT MAX(distributor_id) FROM distributors));

-- -----------------------------------------------------------------------------
-- 3. SEED HEALTHCARE INFRASTRUCTURE NODE ENTITIES (Doctors & Pharmacies)
-- -----------------------------------------------------------------------------
INSERT INTO doctors (doctor_id, region_id, doctor_name, specialty) VALUES 
(1, 1, 'Dr. Ahmad Mansour', 'Ophthalmologist'), 
(2, 2, 'Dr. Nour Al-Huda', 'Ophthalmologist'), 
(3, 3, 'Dr. Basil Jabri', 'General Practitioner')
ON CONFLICT (doctor_id) DO UPDATE SET doctor_name = EXCLUDED.doctor_name;

SELECT setval('doctors_doctor_id_seq', (SELECT MAX(doctor_id) FROM doctors));

-- Seed Pharmacies utilizing explicit uniform UUIDs for frontend deep link testing
INSERT INTO pharmacies (pharmacy_id, region_id, pharmacy_name, phone) VALUES 
('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 1, 'Al-Chifa Pharmacy', '+963-11-444111'),
('b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', 2, 'Ibn Sina Pharmacy', '+963-11-444222'),
('c2eebc99-9c0b-4ef8-bb6d-6bb9bd380a33', 3, 'Al-Razi Pharmacy', '+963-21-444333') 
ON CONFLICT (pharmacy_id) DO UPDATE SET pharmacy_name = EXCLUDED.pharmacy_name;

-- -----------------------------------------------------------------------------
-- 4. SEED SUPPLY CHAIN CATALOGUE (Manufacturers & Medical Drugs Catalogue)
-- -----------------------------------------------------------------------------
INSERT INTO manufacturers (manufacturer_id, manufacturer_name, country_of_origin) VALUES 
(1, 'Iromed S.r.l.', 'Italy'),
(2, 'Bayer AG', 'Germany'),
(3, 'Novartis International AG', 'Switzerland')
ON CONFLICT (manufacturer_id) DO UPDATE SET manufacturer_name = EXCLUDED.manufacturer_name;

SELECT setval('manufacturers_manufacturer_id_seq', (SELECT MAX(manufacturer_id) FROM manufacturers));

INSERT INTO products (product_id, manufacturer_id, product_name, scientific_name, dosage_form, strength, barcode_prefix) VALUES 
(1, 1, 'Iromed Eye Drops', 'Sodium Hyaluronate 0.4%', 'Drops', '0.4%', '8012345'),
(2, 2, 'Aspirin Cardio', 'Acetylsalicylic Acid', 'Tablet', '100mg', '4005678'),
(3, 3, 'Voltaren Emulgel', 'Diclofenac Diethylamine', 'Ointment', '1%', '7611234')
ON CONFLICT (product_id) DO UPDATE SET product_name = EXCLUDED.product_name;

SELECT setval('products_product_id_seq', (SELECT MAX(product_id) FROM products));

-- -----------------------------------------------------------------------------
-- 5. SEED SECURITY ACCOUNTS MATRIX (ERP Users with pre-baked Bcrypt Hashes)
-- admin_system uses the provided bcrypt hash.
-- Other users use a bcrypt hash of: "password123"
-- -----------------------------------------------------------------------------
INSERT INTO erp_users (user_id, username, email, password_hash, role, assigned_region_id) VALUES 
(1, 'admin_system', 'admin@specforge.com', '$2b$10$f38wQshB0iRE91b1wJ1gkuGfRptE78kZ1qU5N6Y9IomXUv1Uv1mUi', 'ADMIN', NULL),
(2, 'anas_director', 'ceo@specforge.com', '$2b$10$0JMQpBvqs7ZkD94qLYqnsO5dsc2hoD3yJIL4Sx2WsMVNO36R8AzzO', 'EXECUTIVE', NULL),
(3, 'khaled_logistics', 'warehouse@specforge.com', '$2b$10$0JMQpBvqs7ZkD94qLYqnsO5dsc2hoD3yJIL4Sx2WsMVNO36R8AzzO', 'WAREHOUSE_MANAGER', 1),
(4, 'rami_rep', 'sales@specforge.com', '$2b$10$0JMQpBvqs7ZkD94qLYqnsO5dsc2hoD3yJIL4Sx2WsMVNO36R8AzzO', 'SALES_REP', 2),
(5, 'chifa_pharmacist', 'pharmacist@specforge.com', '$2b$10$0JMQpBvqs7ZkD94qLYqnsO5dsc2hoD3yJIL4Sx2WsMVNO36R8AzzO', 'PHARMACIST', 1)
ON CONFLICT (user_id) DO UPDATE SET password_hash = EXCLUDED.password_hash;

SELECT setval('erp_users_user_id_seq', (SELECT MAX(user_id) FROM erp_users));

-- -----------------------------------------------------------------------------
-- 6. SEED LOGISTICS & ITEM INVENTORY MATRIX (Active Operational Cargo Batches)
-- -----------------------------------------------------------------------------
INSERT INTO inventory_batches (batch_id, product_id, batch_number, manufacturing_date, expiry_date, total_imported_qty, customs_status) VALUES 
(1, 1, 'IRM-2026-B09', '2026-06-01', '2029-06-01', 5, 'CLEARED'),
(2, 2, 'BAY-2026-A12', '2026-08-15', '2030-08-15', 5, 'CLEARED')
ON CONFLICT (batch_id) DO UPDATE SET batch_number = EXCLUDED.batch_number;

SELECT setval('inventory_batches_batch_id_seq', (SELECT MAX(batch_id) FROM inventory_batches));

-- -----------------------------------------------------------------------------
-- 7. SEED SERIALIZED BOTTLES ITEM TRACKING LEDGER (Individual Barcodes)
-- -----------------------------------------------------------------------------
INSERT INTO serialized_bottles (bottle_serial_id, batch_id, current_holder_type, distributor_id, pharmacy_id) VALUES 
('IRM-BOT-0994821', 1, 'MAIN_WAREHOUSE', NULL, NULL),
('IRM-BOT-0994822', 1, 'DISTRIBUTOR', 1, NULL),
('IRM-BOT-0994823', 1, 'PHARMACY', NULL, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'),
('IRM-BOT-0994824', 1, 'PHARMACY', NULL, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'),
('IRM-BOT-0994825', 1, 'SOLD', NULL, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'),
('BAY-ASP-7741001', 2, 'MAIN_WAREHOUSE', NULL, NULL),
('BAY-ASP-7741002', 2, 'DISTRIBUTOR', 2, NULL),
('BAY-ASP-7741003', 2, 'PHARMACY', NULL, 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22'),
('BAY-ASP-7741004', 2, 'PHARMACY', NULL, 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22'),
('BAY-ASP-7741005', 2, 'SOLD', NULL, 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22')
ON CONFLICT (bottle_serial_id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- 8. SEED UNIFIED SALES HISTORIES (Transactions Records)
-- -----------------------------------------------------------------------------
INSERT INTO transactions (transaction_id, pharmacy_id, distributor_id, doctor_id, bottle_serial_id, quantity_sold) VALUES 
(1, 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 1, 1, 'IRM-BOT-0994825', 1),
(2, 'b1eebc99-9c0b-4ef8-bb6d-6bb9bd380a22', 2, 2, 'BAY-ASP-7741005', 1)
ON CONFLICT (transaction_id) DO NOTHING;

SELECT setval('transactions_transaction_id_seq', (SELECT MAX(transaction_id) FROM transactions));
