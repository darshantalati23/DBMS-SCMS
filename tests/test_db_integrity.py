"""
test_db_integrity.py — Pillar A: Database Constraint & Negative Testing
========================================================================

WHY THESE TESTS EXIST
----------------------
In a "Thick Database, Thin Client" system, PostgreSQL is the single source
of truth for business rules. These tests prove that the database correctly
REJECTS invalid data — regardless of which client sends it.

This is the most important pillar for a technical interview because it
demonstrates you understand:
  1. The difference between application-layer validation and DB-layer enforcement
  2. How to use CHECK constraints, ENUM types, UNIQUE constraints, and FK
     constraints as a first line of defence
  3. How to write negative tests (assert that the system REFUSES bad data)

All tests in this file use psycopg2.errors to assert on the specific
PostgreSQL error class, not just a generic exception.

Test isolation: each test uses the db_tx fixture (SAVEPOINT + ROLLBACK)
so the real seeded database is never modified.
"""

import pytest
import psycopg2
import psycopg2.errors


# ═══════════════════════════════════════════════════════════════════════════════
#  A-1 : Inventory quantity can never go negative
# ═══════════════════════════════════════════════════════════════════════════════

@pytest.mark.integrity
def test_negative_inventory_rejected(db_tx, seed_product, seed_batch, seed_zone):
    """
    BUSINESS RULE: Physical stock cannot be a negative number.
    A warehouse cannot have -50 units of a product.

    DB ENFORCEMENT: CHECK (quantity_on_hand >= 0) on the inventory table.

    WHY TEST THIS: Any UPDATE that decrements stock (e.g., a shipment dispatch)
    must be guarded. This proves the DB catches arithmetic errors in application
    code that might try to decrement below zero.
    """
    cur = db_tx.cursor()
    with pytest.raises(psycopg2.errors.CheckViolation):
        cur.execute("""
            INSERT INTO inventory
                (product_id, batch_id, zone_id, quantity_on_hand, quantity_reserved)
            VALUES (%s, %s, %s, -50, 0)   -- negative quantity_on_hand: INVALID
        """, (seed_product, seed_batch, seed_zone))
        db_tx.commit()


# ═══════════════════════════════════════════════════════════════════════════════
#  A-2 : Cannot ship more than was picked from the shelf
# ═══════════════════════════════════════════════════════════════════════════════

@pytest.mark.integrity
def test_shipped_exceeds_picked_rejected(
        db_tx, seed_warehouse, seed_staff, seed_customer, seed_product):
    """
    BUSINESS RULE: You can only load onto a truck what was physically picked
    from the shelf. shipped_quantity must always be <= picked_quantity.

    DB ENFORCEMENT: CHECK (shipped_quantity <= picked_quantity) on so_item.

    WHY TEST THIS: In warehouse management, the pick-pack-ship sequence is
    critical. This check prevents a data entry error (or a buggy app) from
    recording a shipment of goods that were never actually prepared.
    """
    cur = db_tx.cursor()

    # Create the minimum necessary parent records
    cur.execute("""
        INSERT INTO sales_order
            (so_number, customer_id, warehouse_id, created_by, so_status)
        VALUES ('SO-TEST-SHIP-01', %s, %s, %s, 'picking')
        RETURNING so_id
    """, (seed_customer, seed_warehouse, seed_staff))
    so_id = cur.fetchone()[0]

    with pytest.raises(psycopg2.errors.CheckViolation):
        cur.execute("""
            INSERT INTO so_item
                (so_id, product_id, ordered_quantity, allocated_quantity,
                 picked_quantity, shipped_quantity, unit_price, item_status)
            VALUES (%s, %s,
                    100,   -- ordered
                    80,    -- allocated
                    50,    -- picked  ← only 50 picked from shelf
                    75,    -- shipped ← 75 > 50 picked: INVALID
                    99.00, 'picked')
        """, (so_id, seed_product))
        db_tx.commit()


# ═══════════════════════════════════════════════════════════════════════════════
#  A-3 : Cannot receive more goods than were ordered on the PO
# ═══════════════════════════════════════════════════════════════════════════════

@pytest.mark.integrity
def test_received_exceeds_ordered_rejected(
        db_tx, seed_warehouse, seed_staff, seed_supplier, seed_product):
    """
    BUSINESS RULE: A supplier cannot deliver more units than were ordered.
    received_quantity must always be <= ordered_quantity on a PO line.

    DB ENFORCEMENT: CHECK (received_quantity <= ordered_quantity) on po_item.

    WHY TEST THIS: Over-receipt is a common warehouse error. If not caught at
    the DB level, inventory figures become inflated, triggering incorrect
    reorder calculations and inflated asset valuations.
    """
    cur = db_tx.cursor()

    cur.execute("""
        INSERT INTO purchase_order
            (po_number, supplier_id, warehouse_id, created_by, po_status)
        VALUES ('PO-TEST-RECV-01', %s, %s, %s, 'approved')
        RETURNING po_id
    """, (seed_supplier, seed_warehouse, seed_staff))
    po_id = cur.fetchone()[0]

    with pytest.raises(psycopg2.errors.CheckViolation):
        cur.execute("""
            INSERT INTO po_item
                (po_id, product_id, ordered_quantity, received_quantity,
                 unit_price, item_status)
            VALUES (%s, %s,
                    100,   -- ordered 100 units
                    150,   -- received 150: MORE than ordered — INVALID
                    45.00, 'partially_received')
        """, (po_id, seed_product))
        db_tx.commit()


# ═══════════════════════════════════════════════════════════════════════════════
#  A-4 : Each product must have a globally unique SKU code
# ═══════════════════════════════════════════════════════════════════════════════

@pytest.mark.integrity
def test_duplicate_sku_rejected(db_tx, seed_category):
    """
    BUSINESS RULE: A SKU (Stock Keeping Unit) code is the universal product
    identifier. Duplicates would cause inventory tracking chaos — two different
    products sharing the same identity.

    DB ENFORCEMENT: UNIQUE constraint on product.sku_code.

    WHY TEST THIS: Data entry systems often allow free-text SKU input.
    This proves the DB is the safety net that prevents accidental duplication
    even if the application layer fails to validate.
    """
    cur = db_tx.cursor()

    # Insert the first product — should succeed
    cur.execute("""
        INSERT INTO product
            (category_id, sku_code, product_name, unit_of_measure,
             reorder_point, reorder_quantity)
        VALUES (%s, 'SKU-DUPE-TEST-01', 'Original Product', 'Unit', 10, 50)
    """, (seed_category,))

    # Insert a second product with the SAME sku_code — must be rejected
    with pytest.raises(psycopg2.errors.UniqueViolation):
        cur.execute("""
            INSERT INTO product
                (category_id, sku_code, product_name, unit_of_measure,
                 reorder_point, reorder_quantity)
            VALUES (%s, 'SKU-DUPE-TEST-01', 'Duplicate Product', 'Unit', 10, 50)
        """, (seed_category,))
        db_tx.commit()


# ═══════════════════════════════════════════════════════════════════════════════
#  A-5 : Purchase Order status must be a valid lifecycle ENUM value
# ═══════════════════════════════════════════════════════════════════════════════

@pytest.mark.integrity
def test_invalid_po_status_enum_rejected(
        db_tx, seed_warehouse, seed_staff, seed_supplier):
    """
    BUSINESS RULE: A Purchase Order can only exist in one of these states:
    draft → submitted → approved → partially_received → fully_received / cancelled.

    DB ENFORCEMENT: po_status_enum ENUM type on purchase_order.po_status.

    WHY TEST THIS: ENUM types are PostgreSQL's way of making invalid state
    transitions physically impossible. This proves that no client (CLI, API,
    direct psql) can set a PO to a nonsense status like 'completed' or 'OPEN'.
    An ENUM is stronger than an application-level if/else check.
    """
    with pytest.raises(psycopg2.errors.InvalidTextRepresentation):
        cur = db_tx.cursor()
        cur.execute("""
            INSERT INTO purchase_order
                (po_number, supplier_id, warehouse_id, created_by, po_status)
            VALUES ('PO-ENUM-TEST-01', %s, %s, %s,
                    'completed')   -- 'completed' is NOT a valid po_status_enum value
        """, (seed_supplier, seed_warehouse, seed_staff))
        db_tx.commit()


# ═══════════════════════════════════════════════════════════════════════════════
#  A-6 : Supplier tier must be one of the defined strategic categories
# ═══════════════════════════════════════════════════════════════════════════════

@pytest.mark.integrity
def test_invalid_supplier_tier_enum_rejected(db_tx):
    """
    BUSINESS RULE: Suppliers are classified as strategic, preferred, approved,
    or blacklisted. No other classification exists.

    DB ENFORCEMENT: supplier_tier_enum ENUM type on supplier.supplier_tier.

    WHY TEST THIS: Procurement systems categorise suppliers for credit limits,
    payment terms, and sourcing priority. An invalid tier would corrupt vendor
    analytics and risk scoring.
    """
    with pytest.raises(psycopg2.errors.InvalidTextRepresentation):
        cur = db_tx.cursor()
        cur.execute("""
            INSERT INTO supplier
                (supplier_code, company_name, credit_limit,
                 supplier_tier, on_time_delivery_rate, quality_rejection_rate)
            VALUES ('SUP-ENUM-TEST', 'Bad Tier Supplier', 10000,
                    'gold_partner',   -- NOT a valid supplier_tier_enum value
                    80.0, 5.0)
        """)
        db_tx.commit()


# ═══════════════════════════════════════════════════════════════════════════════
#  A-7 : A batch must reference a product that actually exists (FK integrity)
# ═══════════════════════════════════════════════════════════════════════════════

@pytest.mark.integrity
def test_orphan_batch_product_fk_rejected(db_tx, seed_supplier):
    """
    BUSINESS RULE: Every received batch of goods must be linked to a known
    product in the catalogue. An "orphan" batch with no product reference
    makes inventory tracking impossible.

    DB ENFORCEMENT: FOREIGN KEY (product_id) REFERENCES product(product_id)
    on the batch table.

    WHY TEST THIS: FK constraints guarantee referential integrity across the
    entire entity graph. Without them, deleting a product could leave dangling
    batch records that point to nothing — a classic data integrity failure.
    """
    with pytest.raises(psycopg2.errors.ForeignKeyViolation):
        cur = db_tx.cursor()
        cur.execute("""
            INSERT INTO batch
                (batch_code, product_id, supplier_id,
                 expiry_date, received_date, initial_quantity, quality_status)
            VALUES ('BATCH-ORPHAN-01',
                    9999999,   -- product_id 9999999 does NOT exist
                    %s,
                    CURRENT_DATE + 365,
                    CURRENT_DATE, 100, 'quarantine')
        """, (seed_supplier,))
        db_tx.commit()


# ═══════════════════════════════════════════════════════════════════════════════
#  A-8 : A batch's expiry date cannot be before its received date
# ═══════════════════════════════════════════════════════════════════════════════

@pytest.mark.integrity
def test_batch_expiry_before_received_rejected(
        db_tx, seed_product, seed_supplier):
    """
    BUSINESS RULE: A product cannot expire before it was received.
    Receiving a batch with expiry_date < received_date signals corrupt
    master data (e.g., a data entry mistake in the date fields).

    DB ENFORCEMENT: CHECK (expiry_date >= received_date) on batch table.

    WHY TEST THIS: In cold-chain and pharma supply chains, expiry date
    management is safety-critical. This constraint prevents recording
    already-expired batches into usable inventory positions.
    """
    with pytest.raises(psycopg2.errors.CheckViolation):
        cur = db_tx.cursor()
        cur.execute("""
            INSERT INTO batch
                (batch_code, product_id, supplier_id,
                 expiry_date, received_date, initial_quantity, quality_status)
            VALUES ('BATCH-EXP-01', %s, %s,
                    '2024-01-01',   -- expiry:   Jan 2024
                    '2025-06-01',   -- received: Jun 2025  ← received AFTER expiry: INVALID
                    100, 'quarantine')
        """, (seed_product, seed_supplier))
        db_tx.commit()


# ═══════════════════════════════════════════════════════════════════════════════
#  A-9 : A PO line item must order at least 1 unit (zero-quantity order invalid)
# ═══════════════════════════════════════════════════════════════════════════════

@pytest.mark.integrity
def test_ordered_quantity_zero_rejected(
        db_tx, seed_warehouse, seed_staff, seed_supplier, seed_product):
    """
    BUSINESS RULE: A purchase order line that orders 0 units is meaningless
    and would distort procurement metrics (open PO count, committed spend).

    DB ENFORCEMENT: CHECK (ordered_quantity > 0) on po_item table.

    WHY TEST THIS: Zero or negative order quantities can result from
    calculation bugs in ordering algorithms. This CHECK is the last line of
    defence before bad data reaches the inventory system.
    """
    cur = db_tx.cursor()

    cur.execute("""
        INSERT INTO purchase_order
            (po_number, supplier_id, warehouse_id, created_by, po_status)
        VALUES ('PO-ZERO-QTY-01', %s, %s, %s, 'draft')
        RETURNING po_id
    """, (seed_supplier, seed_warehouse, seed_staff))
    po_id = cur.fetchone()[0]

    with pytest.raises(psycopg2.errors.CheckViolation):
        cur.execute("""
            INSERT INTO po_item
                (po_id, product_id, ordered_quantity, unit_price, item_status)
            VALUES (%s, %s,
                    0,      -- ordering ZERO units: INVALID
                    45.00, 'pending')
        """, (po_id, seed_product))
        db_tx.commit()
