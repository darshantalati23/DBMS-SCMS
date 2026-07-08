# SCMS: Supply Chain Management System

### Meet the Makers

Build by students at Dhirubhai Ambani University (formerly DA-IICT)

- Aaryan Modi (202401435)
- Darshan Talati (202401046)
- Kavya Bhojwani (202401090)
- Shlok Patel (202401156)

## The Core Philosophy and Impact

Supply chain software is notoriously brittle. It appears that when business logic is scattered across microservices, REST APIs, and front-end state, data integrity often suffers. We suspect the root cause is a misplaced trust in the application layer.

This project takes a contrarian, old-school approach: the _"Thick Database, Thin Client"_ architecture.

The core idea? Make PostgreSQL the absolute arbiter of truth. We enforce every business rule, state transition, and referential guarantee directly within the database schema using constraints, triggers, and custom data types. The impact of this design is profound. By stripping the application layer of its validation responsibilities, we eliminate entire classes of bugs (like race conditions leading to negative inventory). The database becomes an impenetrable fortress. If a rule is violated, the database rejects the transaction outright, regardless of the client interacting with it. It’s a design that scales inherently and guarantees rock-solid data integrity under high concurrency.

## The Schema: A Deep Dive

The database isn't just a dumb store for the application; it is the application. We designed a fully normalized relational model comprising **26 tables** and **21 custom ENUM types**, logically partitioned into six domains.

### 1. Master Data (Warehouse, Supplier, Product, Staff)

The foundational entities.

- **Product & Category:** Products belong to a recursive category tree (`parent_category_id`), allowing flexible catalog hierarchies. Crucially, we store temperature thresholds (`min_temp_celsius`, `max_temp_celsius`) to enforce cold chain compliance.
- **Supplier & Supplies:** A generated column computes the `supplier_rating` dynamically based on on-time delivery and quality rejection rates.
- **Warehouse & Zones:** Warehouses are divided into specific operational zones (storage, quarantine, dispatch).
- **Staff:** The foundation for role-based access control, including a `password_hash` column for future API integration.

### 2. Procurement (Purchase Orders & Batches)

Procurement drives inbound inventory. Purchase orders (`purchase_order`, `po_item`) can be fulfilled by external suppliers or internal warehouse transfers.

- A rigorous `CHECK` constraint guarantees we never receive more items than ordered.
- Batches track expiration dates, with a firm rule: `expiry_date >= received_date`.

### 3. Inventory & Auditing

The beating heart of the system.

- **Ternary Inventory Key:** Stock is tracked by `(product_id, batch_id, zone_id)`.
- **Generated Availability:** `quantity_available` is mathematically bound as `GENERATED ALWAYS AS (quantity_on_hand - quantity_reserved)`, eliminating synchronization bugs.
- **Strict Checks:** `quantity_on_hand >= 0` is enforced at the database level. No negative inventory. Ever.
- **Movement Log:** An append-only ledger (`inventory_movement_log`) tracks every single receipt, allocation, and dispatch for perfect auditability.

### 4. Sales & Fulfillment

Sales orders (`sales_order`, `so_item`) reserve inventory. We support multi-warehouse fulfillment natively (`fulfillment_warehouse_id`), allowing a single order to be shipped from multiple locations. Allocation relies on explicit methods (e.g., FEFO - First Expired, First Out) to ensure perishable goods rotate correctly and waste is minimized.

### 5. Inter-Warehouse Transfers

Stock moving between facilities shouldn't be hacked in as a fake purchase order. We modeled `inter_warehouse_transfer` and `transfer_item` as first-class entities. This cleanly separates internal logistics from external procurement, providing accurate supply chain visibility.

### 6. Logistics & Cold Chain Tracking

Shipments (`shipment`, `shipment_item`) handle the physical movement of goods. We integrated `delivery_tracking` for live GPS and IoT temperature sensor readings, alongside an append-only `delivery_event` table. This provides a rigorous, immutable audit trail for cold chain SLA compliance.

## The Python Layer (Testing and CLI)

Python is secondary in this architecture. It serves two narrow, utilitarian purposes: providing a simple interactive interface and running rigorous integration tests against the live database.

We built a lightweight REPL CLI (`src/scms_cli.py`) using `prompt_toolkit` to execute queries and visualize the schema. There is no ORM. The CLI merely passes raw SQL to PostgreSQL and renders the results.

The test suite (`pytest`) is where the Python layer shines, proving the database's resilience. Tests are isolated using transaction `SAVEPOINT`s, ensuring no data pollution. The results are decisive: 21/21 tests passing in under 5 seconds, confirming that the database flawlessly rejects invalid operations and executes complex workflows perfectly. (See `docs/tests_summary.md` for a comprehensive breakdown of the test suite and its impact.)
