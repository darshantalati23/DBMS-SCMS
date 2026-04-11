-- ============================================================
-- SCMS POPULATION SCRIPT — Lab Group 05 | IT214 Milestone 3
-- ============================================================

SET search_path TO scms;

-- ============================================================
-- SECTION 1 | WAREHOUSE (5 warehouses)
-- ============================================================
INSERT INTO warehouse (warehouse_code, warehouse_name, warehouse_type, city, state, pincode, total_capacity_sqft, temperature_controlled, is_active) VALUES
('WH-MUM-01', 'Mumbai Central Hub',        'central',      'Mumbai',      'Maharashtra', '400001', 120000, FALSE, TRUE),
('WH-DEL-01', 'Delhi Regional Depot',       'regional',     'New Delhi',   'Delhi',       '110001', 80000,  FALSE, TRUE),
('WH-BLR-01', 'Bengaluru Cold Storage',     'cold_storage', 'Bengaluru',   'Karnataka',   '560001', 45000,  TRUE,  TRUE),
('WH-AHM-01', 'Ahmedabad Transit Hub',      'transit_hub',  'Ahmedabad',   'Gujarat',     '380001', 30000,  FALSE, TRUE),
('WH-HYD-01', 'Hyderabad Regional Depot',   'regional',     'Hyderabad',   'Telangana',   '500001', 60000,  FALSE, TRUE);

-- ============================================================
-- SECTION 2 | STAFF (20 staff members across warehouses)
-- ============================================================
INSERT INTO staff (warehouse_id, employee_code, full_name, role, email, phone, is_active, last_login) VALUES
-- Mumbai Central
(1, 'EMP-001', 'Rajesh Kumar',       'admin',                   'rajesh.kumar@scms.in',       '9810012345', TRUE,  '2025-04-08 09:15:00'),
(1, 'EMP-002', 'Priya Sharma',       'procurement_manager',     'priya.sharma@scms.in',       '9810012346', TRUE,  '2025-04-08 08:45:00'),
(1, 'EMP-003', 'Amit Desai',         'warehouse_operator',      'amit.desai@scms.in',         '9810012347', TRUE,  '2025-04-07 17:30:00'),
(1, 'EMP-004', 'Sneha Patil',        'sales_executive',         'sneha.patil@scms.in',        '9810012348', TRUE,  '2025-04-08 10:00:00'),
(1, 'EMP-005', 'Vikram Mehta',       'auditor',                 'vikram.mehta@scms.in',       '9810012349', TRUE,  '2025-04-06 14:00:00'),
-- Delhi Regional
(2, 'EMP-006', 'Ananya Singh',       'procurement_manager',     'ananya.singh@scms.in',       '9910012345', TRUE,  '2025-04-08 09:00:00'),
(2, 'EMP-007', 'Rohit Gupta',        'warehouse_operator',      'rohit.gupta@scms.in',        '9910012346', TRUE,  '2025-04-08 07:30:00'),
(2, 'EMP-008', 'Kavitha Reddy',      'sales_executive',         'kavitha.reddy@scms.in',      '9910012347', TRUE,  '2025-04-08 11:00:00'),
(2, 'EMP-009', 'Manish Agarwal',     'logistics_coordinator',   'manish.agarwal@scms.in',     '9910012348', TRUE,  '2025-04-07 16:45:00'),
-- Bengaluru Cold Storage
(3, 'EMP-010', 'Divya Nair',         'warehouse_operator',      'divya.nair@scms.in',         '8010012345', TRUE,  '2025-04-08 08:00:00'),
(3, 'EMP-011', 'Suresh Iyer',        'procurement_manager',     'suresh.iyer@scms.in',        '8010012346', TRUE,  '2025-04-08 09:30:00'),
(3, 'EMP-012', 'Meera Krishnan',     'logistics_coordinator',   'meera.krishnan@scms.in',     '8010012347', TRUE,  '2025-04-07 18:00:00'),
-- Ahmedabad Transit Hub
(4, 'EMP-013', 'Hardik Patel',       'warehouse_operator',      'hardik.patel@scms.in',       '9510012345', TRUE,  '2025-04-08 06:45:00'),
(4, 'EMP-014', 'Jinal Shah',         'logistics_coordinator',   'jinal.shah@scms.in',         '9510012346', TRUE,  '2025-04-08 07:15:00'),
-- Hyderabad Regional
(5, 'EMP-015', 'Srinivas Rao',       'procurement_manager',     'srinivas.rao@scms.in',       '7010012345', TRUE,  '2025-04-08 09:45:00'),
(5, 'EMP-016', 'Lakshmi Devi',       'sales_executive',         'lakshmi.devi@scms.in',       '7010012346', TRUE,  '2025-04-08 10:30:00'),
(5, 'EMP-017', 'Charan Kumar',       'warehouse_operator',      'charan.kumar@scms.in',       '7010012347', TRUE,  '2025-04-07 15:00:00'),
-- Central (no warehouse assignment)
(NULL, 'EMP-018', 'Deepak Joshi',    'admin',                   'deepak.joshi@scms.in',       '9000012345', TRUE,  '2025-04-08 08:30:00'),
(NULL, 'EMP-019', 'Nisha Verma',     'auditor',                 'nisha.verma@scms.in',        '9000012346', TRUE,  '2025-04-07 17:00:00'),
(1,    'EMP-020', 'Arun Tiwari',     'logistics_coordinator',   'arun.tiwari@scms.in',        '9810099999', TRUE,  '2025-04-08 08:00:00');

-- ============================================================
-- SECTION 3 | SUPPLIER (10 suppliers)
-- ============================================================
INSERT INTO supplier (supplier_code, company_name, contact_person, email, phone, gstin, city, state, country, credit_limit, payment_terms_days, supplier_tier, on_time_delivery_rate, quality_rejection_rate, is_active) VALUES
('SUP-001', 'Hindustan Unilever Ltd',          'Rahul Bajaj',      'rahul.bajaj@hul.com',       '2212345601', '27AAACH0209R1ZA', 'Mumbai',    'Maharashtra', 'India', 5000000.00, 30,  'strategic',  96.5, 1.2,  TRUE),
('SUP-002', 'ITC Limited',                     'Sunil Kapoor',     'sunil.kapoor@itc.in',       '3312345602', '19AAACI3240J1ZK', 'Kolkata',   'West Bengal', 'India', 4000000.00, 45,  'strategic',  94.0, 2.1,  TRUE),
('SUP-003', 'Dabur India Ltd',                 'Kavita Madan',     'kavita.madan@dabur.com',    '1112345603', '07AAACD1391K1ZS', 'Ghaziabad', 'Uttar Pradesh','India',3000000.00, 30,  'preferred',  91.5, 3.4,  TRUE),
('SUP-004', 'Godrej Consumer Products',        'Vivek Sharma',     'vivek.s@godrejcp.com',      '2212345604', '27AAACG1234K1ZP', 'Mumbai',    'Maharashtra', 'India', 3500000.00, 30,  'preferred',  89.0, 4.8,  TRUE),
('SUP-005', 'Marico Industries',               'Anjali Gupta',     'anjali.g@marico.com',       '2212345605', '27AAACM0765K1ZD', 'Mumbai',    'Maharashtra', 'India', 2500000.00, 45,  'preferred',  93.2, 2.7,  TRUE),
('SUP-006', 'Patanjali Ayurved Ltd',           'Ravi Shankar',     'ravi.s@patanjali.com',      '1351234566', '05AAACPA234K1ZX', 'Haridwar',  'Uttarakhand', 'India', 1500000.00, 30,  'approved',   85.0, 6.0,  TRUE),
('SUP-007', 'Emami Limited',                   'Sushil Goenka',    'sushil.g@emami.com',        '3312345607', '19AAACE1234K1ZM', 'Kolkata',   'West Bengal', 'India', 2000000.00, 45,  'approved',   88.5, 5.1,  TRUE),
('SUP-008', 'Cipla Ltd',                       'Dr. Anil Sood',    'anil.sood@cipla.com',       '2212345608', '27AAACC1234K1ZQ', 'Mumbai',    'Maharashtra', 'India', 6000000.00, 60,  'strategic',  97.8, 0.8,  TRUE),
('SUP-009', 'Sun Pharmaceutical',              'Dr. Rekha Menon',  'rekha.m@sunpharma.com',     '2212345609', '27AAACS1234K1ZT', 'Mumbai',    'Maharashtra', 'India', 7000000.00, 60,  'strategic',  98.2, 0.5,  TRUE),
('SUP-010', 'Reckitt Benckiser India',         'Gaurav Singhania',  'gaurav.s@rb.com',           '1241234510', '24AAACRB234K1ZV', 'Ahmedabad', 'Gujarat',     'India', 2800000.00, 30,  'preferred',  90.5, 3.9,  FALSE);

-- ============================================================
-- SECTION 4 | PRODUCT CATEGORY (hierarchical)
-- ============================================================
INSERT INTO product_category (category_name, parent_category_id, description) VALUES
('FMCG',              NULL, 'Fast Moving Consumer Goods — top-level category'),
('Pharma',            NULL, 'Pharmaceutical products — top-level category'),
('Personal Care',     1,    'Soaps, shampoos, skin care under FMCG'),
('Food & Beverage',   1,    'Packaged food, drinks, snacks under FMCG'),
('Home Care',         1,    'Cleaning, dishwash, laundry under FMCG'),
('OTC Medicines',     2,    'Over-the-counter drugs and supplements'),
('Prescription Drugs',2,    'Rx-only medications — cold-storage eligible'),
('Hair Care',         3,    'Shampoos, conditioners, oils under Personal Care'),
('Skin Care',         3,    'Moisturisers, face wash, sunscreen under Personal Care'),
('Oral Care',         3,    'Toothpaste, mouthwash under Personal Care'),
('Snacks',            4,    'Biscuits, chips, namkeen under Food & Beverage'),
('Beverages',         4,    'Juices, health drinks under Food & Beverage'),
('Laundry',           5,    'Detergents, fabric softeners under Home Care'),
('Surface Care',      5,    'Floor cleaners, toilet cleaners under Home Care');

-- ============================================================
-- SECTION 5 | PRODUCT (30 SKUs)
-- ============================================================
INSERT INTO product (category_id, sku_code, product_name, unit_of_measure, is_perishable, shelf_life_days, standard_cost, reorder_point, reorder_quantity, weight_kg, is_active) VALUES
-- Hair Care (cat 8)
(8,  'SKU-HC-001', 'Dove Shampoo 200ml',             'Unit',  FALSE, 730,  62.00,  500, 1000, 0.220, TRUE),
(8,  'SKU-HC-002', 'Pantene Pro-V Conditioner 180ml','Unit',  FALSE, 730,  78.00,  300, 600,  0.195, TRUE),
(8,  'SKU-HC-003', 'Marico Parachute Coconut Oil 500ml','Unit',FALSE,1095, 110.00, 400, 800,  0.520, TRUE),
(8,  'SKU-HC-004', 'Dabur Amla Hair Oil 300ml',      'Unit',  FALSE, 1095, 85.00,  350, 700,  0.325, TRUE),
-- Skin Care (cat 9)
(9,  'SKU-SC-001', 'Vaseline Body Lotion 200ml',     'Unit',  FALSE, 1095, 95.00,  400, 800,  0.215, TRUE),
(9,  'SKU-SC-002', 'Nivea Soft Moisturiser 100ml',   'Unit',  FALSE, 1095, 88.00,  300, 600,  0.110, TRUE),
(9,  'SKU-SC-003', 'Lakme Sun Expert SPF50 100ml',   'Unit',  FALSE, 730,  145.00, 200, 400,  0.105, TRUE),
(9,  'SKU-SC-004', 'Garnier Men Facewash 100g',      'Unit',  FALSE, 730,  72.00,  300, 600,  0.105, TRUE),
-- Oral Care (cat 10)
(10, 'SKU-OC-001', 'Colgate Strong Teeth 200g',      'Unit',  FALSE, 1095, 48.00,  600, 1200, 0.205, TRUE),
(10, 'SKU-OC-002', 'Pepsodent Germicheck 150g',      'Unit',  FALSE, 1095, 42.00,  500, 1000, 0.155, TRUE),
(10, 'SKU-OC-003', 'Listerine Cool Mint 250ml',      'Unit',  FALSE, 730,  115.00, 250, 500,  0.265, TRUE),
-- Snacks (cat 11)
(11, 'SKU-SN-001', 'Britannia Good Day Biscuits 100g','Unit', TRUE,  180,  18.00,  800, 2000, 0.105, TRUE),
(11, 'SKU-SN-002', 'Lay''s Classic Salted Chips 52g', 'Unit',  TRUE,  120,  15.00,  600, 1500, 0.055, TRUE),
(11, 'SKU-SN-003', 'Haldirams Bhujia 400g',          'Unit',  TRUE,  270,  68.00,  400, 1000, 0.410, TRUE),
-- Beverages (cat 12)
(12, 'SKU-BV-001', 'Tropicana Orange Juice 1L',      'Unit',  TRUE,  90,   75.00,  300, 800,  1.050, TRUE),
(12, 'SKU-BV-002', 'Bournvita Health Drink 500g',    'Unit',  FALSE, 365,  210.00, 200, 500,  0.520, TRUE),
(12, 'SKU-BV-003', 'Real Fruit Power Mixed 1L',      'Unit',  TRUE,  90,   72.00,  300, 700,  1.050, TRUE),
-- Laundry (cat 13)
(13, 'SKU-LN-001', 'Surf Excel Quick Wash 1kg',      'Unit',  FALSE, 1095, 125.00, 400, 1000, 1.010, TRUE),
(13, 'SKU-LN-002', 'Ariel Matic Powder 2kg',         'Unit',  FALSE, 1095, 235.00, 300, 700,  2.020, TRUE),
(13, 'SKU-LN-003', 'Comfort Fabric Conditioner 800ml','Unit', FALSE, 730,  118.00, 250, 600,  0.840, TRUE),
-- Surface Care (cat 14)
(14, 'SKU-SFC-001','Lizol Surface Cleaner 1L',       'Unit',  FALSE, 730,  145.00, 300, 700,  1.060, TRUE),
(14, 'SKU-SFC-002','Harpic Power Plus 1L',           'Unit',  FALSE, 730,  138.00, 300, 700,  1.060, TRUE),
-- OTC Medicines (cat 6)
(6,  'SKU-OTC-001','Crocin Advance 500mg Strip 15',  'Strip', FALSE, 730,  32.00,  500, 1500, 0.020, TRUE),
(6,  'SKU-OTC-002','Vicks VapoRub 50g',              'Unit',  FALSE, 1095, 78.00,  300, 800,  0.055, TRUE),
(6,  'SKU-OTC-003','Digene Antacid Gel 200ml',       'Unit',  FALSE, 730,  65.00,  300, 700,  0.215, TRUE),
(6,  'SKU-OTC-004','Dolo 650mg Strip 15',            'Strip', FALSE, 730,  28.00,  600, 2000, 0.018, TRUE),
-- Prescription Drugs (cat 7) — cold storage
(7,  'SKU-RX-001', 'Azithromycin 500mg Strip 3',     'Strip', TRUE,  365,  85.00,  200, 600,  0.012, TRUE),
(7,  'SKU-RX-002', 'Metformin 500mg Strip 15',       'Strip', TRUE,  730,  45.00,  300, 1000, 0.025, TRUE),
(7,  'SKU-RX-003', 'Atorvastatin 10mg Strip 15',     'Strip', TRUE,  730,  62.00,  250, 800,  0.020, TRUE),
(7,  'SKU-RX-004', 'Pantoprazole 40mg Strip 15',     'Strip', TRUE,  730,  55.00,  250, 800,  0.022, TRUE);
-- ============================================================
-- SECTION 6 | SUPPLIES — Supplier × Product pricing contracts
-- (25 contracts across suppliers and products)
-- ============================================================
INSERT INTO supplies (supplier_id, product_id, unit_price, currency, minimum_order_qty, lead_time_days, price_valid_from, price_valid_until, is_preferred_supplier) VALUES
-- HUL → Hair Care & Skin Care & Oral Care
(1,  1,  58.00,  'INR', 200, 7,  '2024-01-01', '2025-12-31', TRUE),
(1,  5,  90.00,  'INR', 200, 7,  '2024-01-01', '2025-12-31', TRUE),
(1,  9,  45.00,  'INR', 500, 7,  '2024-01-01', '2025-12-31', TRUE),
(1,  18, 118.00, 'INR', 300, 10, '2024-01-01', '2025-12-31', FALSE),
-- ITC → Snacks & Beverages
(2,  12, 16.00,  'INR', 1000,5,  '2024-01-01', '2025-12-31', TRUE),
(2,  13, 13.50,  'INR', 1000,5,  '2024-01-01', '2025-12-31', TRUE),
(2,  14, 63.00,  'INR', 500, 7,  '2024-01-01', '2025-12-31', TRUE),
(2,  15, 70.00,  'INR', 300, 7,  '2024-01-01', '2025-12-31', FALSE),
-- Dabur → Hair Care & OTC
(3,  4,  80.00,  'INR', 300, 10, '2024-01-01', '2025-12-31', TRUE),
(3,  24, 30.00,  'INR', 500, 7,  '2024-01-01', '2025-12-31', TRUE),
(3,  25, 72.00,  'INR', 300, 7,  '2024-01-01', '2025-12-31', TRUE),
(3,  26, 60.00,  'INR', 500, 7,  '2024-01-01', '2025-12-31', TRUE),
-- Godrej → Skin Care & Home Care
(4,  6,  82.00,  'INR', 200, 10, '2024-01-01', '2025-12-31', TRUE),
(4,  8,  68.00,  'INR', 300, 10, '2024-01-01', '2025-12-31', TRUE),
(4,  20, 112.00, 'INR', 300, 10, '2024-01-01', '2025-12-31', TRUE),
-- Marico → Hair Care
(5,  3,  105.00, 'INR', 400, 7,  '2024-01-01', '2025-12-31', TRUE),
(5,  1,  60.00,  'INR', 200, 7,  '2024-04-01', '2026-03-31', FALSE),
-- Patanjali → OTC & Oral Care
(6,  10, 38.00,  'INR', 500, 12, '2024-01-01', '2025-12-31', FALSE),
(6,  26, 56.00,  'INR', 500, 12, '2024-01-01', '2025-12-31', FALSE),
-- Cipla → Rx Drugs
(8,  27, 78.00,  'INR', 200, 14, '2024-01-01', '2025-12-31', TRUE),
(8,  28, 40.00,  'INR', 300, 14, '2024-01-01', '2025-12-31', TRUE),
(8,  29, 58.00,  'INR', 250, 14, '2024-01-01', '2025-12-31', TRUE),
-- Sun Pharma → Rx Drugs (competing + additional)
(9,  27, 80.00,  'INR', 200, 10, '2024-04-01', '2026-03-31', FALSE),
(9,  29, 55.00,  'INR', 250, 10, '2024-01-01', '2025-12-31', FALSE),
(9,  30, 50.00,  'INR', 250, 10, '2024-01-01', '2025-12-31', TRUE);

-- ============================================================
-- SECTION 7 | WAREHOUSE ZONE (4–5 zones per warehouse = 22 zones)
-- ============================================================
INSERT INTO warehouse_zone (warehouse_id, zone_code, zone_type, capacity_units, temperature_zone, is_active) VALUES
-- WH-MUM-01 (5 zones)
(1, 'MUM-RCV-A', 'receiving',   500,  'ambient',     TRUE),
(1, 'MUM-STG-A', 'storage',     3000, 'ambient',     TRUE),
(1, 'MUM-STG-B', 'storage',     2000, 'ambient',     TRUE),
(1, 'MUM-PCK-A', 'picking',     800,  'ambient',     TRUE),
(1, 'MUM-DSP-A', 'dispatch',    600,  'ambient',     TRUE),
-- WH-DEL-01 (5 zones)
(2, 'DEL-RCV-A', 'receiving',   400,  'ambient',     TRUE),
(2, 'DEL-STG-A', 'storage',     2000, 'ambient',     TRUE),
(2, 'DEL-STG-B', 'storage',     1500, 'ambient',     TRUE),
(2, 'DEL-PCK-A', 'picking',     600,  'ambient',     TRUE),
(2, 'DEL-DSP-A', 'dispatch',    400,  'ambient',     TRUE),
-- WH-BLR-01 Cold Storage (5 zones — temp controlled)
(3, 'BLR-RCV-C', 'receiving',   200,  'cold_2_8',    TRUE),
(3, 'BLR-STG-C', 'storage',     1200, 'cold_2_8',    TRUE),
(3, 'BLR-STG-F', 'storage',     800,  'frozen_-18',  TRUE),
(3, 'BLR-PCK-C', 'picking',     300,  'cold_2_8',    TRUE),
(3, 'BLR-QRN-C', 'quarantine',  150,  'cold_2_8',    TRUE),
-- WH-AHM-01 Transit Hub (4 zones)
(4, 'AHM-RCV-A', 'receiving',   300,  'ambient',     TRUE),
(4, 'AHM-STG-A', 'storage',     800,  'ambient',     TRUE),
(4, 'AHM-PCK-A', 'picking',     400,  'ambient',     TRUE),
(4, 'AHM-DSP-A', 'dispatch',    500,  'ambient',     TRUE),
-- WH-HYD-01 (5 zones)
(5, 'HYD-RCV-A', 'receiving',   350,  'ambient',     TRUE),
(5, 'HYD-STG-A', 'storage',     1800, 'ambient',     TRUE),
(5, 'HYD-STG-B', 'storage',     1200, 'ambient',     TRUE),
(5, 'HYD-PCK-A', 'picking',     500,  'ambient',     TRUE),
(5, 'HYD-DSP-A', 'dispatch',    400,  'ambient',     TRUE);

-- ============================================================
-- SECTION 8 | PURCHASE ORDER (15 POs across warehouses)
-- ============================================================
INSERT INTO purchase_order (po_number, supplier_id, warehouse_id, created_by, approved_by, po_status, order_date, expected_delivery_date, actual_delivery_date, received_by, grn_status, rejection_reason, payment_terms, payment_status, total_amount) VALUES
-- Fully received POs
('PO-2025-0001', 1, 1, 2,  1,  'fully_received',     '2025-01-10', '2025-01-17', '2025-01-16', 3,  'putaway_done', NULL,                           'Net 30',  'paid',            243600.00),
('PO-2025-0002', 2, 2, 6,  18, 'fully_received',     '2025-01-12', '2025-01-19', '2025-01-20', 7,  'putaway_done', NULL,                           'Net 45',  'paid',            198000.00),
('PO-2025-0003', 8, 3, 11, 18, 'fully_received',     '2025-01-15', '2025-01-29', '2025-01-28', 10, 'putaway_done', NULL,                           'Net 60',  'paid',            312000.00),
('PO-2025-0004', 3, 1, 2,  1,  'fully_received',     '2025-02-01', '2025-02-11', '2025-02-10', 3,  'putaway_done', NULL,                           'Net 30',  'paid',            176400.00),
('PO-2025-0005', 5, 4, 2,  18, 'fully_received',     '2025-02-05', '2025-02-12', '2025-02-14', 13, 'putaway_done', NULL,                           'Net 45',  'paid',            126000.00),
-- Partially received
('PO-2025-0006', 9, 3, 11, 18, 'partially_received', '2025-02-20', '2025-03-06', '2025-03-05', 10, 'passed',       NULL,                           'Net 60',  'partially_paid',  198000.00),
('PO-2025-0007', 4, 5, 15, 18, 'partially_received', '2025-03-01', '2025-03-11', '2025-03-12', 17, 'passed',       NULL,                           'Net 30',  'unpaid',          155400.00),
-- GRN failed / rejected
('PO-2025-0008', 6, 2, 6,  18, 'fully_received',     '2025-03-05', '2025-03-17', '2025-03-18', 7,  'failed',       'Batch expiry dates too close', 'Net 30',  'unpaid',          84000.00),
-- Approved, awaiting delivery
('PO-2025-0009', 1, 1, 2,  1,  'approved',           '2025-03-20', '2025-03-27', NULL,          NULL, NULL,         NULL,                           'Net 30',  'unpaid',          290400.00),
('PO-2025-0010', 2, 2, 6,  18, 'approved',           '2025-03-22', '2025-03-29', NULL,          NULL, NULL,         NULL,                           'Net 45',  'unpaid',          232000.00),
-- Submitted
('PO-2025-0011', 8, 3, 11, NULL, 'submitted',        '2025-04-01', '2025-04-15', NULL,          NULL, NULL,         NULL,                           'Net 60',  'unpaid',          390000.00),
('PO-2025-0012', 3, 5, 15, NULL, 'submitted',        '2025-04-02', '2025-04-12', NULL,          NULL, NULL,         NULL,                           'Net 30',  'unpaid',          112000.00),
-- Draft
('PO-2025-0013', 5, 1, 2,  NULL, 'draft',            '2025-04-05', '2025-04-15', NULL,          NULL, NULL,         NULL,                           'Net 45',  'unpaid',          0.00),
-- Cancelled
('PO-2025-0014', 7, 2, 6,  18, 'cancelled',          '2025-03-10', '2025-03-20', NULL,          NULL, NULL,         NULL,                           'Net 45',  'unpaid',          0.00),
-- Old received PO for inventory continuity
('PO-2024-0050', 9, 3, 11, 18, 'fully_received',     '2024-11-01', '2024-11-15', '2024-11-14', 10, 'putaway_done', NULL,                           'Net 60',  'paid',            468000.00);

-- ============================================================
-- SECTION 9 | PO_ITEM (2–4 line items per PO = 38 items)
-- ============================================================
INSERT INTO po_item (po_id, product_id, supplier_product_id, ordered_quantity, received_quantity, unit_price, item_status) VALUES
-- PO-2025-0001: HUL → WH-MUM (Dove Shampoo, Vaseline, Colgate)
(1, 1,  1, 2000, 2000, 58.00, 'fully_received'),
(1, 5,  2, 1000, 1000, 90.00, 'fully_received'),
(1, 9,  3, 1200, 1200, 45.00, 'fully_received'),
-- PO-2025-0002: ITC → WH-DEL (Britannia, Lays, Haldirams)
(2, 12, 5, 3000, 3000, 16.00, 'fully_received'),
(2, 13, 6, 2000, 2000, 13.50, 'fully_received'),
(2, 14, 7, 1000, 1000, 63.00, 'fully_received'),
-- PO-2025-0003: Cipla → WH-BLR (Azithromycin, Metformin, Atorvastatin)
(3, 27, 20, 1000, 1000, 78.00, 'fully_received'),
(3, 28, 21, 2000, 2000, 40.00, 'fully_received'),
(3, 29, 22, 1500, 1500, 58.00, 'fully_received'),
-- PO-2025-0004: Dabur → WH-MUM (Amla Oil, Crocin, Digene)
(4, 4,  9, 1000, 1000, 80.00, 'fully_received'),
(4, 24, 10, 2000, 2000, 30.00, 'fully_received'),
(4, 26, 12, 1200, 1200, 60.00, 'fully_received'),
-- PO-2025-0005: Marico → WH-AHM (Parachute oil)
(5, 3,  16, 1200, 1200, 105.00, 'fully_received'),
-- PO-2025-0006: Sun Pharma → WH-BLR (Azithromycin, Pantoprazole)
(6, 27, 23, 1500, 800,  80.00, 'partially_received'),
(6, 30, 25, 2000, 1200, 50.00, 'partially_received'),
-- PO-2025-0007: Godrej → WH-HYD (Nivea Soft, Garnier, Comfort)
(7, 6,  13, 800,  600,  82.00, 'partially_received'),
(7, 8,  14, 600,  400,  68.00, 'partially_received'),
(7, 20, 15, 500,  0,    112.00,'pending'),
-- PO-2025-0008: Patanjali → WH-DEL (Pepsodent-alt, Dolo)  [GRN FAILED]
(8, 10, 18, 1500, 1500, 38.00, 'fully_received'),
(8, 26, 19, 1000, 1000, 56.00, 'fully_received'),
-- PO-2025-0009: HUL → WH-MUM (pending delivery)
(9, 1,  1, 3000, 0, 58.00, 'pending'),
(9, 5,  2, 1500, 0, 90.00, 'pending'),
(9, 18, 4, 1000, 0, 118.00,'pending'),
-- PO-2025-0010: ITC → WH-DEL (pending delivery)
(10, 12, 5, 4000, 0, 16.00, 'pending'),
(10, 15, 8, 1000, 0, 70.00, 'pending'),
(10, 16, NULL, 500, 0, 210.00,'pending'),
-- PO-2025-0011: Cipla → WH-BLR (submitted)
(11, 27, 20, 2000, 0, 78.00, 'pending'),
(11, 28, 21, 3000, 0, 40.00, 'pending'),
(11, 29, 22, 2000, 0, 58.00, 'pending'),
(11, 30, NULL, 1500, 0, 55.00,'pending'),
-- PO-2025-0012: Dabur → WH-HYD (submitted)
(12, 24, 10, 2000, 0, 30.00, 'pending'),
(12, 25, 11, 1000, 0, 72.00, 'pending'),
-- PO-2024-0050: Sun Pharma old → WH-BLR (fully received, bulk)
(15, 27, 23, 3000, 3000, 80.00, 'fully_received'),
(15, 28, 21, 5000, 5000, 40.00, 'fully_received'),
(15, 29, 24, 3500, 3500, 55.00, 'fully_received'),
(15, 30, 25, 4000, 4000, 50.00, 'fully_received');

-- ============================================================
-- SECTION 10 | BATCH (25 batches from received PO items)
-- ============================================================
INSERT INTO batch (batch_code, product_id, supplier_id, po_item_id, manufactured_date, expiry_date, received_date, initial_quantity, unit_of_measure, quality_status) VALUES
-- From PO-2025-0001 (HUL → MUM)
('BCH-HUL-2025-001', 1,  1, 1,  '2024-10-01', '2026-09-30', '2025-01-16', 2000, 'Unit',  'approved'),
('BCH-HUL-2025-002', 5,  1, 2,  '2024-11-01', '2027-10-31', '2025-01-16', 1000, 'Unit',  'approved'),
('BCH-HUL-2025-003', 9,  1, 3,  '2024-10-15', '2027-10-14', '2025-01-16', 1200, 'Unit',  'approved'),
-- From PO-2025-0002 (ITC → DEL)
('BCH-ITC-2025-001', 12, 2, 4,  '2025-01-05', '2025-07-04', '2025-01-20', 3000, 'Unit',  'approved'),
('BCH-ITC-2025-002', 13, 2, 5,  '2025-01-05', '2025-05-04', '2025-01-20', 2000, 'Unit',  'approved'),
('BCH-ITC-2025-003', 14, 2, 6,  '2024-12-01', '2025-08-31', '2025-01-20', 1000, 'Unit',  'approved'),
-- From PO-2025-0003 (Cipla → BLR)
('BCH-CIP-2025-001', 27, 8, 7,  '2025-01-01', '2026-01-01', '2025-01-28', 1000, 'Strip', 'approved'),
('BCH-CIP-2025-002', 28, 8, 8,  '2025-01-01', '2027-01-01', '2025-01-28', 2000, 'Strip', 'approved'),
('BCH-CIP-2025-003', 29, 8, 9,  '2025-01-01', '2027-01-01', '2025-01-28', 1500, 'Strip', 'approved'),
-- From PO-2025-0004 (Dabur → MUM)
('BCH-DAB-2025-001', 4,  3, 10, '2024-09-01', '2027-08-31', '2025-02-10', 1000, 'Unit',  'approved'),
('BCH-DAB-2025-002', 24, 3, 11, '2024-11-01', '2026-10-31', '2025-02-10', 2000, 'Strip', 'approved'),
('BCH-DAB-2025-003', 26, 3, 12, '2024-10-01', '2026-09-30', '2025-02-10', 1200, 'Unit',  'approved'),
-- From PO-2025-0005 (Marico → AHM)
('BCH-MAR-2025-001', 3,  5, 13, '2024-10-01', '2027-09-30', '2025-02-14', 1200, 'Unit',  'approved'),
-- From PO-2025-0006 (Sun Pharma → BLR, partial)
('BCH-SUN-2025-001', 27, 9, 14, '2025-02-01', '2026-02-01', '2025-03-05', 800,  'Strip', 'approved'),
('BCH-SUN-2025-002', 30, 9, 15, '2025-01-01', '2027-01-01', '2025-03-05', 1200, 'Strip', 'approved'),
-- From PO-2025-0007 (Godrej → HYD, partial)
('BCH-GOD-2025-001', 6,  4, 16, '2024-11-01', '2027-10-31', '2025-03-12', 600,  'Unit',  'approved'),
('BCH-GOD-2025-002', 8,  4, 17, '2024-11-01', '2026-10-31', '2025-03-12', 400,  'Unit',  'approved'),
-- From PO-2025-0008 (Patanjali → DEL, GRN failed but items received — quarantined)
('BCH-PAT-2025-001', 10, 6, 19, '2024-06-01', '2025-05-31', '2025-03-18', 1500, 'Unit',  'quarantine'),
('BCH-PAT-2025-002', 26, 6, 20, '2024-07-01', '2025-06-30', '2025-03-18', 1000, 'Unit',  'quarantine'),
-- From PO-2024-0050 (Sun Pharma old bulk → BLR, all approved)
('BCH-SUN-2024-001', 27, 9, 32, '2024-09-01', '2025-09-01', '2024-11-14', 3000, 'Strip', 'approved'),
('BCH-SUN-2024-002', 28, 9, 33, '2024-09-01', '2026-09-01', '2024-11-14', 5000, 'Strip', 'approved'),
('BCH-SUN-2024-003', 29, 9, 34, '2024-09-01', '2026-09-01', '2024-11-14', 3500, 'Strip', 'approved'),
('BCH-SUN-2024-004', 30, 9, 35, '2024-09-01', '2026-09-01', '2024-11-14', 4000, 'Strip', 'approved'),
-- Standalone batch (direct adjustment / opening stock)
('BCH-OPN-2024-001', 1,  1, NULL, '2024-08-01', '2026-07-31', '2024-09-01', 500, 'Unit',  'approved');

-- ============================================================
-- SECTION 11 | INVENTORY (batch × zone placements)
-- ============================================================
INSERT INTO inventory (product_id, batch_id, zone_id, quantity_on_hand, quantity_reserved, last_movement_at) VALUES
-- WH-MUM STG-A (zone_id=2): FMCG stock
(1,  1,  2, 1200, 300, '2025-02-15 10:00:00'),   -- Dove Shampoo (BCH-HUL-2025-001)
(1,  24, 2, 300,  100, '2024-09-05 08:00:00'),   -- Dove Shampoo (BCH-OPN-2024-001, older)
(5,  2,  2, 600,  150, '2025-02-15 10:00:00'),   -- Vaseline (BCH-HUL-2025-002)
(9,  3,  2, 900,  200, '2025-02-15 10:00:00'),   -- Colgate (BCH-HUL-2025-003)
(4,  10, 3, 700,  100, '2025-02-12 09:00:00'),   -- Dabur Amla Oil, STG-B zone
(24, 11, 3, 1800, 400, '2025-02-12 09:00:00'),   -- Crocin (BCH-DAB-2025-002)
(26, 12, 3, 1000, 200, '2025-02-12 09:00:00'),   -- Digene (BCH-DAB-2025-003)
-- WH-DEL STG-A (zone_id=7): ITC snacks
(12, 4,  7, 2200, 500, '2025-01-22 11:00:00'),   -- Britannia
(13, 5,  7, 1500, 300, '2025-01-22 11:00:00'),   -- Lays
(14, 6,  7, 800,  150, '2025-01-22 11:00:00'),   -- Haldirams
-- WH-DEL STG-B (zone_id=8): Patanjali (quarantined — should be in quarantine zone but placed here for demo)
(10, 18, 8, 1500, 0,   '2025-03-19 14:00:00'),   -- Pepsodent (quarantine batch)	
(26, 19, 8, 1000, 0,   '2025-03-19 14:00:00'),   -- Digene-Patanjali (quarantine batch)
-- WH-BLR Cold Storage STG-C (zone_id=12): Cipla new batches
(27, 7,  12, 800,  200, '2025-01-30 08:00:00'),  -- Azithromycin Cipla
(28, 8,  12, 1800, 400, '2025-01-30 08:00:00'),  -- Metformin Cipla
(29, 9,  12, 1300, 300, '2025-01-30 08:00:00'),  -- Atorvastatin Cipla
-- WH-BLR Cold Storage STG-C: Sun Pharma new batches
(27, 14, 12, 600,  100, '2025-03-07 09:00:00'),  -- Azithromycin Sun
(30, 15, 12, 1000, 200, '2025-03-07 09:00:00'),  -- Pantoprazole Sun
-- WH-BLR Cold Storage STG-C: Sun Pharma 2024 bulk
(27, 20, 12, 2500, 600, '2024-11-16 10:00:00'),  -- Azithromycin 2024 bulk
(28, 21, 12, 4500, 900, '2024-11-16 10:00:00'),  -- Metformin 2024 bulk
(29, 22, 12, 3200, 700, '2024-11-16 10:00:00'),  -- Atorvastatin 2024 bulk
(30, 23, 12, 3800, 800, '2024-11-16 10:00:00'),  -- Pantoprazole 2024 bulk
-- WH-AHM STG-A (zone_id=17): Marico
(3,  13, 17, 900,  200, '2025-02-16 07:00:00'),  -- Parachute oil
-- WH-HYD STG-A (zone_id=21): Godrej
(6,  16, 21, 500,  100, '2025-03-14 10:00:00'),  -- Nivea Soft
(8,  17, 21, 350,   80, '2025-03-14 10:00:00'),  -- Garnier Facewash
-- WH-BLR Quarantine zone (zone_id=15) — a different zone than STG
(27, 7,  15,  200,   0, '2025-01-30 08:00:00'),  -- Azithromycin initial quarantine (pre-QC pass)
-- WH-MUM picking zone (zone_id=4) — picked-forward stock
(1,  1,  4,  100,   80, '2025-03-01 12:00:00'),  -- Dove Shampoo in picking
(9,  3,  4,  150,  100, '2025-03-01 12:00:00');  -- Colgate in picking

-- ============================================================
-- SECTION 12 | CUSTOMER (15 customers)
-- ============================================================
INSERT INTO customer (customer_code, customer_type, company_name, contact_person, email, phone, billing_address, credit_limit, outstanding_balance, is_credit_hold, payment_terms_days, kyc_verified) VALUES
('CUST-001', 'wholesale',          'Metro Cash & Carry India',      'Deepak Verma',    'deepak.verma@metro.in',          '2234567001', 'Plot 12, MIDC, Andheri East, Mumbai 400093',            2000000.00,  450000.00, FALSE, 30, TRUE),
('CUST-002', 'retail',             'D-Mart (Avenue Supermarts)',    'Geeta Talwar',    'geeta.talwar@dmart.in',          '2234567002', '1234 Link Road, Malad West, Mumbai 400064',             1500000.00,  125000.00, FALSE, 15, TRUE),
('CUST-003', 'ecommerce_platform', 'Flipkart Wholesale',            'Rajan Khanna',    'rajan.khanna@flipkart.com',      '8034567001', 'Cessna Business Park, Bengaluru 560037',                3000000.00,       0.00, FALSE,  7, TRUE),
('CUST-004', 'institutional',      'Apollo Hospitals Pharmacy',     'Dr. Meera Suri',  'meera.suri@apollohospitals.com', '4423456001', 'Plot 1, Jubilee Hills, Hyderabad 500033',               2500000.00,  850000.00, FALSE, 30, TRUE),
('CUST-005', 'wholesale',          'Reliance Retail Ltd',           'Arjun Sharma',    'arjun.sharma@reliance.com',      '2234567005', 'Maker Chambers IV, Nariman Point, Mumbai 400021',       5000000.00, 1200000.00, FALSE, 30, TRUE),
('CUST-006', 'retail',             'Spencers Retail Ltd',           'Pooja Agarwal',   'pooja.a@spencers.in',            '3312345601', '7 Duncan House, Kolkata 700001',                         800000.00,  320000.00, FALSE, 30, TRUE),
('CUST-007', 'ecommerce_platform', 'Amazon Seller Services',        'Vivek Puri',      'vivek.puri@amazon.in',           '8023456001', 'Brigade Metropolis, Whitefield, Bengaluru 560048',      4000000.00,  500000.00, FALSE,  7, TRUE),
('CUST-008', 'institutional',      'AIIMS Delhi Pharmacy',          'Dr. Alok Verma',  'alok.verma@aiims.edu',           '1111234501', 'Ansari Nagar, New Delhi 110029',                        1000000.00,       0.00, FALSE, 60, TRUE),
('CUST-009', 'wholesale',          'Medplus Health Services',       'Sanjay Rao',      'sanjay.rao@medplus.in',          '4023456001', 'Road 12, Banjara Hills, Hyderabad 500034',              1200000.00,  150000.00, FALSE, 30, TRUE),
('CUST-010', 'retail',             'Big Bazaar (Future Retail)',    'Kirti Singh',     'kirti.singh@bigbazaar.in',       '2234567010', 'Knowledge Park II, Greater Noida 201306',                700000.00,  710000.00, TRUE,  30, FALSE), -- credit hold (over limit)
('CUST-011', 'ecommerce_platform', '1mg Technologies',              'Prateek Goel',    'prateek@1mg.com',                '1124567001', 'DLF Cyber City Phase II, Gurugram 122002',               900000.00,  200000.00, FALSE, 15, TRUE),
('CUST-012', 'institutional',      'Fortis Healthcare Pharmacy',    'Dr. Sunita Bose', 'sunita.bose@fortis.in',          '1234501001', '12/1 Cunningham Road, Bengaluru 560052',                 800000.00,   85000.00, FALSE, 45, TRUE),
('CUST-013', 'wholesale',          'Arihant Pharma Distributors',   'Mahesh Shah',     'mahesh.shah@arihantpharma.in',   '7927456001', 'Gujarat Industrial Estate, Vadodara 390007',             600000.00,  300000.00, FALSE, 30, TRUE),
('CUST-014', 'retail',             'More Retail Ltd',               'Priya Nayak',     'priya.nayak@more.in',            '8042345601', 'Prestige Meridian, MG Road, Bengaluru 560001',           500000.00,       0.00, FALSE, 30, TRUE),
('CUST-015', 'wholesale',          'Pharmeasy Trade & Supply',      'Nikhil Kapoor',   'nikhil.kapoor@pharmeasy.in',     '2234890001', '10th Floor, One BKC, Mumbai 400051',                    1800000.00,  950000.00, FALSE, 15, TRUE);

-- ============================================================
-- SECTION 13 | SALES ORDER (20 SOs)
-- ============================================================
INSERT INTO sales_order (so_number, customer_id, warehouse_id, created_by, so_status, order_date, requested_delivery_date, priority_level, dest_street, dest_city, dest_state, dest_pincode, total_amount, payment_status) VALUES
-- Delivered
('SO-2025-0001', 1,  1, 4,  'delivered',  '2025-02-01', '2025-02-08', 'standard', 'Plot 12 MIDC Andheri East', 'Mumbai',    'Maharashtra', '400093', 198000.00, 'paid'),
('SO-2025-0002', 2,  1, 4,  'delivered',  '2025-02-03', '2025-02-07', 'express',  '1234 Link Road Malad West', 'Mumbai',    'Maharashtra', '400064', 87500.00,  'paid'),
('SO-2025-0003', 3,  3, 4,  'delivered',  '2025-02-10', '2025-02-15', 'standard', 'Cessna Business Park',      'Bengaluru', 'Karnataka',   '560037', 312000.00, 'paid'),
('SO-2025-0004', 4,  3, 16, 'delivered',  '2025-02-15', '2025-02-22', 'urgent',   'Plot 1 Jubilee Hills',      'Hyderabad', 'Telangana',   '500033', 145000.00, 'paid'),
('SO-2025-0005', 5,  1, 4,  'delivered',  '2025-02-20', '2025-02-27', 'standard', 'Maker Chambers IV',         'Mumbai',    'Maharashtra', '400021', 256000.00, 'partially_paid'),
-- Dispatched (in transit)
('SO-2025-0006', 7,  3, 8,  'dispatched', '2025-03-05', '2025-03-10', 'express',  'Brigade Metropolis',         'Bengaluru', 'Karnataka',   '560048', 420000.00, 'unpaid'),
('SO-2025-0007', 9,  5, 16, 'dispatched', '2025-03-08', '2025-03-13', 'standard', 'Road 12 Banjara Hills',      'Hyderabad', 'Telangana',   '500034', 112000.00, 'unpaid'),
('SO-2025-0008', 11, 3, 16, 'dispatched', '2025-03-10', '2025-03-14', 'urgent',   'DLF Cyber City Phase II',    'Gurugram',  'Haryana',     '122002', 98000.00,  'unpaid'),
-- Picking/Packed
('SO-2025-0009', 1,  1, 4,  'picking',    '2025-03-15', '2025-03-22', 'standard', 'Plot 12 MIDC Andheri East', 'Mumbai',    'Maharashtra', '400093', 156000.00, 'unpaid'),
('SO-2025-0010', 5,  1, 4,  'packed',     '2025-03-16', '2025-03-21', 'express',  'Maker Chambers IV',          'Mumbai',    'Maharashtra', '400021', 234000.00, 'unpaid'),
-- Allocated
('SO-2025-0011', 2,  2, 8,  'allocated',  '2025-03-18', '2025-03-28', 'standard', '1234 Link Road Malad West', 'Mumbai',    'Maharashtra', '400064', 88000.00,  'unpaid'),
('SO-2025-0012', 6,  2, 8,  'allocated',  '2025-03-20', '2025-03-30', 'standard', '7 Duncan House',             'Kolkata',   'West Bengal', '700001', 74000.00,  'unpaid'),
-- Confirmed
('SO-2025-0013', 3,  3, 4,  'confirmed',  '2025-03-25', '2025-04-05', 'standard', 'Cessna Business Park',       'Bengaluru', 'Karnataka',   '560037', 510000.00, 'unpaid'),
('SO-2025-0014', 8,  2, 8,  'confirmed',  '2025-03-26', '2025-04-08', 'urgent',   'Ansari Nagar',               'New Delhi', 'Delhi',       '110029', 178000.00, 'unpaid'),
-- Draft
('SO-2025-0015', 13, 4, 4,  'draft',      '2025-04-01', '2025-04-10', 'standard', 'Gujarat Industrial Estate',  'Vadodara',  'Gujarat',     '390007', 0.00,      'unpaid'),
('SO-2025-0016', 15, 1, 4,  'draft',      '2025-04-02', '2025-04-12', 'express',  '10th Floor One BKC',         'Mumbai',    'Maharashtra', '400051', 0.00,      'unpaid'),
-- Cancelled
('SO-2025-0017', 10, 2, 8,  'cancelled',  '2025-03-12', '2025-03-20', 'standard', 'Knowledge Park II',          'Greater Noida','Uttar Pradesh','201306',0.00,  'unpaid'),
-- Returned
('SO-2025-0018', 4,  3, 16, 'returned',   '2025-01-20', '2025-01-27', 'standard', 'Plot 1 Jubilee Hills',       'Hyderabad', 'Telangana',   '500033', 85000.00,  'paid'),
-- Wholesale bulk pharma
('SO-2025-0019', 15, 3, 11, 'delivered',  '2025-03-01', '2025-03-08', 'standard', '10th Floor One BKC',         'Mumbai',    'Maharashtra', '400051', 680000.00, 'paid'),
('SO-2025-0020', 12, 3, 11, 'allocated',  '2025-04-01', '2025-04-10', 'standard', '12/1 Cunningham Road',       'Bengaluru', 'Karnataka',   '560052', 245000.00, 'unpaid');

-- ============================================================
-- SECTION 14 | SO_ITEM (2–4 items per SO = 45 items)
-- ============================================================
INSERT INTO so_item (so_id, product_id, ordered_quantity, allocated_quantity, picked_quantity, shipped_quantity, unit_price, item_status) VALUES
-- SO-2025-0001 (Metro → MUM, delivered)
(1,  1,  1000, 1000, 1000, 1000, 72.00, 'shipped'),
(1,  9,   800,  800,  800,  800, 55.00, 'shipped'),
(1,  5,   500,  500,  500,  500, 110.00,'shipped'),
-- SO-2025-0002 (D-Mart → MUM, delivered)
(2,  24, 1500, 1500, 1500, 1500, 38.00, 'shipped'),
(2,  26,  500,  500,  500,  500, 75.00, 'shipped'),
-- SO-2025-0003 (Flipkart → BLR, delivered)
(3,  27, 1500, 1500, 1500, 1500, 95.00, 'shipped'),
(3,  28, 2000, 2000, 2000, 2000, 52.00, 'shipped'),
(3,  30, 1000, 1000, 1000, 1000, 62.00, 'shipped'),
-- SO-2025-0004 (Apollo → BLR, delivered urgent)
(4,  29,  800,  800,  800,  800, 75.00, 'shipped'),
(4,  27,  500,  500,  500,  500, 95.00, 'shipped'),
(4,  30,  400,  400,  400,  400, 62.00, 'shipped'),
-- SO-2025-0005 (Reliance → MUM, delivered)
(5,  1,  2000, 2000, 2000, 2000, 72.00, 'shipped'),
(5,  9,  1200, 1200, 1200, 1200, 55.00, 'shipped'),
-- SO-2025-0006 (Amazon → BLR, dispatched)
(6,  27, 2000, 2000, 2000, 2000, 95.00, 'shipped'),
(6,  28, 2500, 2500, 2500, 2500, 52.00, 'shipped'),
(6,  29, 1500, 1500, 1500, 1500, 75.00, 'shipped'),
-- SO-2025-0007 (Medplus → HYD, dispatched)
(7,  6,   400,  400,  400,  400, 98.00, 'shipped'),
(7,  8,   300,  300,  300,  300, 85.00, 'shipped'),
-- SO-2025-0008 (1mg → BLR, dispatched)
(8,  30,  800,  800,  800,  800, 68.00, 'shipped'),
(8,  29,  600,  600,  600,  600, 75.00, 'shipped'),
-- SO-2025-0009 (Metro → MUM, picking)
(9,  4,   500,  500,  300,    0, 98.00, 'picked'),
(9,  24,  800,  800,  500,    0, 38.00, 'picked'),
-- SO-2025-0010 (Reliance → MUM, packed)
(10, 1,  1500, 1500, 1500,    0, 72.00, 'picked'),
(10, 26,  800,  800,  800,    0, 80.00, 'picked'),
-- SO-2025-0011 (D-Mart → DEL, allocated)
(11, 12, 1500, 1500,    0,    0, 20.00, 'allocated'),
(11, 14,  500,  500,    0,    0, 76.00, 'allocated'),
-- SO-2025-0012 (Spencers → DEL, allocated)
(12, 13,  800,  800,    0,    0, 18.00, 'allocated'),
(12, 14,  600,  600,    0,    0, 76.00, 'allocated'),
-- SO-2025-0013 (Flipkart → BLR, confirmed)
(13, 27, 3000,    0,    0,    0, 95.00, 'pending'),
(13, 28, 4000,    0,    0,    0, 52.00, 'pending'),
(13, 30, 2000,    0,    0,    0, 62.00, 'pending'),
-- SO-2025-0014 (AIIMS → DEL, confirmed)
(14, 27, 1000,    0,    0,    0, 95.00, 'pending'),
(14, 28, 1500,    0,    0,    0, 52.00, 'pending'),
-- SO-2025-0018 (Apollo returned)
(18, 29,  200,  200,  200,  200, 75.00, 'shipped'),
(18, 27,  100,  100,  100,  100, 95.00, 'shipped'),
-- SO-2025-0019 (Pharmeasy bulk, delivered)
(19, 27, 3000, 3000, 3000, 3000, 95.00, 'shipped'),
(19, 28, 4000, 4000, 4000, 4000, 52.00, 'shipped'),
(19, 30, 2000, 2000, 2000, 2000, 62.00, 'shipped'),
-- SO-2025-0020 (Fortis → BLR, allocated)
(20, 28, 1500, 1500,    0,    0, 55.00, 'allocated'),
(20, 29, 1000, 1000,    0,    0, 75.00, 'allocated'),
(20, 30,  800,  800,    0,    0, 68.00, 'allocated');

-- ============================================================
-- SECTION 15 | INVENTORY_ALLOCATION (FEFO allocations)
-- ============================================================
INSERT INTO inventory_allocation (so_item_id, inventory_id, allocated_quantity, allocation_method, allocated_at, allocated_by) VALUES
-- SO-2025-0001 items 1,2,3 from MUM inventory
(1,  1,  1000, 'FEFO', '2025-02-01 14:00:00', 3),   -- Dove from BCH-HUL-2025-001
(2,  4,   800, 'FEFO', '2025-02-01 14:05:00', 3),   -- Colgate from BCH-HUL-2025-003
(3,  3,   500, 'FEFO', '2025-02-01 14:10:00', 3),   -- Vaseline from BCH-HUL-2025-002
-- SO-2025-0002 items 4,5
(4,  6,  1500, 'FEFO', '2025-02-03 10:00:00', 3),   -- Crocin
(5,  7,   500, 'FEFO', '2025-02-03 10:05:00', 3),   -- Digene
-- SO-2025-0003 items 6,7,8 from BLR inventory
(6,  18, 1500, 'FEFO', '2025-02-10 09:00:00', 10),  -- Azithromycin 2024 bulk (FEFO: older first)
(7,  19, 2000, 'FEFO', '2025-02-10 09:05:00', 10),  -- Metformin 2024 bulk
(8,  21, 1000, 'FEFO', '2025-02-10 09:10:00', 10),  -- Pantoprazole 2024 bulk
-- SO-2025-0004 items 9,10,11
(9,  20,  800, 'FEFO', '2025-02-15 08:00:00', 10),  -- Atorvastatin 2024 bulk
(10, 18,  500, 'FEFO', '2025-02-15 08:05:00', 10),  -- Azithromycin (another chunk)
(11, 21,  400, 'FEFO', '2025-02-15 08:10:00', 10),  -- Pantoprazole
-- SO-2025-0005 items 12,13
(12, 26, 2000, 'FEFO', '2025-02-20 11:00:00', 3),   -- Dove from picking zone (inv_id=27)
(13, 27, 1200, 'FEFO', '2025-02-20 11:05:00', 3),   -- Colgate from picking zone
-- SO-2025-0006 dispatched — Amazon bulk BLR
(14, 13,  800, 'FEFO', '2025-03-05 07:00:00', 10),  -- Azithromycin Cipla (inv_id=13)
(14, 18, 1200, 'FEFO', '2025-03-05 07:05:00', 10),  -- Azithromycin 2024 (FEFO split)
(15, 14, 1800, 'FEFO', '2025-03-05 07:10:00', 10),  -- Metformin Cipla
(15, 19,  700, 'FEFO', '2025-03-05 07:15:00', 10),  -- Metformin 2024 (split)
(16, 15, 1000, 'FEFO', '2025-03-05 07:20:00', 10),  -- Atorvastatin Cipla
(16, 20,  500, 'FEFO', '2025-03-05 07:25:00', 10),  -- Atorvastatin 2024 (split)
-- SO-2025-0007 — Medplus HYD
(17, 23,  400, 'FEFO', '2025-03-08 09:00:00', 17),  -- Nivea
(18, 24,  300, 'FEFO', '2025-03-08 09:05:00', 17),  -- Garnier
-- SO-2025-0008 — 1mg BLR
(19, 21,  800, 'FEFO', '2025-03-10 10:00:00', 10),  -- Pantoprazole 2024
(20, 22,  600, 'FEFO', '2025-03-10 10:05:00', 10),  -- Atorvastatin 2024
-- SO-2025-0009 — Metro MUM picking
(21, 5,   500, 'FEFO', '2025-03-15 09:00:00', 3),   -- Dabur Amla Oil
(22, 6,   800, 'FEFO', '2025-03-15 09:05:00', 3),   -- Crocin
-- SO-2025-0010 — Reliance MUM
(23, 26, 1500, 'FEFO', '2025-03-16 10:00:00', 3),   -- Dove picking
(24, 7,   800, 'FEFO', '2025-03-16 10:05:00', 3),   -- Digene
-- SO-2025-0011 — D-Mart DEL snacks
(25, 8,  1500, 'FEFO', '2025-03-18 11:00:00', 7),   -- Britannia
(26, 10,  500, 'FEFO', '2025-03-18 11:05:00', 7),   -- Haldirams
-- SO-2025-0012 — Spencers DEL snacks
(27, 9,   800, 'FEFO', '2025-03-20 09:00:00', 7),   -- Lays
(28, 10,  600, 'FEFO', '2025-03-20 09:05:00', 7),   -- Haldirams
-- SO-2025-0018 — Apollo returned SO
(34, 22,  200, 'FEFO', '2025-01-20 10:00:00', 10),  -- Atorvastatin
(35, 18,  100, 'FEFO', '2025-01-20 10:05:00', 10),  -- Azithromycin
-- SO-2025-0019 — Pharmeasy bulk
(36, 18, 2500, 'FEFO', '2025-03-01 08:00:00', 10),
(36, 13,  500, 'FEFO', '2025-03-01 08:05:00', 10),
(37, 19, 3500, 'FEFO', '2025-03-01 08:10:00', 10),
(37, 14,  500, 'FEFO', '2025-03-01 08:15:00', 10),
(38, 21, 1800, 'FEFO', '2025-03-01 08:20:00', 10),
(38, 16,  200, 'FEFO', '2025-03-01 08:25:00', 10),
-- SO-2025-0020 — Fortis allocated
(39, 14, 1500, 'manual', '2025-04-01 09:00:00', 10),
(40, 15, 1000, 'manual', '2025-04-01 09:05:00', 10),
(41, 16,  800, 'manual', '2025-04-01 09:10:00', 10);

-- ============================================================
-- SECTION 16 | SHIPMENT (10 shipments)
-- ============================================================
INSERT INTO shipment (shipment_number, origin_warehouse_id, vehicle_registration, carrier_name, driver_name, driver_phone, shipment_status, dispatch_at, estimated_arrival, actual_arrival, total_weight_kg, total_volume_cubic_m, freight_cost) VALUES
('SHP-2025-0001', 1, 'MH01AB1234', 'Blue Dart Logistics',     'Ramesh Yadav',    '9870011111', 'delivered',     '2025-02-05 06:00:00', '2025-02-08 18:00:00', '2025-02-08 15:30:00', 650.00,  3.20, 8500.00),
('SHP-2025-0002', 1, 'MH01CD5678', 'Delhivery Pvt Ltd',       'Suresh Pawar',    '9870022222', 'delivered',     '2025-02-05 08:00:00', '2025-02-07 20:00:00', '2025-02-07 18:00:00', 280.00,  1.50, 4200.00),
('SHP-2025-0003', 3, 'KA03EF9012', 'DTDC Courier',            'Mahesh Gowda',    '9870033333', 'delivered',     '2025-02-12 05:00:00', '2025-02-15 20:00:00', '2025-02-15 17:00:00', 420.00,  2.80, 6000.00),
('SHP-2025-0004', 3, 'KA03GH3456', 'Ecom Express',            'Venkatesha Rao',  '9870044444', 'delivered',     '2025-02-17 06:00:00', '2025-02-22 18:00:00', '2025-02-22 16:00:00', 250.00,  1.20, 5500.00),
('SHP-2025-0005', 1, 'MH01IJ7890', 'TCI Express',             'Ganesh Tiwari',   '9870055555', 'delivered',     '2025-02-22 07:00:00', '2025-02-27 19:00:00', '2025-02-27 14:00:00', 780.00,  4.10, 12000.00),
('SHP-2025-0006', 3, 'KA03KL1234', 'Amazon Logistics',        'Shiva Kumar',     '9870066666', 'in_transit',    '2025-03-07 04:00:00', '2025-03-10 20:00:00', NULL,                  1200.00, 6.50, 15000.00),
('SHP-2025-0007', 5, 'TS09MN5678', 'Rivigo Pvt Ltd',          'Narsimha Reddy',  '9870077777', 'out_for_delivery','2025-03-11 06:00:00','2025-03-13 18:00:00',NULL,                  280.00,  1.60, 3800.00),
('SHP-2025-0008', 3, 'KA03OP9012', 'Shadowfax Technologies',  'Praveen Kumar',   '9870088888', 'in_transit',    '2025-03-12 05:00:00', '2025-03-14 21:00:00', NULL,                  380.00,  1.80, 5200.00),
('SHP-2025-0009', 1, 'MH01QR3456', 'GATI Ltd',                'Dilip Sharma',    '9870099999', 'loading',       NULL,                  '2025-03-22 18:00:00', NULL,                  450.00,  2.20, 7500.00),
('SHP-2025-0010', 3, 'KA03ST7890', 'Blue Dart Logistics',     'Arun Bhat',       '9871011111', 'delivered',     '2025-03-05 04:00:00', '2025-03-08 18:00:00', '2025-03-08 15:00:00', 2100.00, 10.50,22000.00);

-- ============================================================
-- SECTION 17 | SHIPMENT_ITEM
-- ============================================================
INSERT INTO shipment_item (shipment_id, so_item_id, quantity_shipped) VALUES
-- SHP-2025-0001 → SO-2025-0001 items
(1, 1,  1000),  -- Dove Shampoo
(1, 2,   800),  -- Colgate
(1, 3,   500),  -- Vaseline
-- SHP-2025-0002 → SO-2025-0002 items
(2, 4,  1500),  -- Crocin
(2, 5,   500),  -- Digene
-- SHP-2025-0003 → SO-2025-0003 items
(3, 6,  1500),  -- Azithromycin
(3, 7,  2000),  -- Metformin
(3, 8,  1000),  -- Pantoprazole
-- SHP-2025-0004 → SO-2025-0004 items
(4, 9,   800),  -- Atorvastatin
(4, 10,  500),  -- Azithromycin
(4, 11,  400),  -- Pantoprazole
-- SHP-2025-0005 → SO-2025-0005 items
(5, 12, 2000),  -- Dove Shampoo
(5, 13, 1200),  -- Colgate
-- SHP-2025-0006 → SO-2025-0006 (dispatched)
(6, 14, 2000),  -- Azithromycin
(6, 15, 2500),  -- Metformin
(6, 16, 1500),  -- Atorvastatin
-- SHP-2025-0007 → SO-2025-0007 (out for delivery)
(7, 17,  400),  -- Nivea
(7, 18,  300),  -- Garnier
-- SHP-2025-0008 → SO-2025-0008 (in transit)
(8, 19,  800),  -- Pantoprazole
(8, 20,  600),  -- Atorvastatin
-- SHP-2025-0009 → SO-2025-0009 (loading, not shipped yet)
(9, 21,  300),  -- Dabur Amla Oil partial pick
(9, 22,  500),  -- Crocin partial pick
-- SHP-2025-0010 → SO-2025-0019 Pharmeasy bulk
(10, 36, 3000),
(10, 37, 4000),
(10, 38, 2000);

-- ============================================================
-- SECTION 18 | RETURN_REQUEST + RETURN_ITEM
-- ============================================================
INSERT INTO return_request (so_id, customer_id, approved_by, return_reason, return_status, requested_at) VALUES
(18, 4,  11, 'quality_issue', 'restocked',  '2025-02-01 10:00:00'),  -- Apollo returned SO-18
(4,  4,  11, 'wrong_item',    'refunded',   '2025-02-25 11:00:00'),  -- Apollo SO-4 small return
(1,  1,  1,  'excess',        'restocked',  '2025-03-01 09:00:00'),  -- Metro SO-1 excess return
(3,  3,  11, 'damaged',       'inspected',  '2025-03-20 14:00:00'),  -- Flipkart SO-3 damaged
(5,  5,  1,  'quality_issue', 'requested',  '2025-04-02 10:00:00');  -- Reliance SO-5 pending

INSERT INTO return_item (return_id, so_item_id, returned_quantity, condition_on_arrival, restocked_to_inventory_id, disposal_method) VALUES
(1, 34,  150, 'resellable',  20,   NULL),           -- Atorvastatin restocked to inv_id=20 (2024 bulk BLR)
(1, 35,   80, 'resellable',  18,   NULL),           -- Azithromycin restocked
(2, 10,   50, 'damaged',     NULL, 'Dispose-Incinerate'),  -- wrong Azith — incinerated
(3, 1,   200, 'resellable',  1,    NULL),           -- Dove Shampoo restocked to MUM
(4, 6,   100, 'damaged',     NULL, 'Dispose-Returns Centre'),
(5, 12,  300, 'resellable',  26,   NULL);           -- Dove from picking zone

-- ============================================================
-- SECTION 19 | REORDER_ALERT (7 alerts — auto-triggered scenario)
-- ============================================================
INSERT INTO reorder_alert (product_id, warehouse_id, preferred_supplier_id, current_stock, reorder_point, suggested_order_quantity, alert_status, triggered_at) VALUES
(12, 2, 2,  2200, 800,  2000, 'po_raised',  '2025-03-22 02:00:00'),  -- Britannia low at DEL
(13, 2, 2,  1500, 600,  1500, 'po_raised',  '2025-03-22 02:01:00'),  -- Lays low at DEL
(1,  1, 1,  1500, 500,  1000, 'dismissed',  '2025-03-10 02:00:00'),  -- Dove MUM (dismissed)
(27, 3, 8,  3900, 200,  2000, 'open',       '2025-04-01 02:00:00'),  -- Azith BLR (open — high dispatch)
(28, 3, 8,  8800, 300,  3000, 'open',       '2025-04-01 02:01:00'),  -- Metformin BLR
(3,  4, 5,   900, 400,   800, 'po_raised',  '2025-03-25 02:00:00'),  -- Parachute AHM
(6,  5, 4,   500, 300,   600, 'open',       '2025-04-05 02:00:00');  -- Nivea HYD

-- ============================================================
-- SECTION 20 | AUDIT_LOG (sample audit trail — 15 entries)
-- ============================================================
INSERT INTO audit_log (staff_id, action_type, table_name, record_id, old_value, new_value, performed_at, ip_address) VALUES
(2,  'INSERT', 'purchase_order',    1,  NULL,
 '{"po_number":"PO-2025-0001","po_status":"draft","supplier_id":1}',
 '2025-01-10 10:00:00', '10.0.1.2'),
(1,  'UPDATE', 'purchase_order',    1,
 '{"po_status":"draft"}', '{"po_status":"approved"}',
 '2025-01-10 11:30:00', '10.0.1.1'),
(3,  'UPDATE', 'purchase_order',    1,
 '{"po_status":"approved","grn_status":null}', '{"po_status":"fully_received","grn_status":"putaway_done"}',
 '2025-01-16 14:00:00', '10.0.1.3'),
(4,  'INSERT', 'sales_order',       1,  NULL,
 '{"so_number":"SO-2025-0001","so_status":"draft","customer_id":1}',
 '2025-02-01 09:00:00', '10.0.1.4'),
(3,  'UPDATE', 'sales_order',       1,
 '{"so_status":"confirmed"}', '{"so_status":"allocated"}',
 '2025-02-01 14:15:00', '10.0.1.3'),
(3,  'UPDATE', 'sales_order',       1,
 '{"so_status":"allocated"}', '{"so_status":"picking"}',
 '2025-02-04 08:00:00', '10.0.1.3'),
(3,  'UPDATE', 'sales_order',       1,
 '{"so_status":"picking"}', '{"so_status":"dispatched"}',
 '2025-02-05 06:30:00', '10.0.1.3'),
(3,  'UPDATE', 'sales_order',       1,
 '{"so_status":"dispatched"}', '{"so_status":"delivered"}',
 '2025-02-08 16:00:00', '10.0.1.3'),
(11, 'UPDATE', 'batch',             7,
 '{"quality_status":"quarantine"}', '{"quality_status":"approved"}',
 '2025-01-29 12:00:00', '10.0.3.11'),
(5,  'INSERT', 'reorder_alert',     1,  NULL,
 '{"product_id":12,"warehouse_id":2,"alert_status":"open"}',
 '2025-03-22 02:00:00', '10.0.1.5'),
(6,  'UPDATE', 'reorder_alert',     1,
 '{"alert_status":"open"}', '{"alert_status":"po_raised"}',
 '2025-03-22 09:00:00', '10.0.2.6'),
(18, 'UPDATE', 'supplier',          6,
 '{"supplier_tier":"preferred"}', '{"supplier_tier":"approved"}',
 '2025-03-19 16:00:00', '10.0.0.18'),
(19, 'DELETE', 'inventory_allocation', 5, '{"allocation_id":5,"allocated_quantity":1500}', NULL,
 '2025-02-11 10:00:00', '10.0.0.19'),
(10, 'INSERT', 'return_request',    1,  NULL,
 '{"return_id":1,"so_id":18,"return_reason":"quality_issue"}',
 '2025-02-01 10:00:00', '10.0.3.10'),
(1,  'UPDATE', 'purchase_order',    8,
 '{"grn_status":"pending_inspection"}', '{"grn_status":"failed","rejection_reason":"Batch expiry dates too close"}',
 '2025-03-18 15:00:00', '10.0.1.1');

-- ============================================================
-- SECTION 21 | INVENTORY_MOVEMENT_LOG (20 movement events)
-- ============================================================
INSERT INTO inventory_movement_log (inventory_id, movement_type, quantity_change, quantity_after, batch_id, zone_id, reference_id, reference_table, performed_by, performed_at) VALUES
-- Receipts (PO-2025-0001 putaway MUM)
(1,  'receipt',      2000,  2000, 1,  2, 1,  'purchase_order', 3,  '2025-01-16 15:00:00'),
(3,  'receipt',      1000,  1000, 2,  2, 1,  'purchase_order', 3,  '2025-01-16 15:05:00'),
(4,  'receipt',      1200,  1200, 3,  2, 1,  'purchase_order', 3,  '2025-01-16 15:10:00'),
-- Receipts (PO-2025-0002 DEL)
(8,  'receipt',      3000,  3000, 4,  7, 2,  'purchase_order', 7,  '2025-01-20 12:00:00'),
(9,  'receipt',      2000,  2000, 5,  7, 2,  'purchase_order', 7,  '2025-01-20 12:05:00'),
(10, 'receipt',      1000,  1000, 6,  7, 2,  'purchase_order', 7,  '2025-01-20 12:10:00'),
-- Allocations for SO-2025-0001
(1,  'allocation',  -1000,  1000, 1,  2, 1,  'sales_order',   3,  '2025-02-01 14:00:00'),
(4,  'allocation',   -800,   400, 3,  2, 1,  'sales_order',   3,  '2025-02-01 14:05:00'),
(3,  'allocation',   -500,   500, 2,  2, 1,  'sales_order',   3,  '2025-02-01 14:10:00'),
-- Dispatch (SO-2025-0001 shipped)
(1,  'dispatch',    -1000,     0, 1,  2, 1,  'shipment',      3,  '2025-02-05 06:30:00'),
(4,  'dispatch',     -800,     0, 3,  2, 1,  'shipment',      3,  '2025-02-05 06:35:00'),
-- Return restocking
(1,  'return',        200,   200, 1,  2, 3,  'return_request',3,  '2025-03-02 10:00:00'),
(18, 'return',        150,  2650, 20, 12,1,  'return_request',10, '2025-02-03 11:00:00'),
-- FEFO allocation BLR Amazon
(18, 'allocation',  -1500,  1000, 20, 12, 6, 'sales_order',   10, '2025-03-05 07:05:00'),
(19, 'allocation',  -2000,  2500, 21, 12, 6, 'sales_order',   10, '2025-03-05 07:10:00'),
-- Write-off (damaged Azith from Apollo return)
(18, 'write_off',     -50,   950, 7,  12, 2, 'return_item',   10, '2025-02-26 12:00:00'),
-- Deallocation (SO-2025-0017 cancelled)
(8,  'deallocation',  500,  2700, 4,  7,  17,'sales_order',   7,  '2025-03-13 09:00:00'),
-- Adjustment (stock count correction MUM STG-B)
(5,  'adjustment',   -30,    670, 10, 3,  NULL,NULL,          3,  '2025-03-20 16:00:00'),
-- Pharmeasy dispatch BLR
(18, 'dispatch',    -2500,     0, 20, 12, 19, 'shipment',     10, '2025-03-05 06:00:00'),
(19, 'dispatch',    -3500,     0, 21, 12, 19, 'shipment',     10, '2025-03-05 06:05:00');