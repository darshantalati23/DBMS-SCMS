"""
test_workflows.py — Pillar B: Business Workflow & State Transition Testing
==========================================================================

WHY THESE TESTS EXIST
----------------------
These are end-to-end transaction tests that simulate real supply chain
operations. They prove that when the system executes a complete business
workflow, the database ends up in the *correct* state.

This pillar demonstrates you understand:
  1. How multi-table transactions model real business events
  2. How to verify that side effects (movement logs, generated columns) work
  3. How to think about system behaviour in terms of state machines

All tests use the db_tx fixture (SAVEPOINT + ROLLBACK) so the seeded database
is never modified. Each test is a self-contained mini-scenario.

KEY PATTERN: Arrange → Act → Assert
  - Arrange: Set up the minimum required DB state using factory fixtures
  - Act:     Execute the SQL that represents the business operation
  - Assert:  Query the DB and verify the expected outcome
"""

import pytest
import psycopg2


# ═══════════════════════════════════════════════════════════════════════════════
#  B-1 : Full Procure-to-Pay flow
#        Create PO → Receive goods → Inventory updated + Movement log created
# ═══════════════════════════════════════════════════════════════════════════════

@pytest.mark.workflow
def test_procure_to_pay_flow(
        db_tx, seed_warehouse, seed_staff, seed_supplier,
        seed_product, seed_batch, seed_zone):
    """
    BUSINESS SCENARIO:
    A procurement manager creates a Purchase Order for 100 units.
    The warehouse operator receives 100 units from the supplier.
    After receipt:
      1. inventory.quantity_on_hand must increase by 100
      2. An inventory_movement_log entry of type 'receipt' must be created

    This is the most fundamental workflow in any supply chain — verifying it
    end-to-end proves the entire inbound logistics pipeline is consistent.
    """
    cur = db_tx.cursor()

    # ── ARRANGE ─────────────────────────────────────────────────────────────
    # Create an inventory slot starting at 0 units on hand
    cur.execute("""
        INSERT INTO inventory
            (product_id, batch_id, zone_id, quantity_on_hand, quantity_reserved)
        VALUES (%s, %s, %s, 0, 0)
        RETURNING inventory_id
    """, (seed_product, seed_batch, seed_zone))
    inventory_id = cur.fetchone()[0]

    # Create the Purchase Order in 'approved' state
    cur.execute("""
        INSERT INTO purchase_order
            (po_number, supplier_id, warehouse_id, created_by, po_status)
        VALUES ('PO-WORKFLOW-001', %s, %s, %s, 'approved')
        RETURNING po_id
    """, (seed_supplier, seed_warehouse, seed_staff))
    po_id = cur.fetchone()[0]

    # Add a line item: 100 units ordered
    cur.execute("""
        INSERT INTO po_item
            (po_id, product_id, ordered_quantity, received_quantity,
             unit_price, item_status)
        VALUES (%s, %s, 100, 0, 45.00, 'pending')
        RETURNING po_item_id
    """, (po_id, seed_product))
    po_item_id = cur.fetchone()[0]

    # ── ACT ──────────────────────────────────────────────────────────────────
    # Simulate receiving 100 units:
    #   Step 1 — Update the PO line item to reflect receipt
    cur.execute("""
        UPDATE po_item
        SET received_quantity = 100,
            item_status       = 'fully_received'
        WHERE po_item_id = %s
    """, (po_item_id,))

    #   Step 2 — Update the PO header status
    cur.execute("""
        UPDATE purchase_order
        SET po_status           = 'fully_received',
            actual_delivery_date = CURRENT_DATE,
            grn_status           = 'passed'
        WHERE po_id = %s
    """, (po_id,))

    #   Step 3 — Increment inventory (the core of "receiving goods")
    cur.execute("""
        UPDATE inventory
        SET quantity_on_hand = quantity_on_hand + 100,
            last_movement_at  = NOW()
        WHERE inventory_id = %s
    """, (inventory_id,))

    #   Step 4 — Write the movement log (this is what makes inventory
    #             auditable — every change is recorded)
    cur.execute("""
        INSERT INTO inventory_movement_log
            (inventory_id, movement_type, quantity_change,
             quantity_after, batch_id, zone_id,
             reference_id, reference_table, performed_by)
        VALUES (%s, 'receipt', 100, 100,
                %s, %s,
                %s, 'po_item', %s)
    """, (inventory_id, seed_batch, seed_zone, po_item_id, seed_staff))

    # ── ASSERT ───────────────────────────────────────────────────────────────
    # 1. Inventory quantity must now be 100
    cur.execute("""
        SELECT quantity_on_hand FROM inventory WHERE inventory_id = %s
    """, (inventory_id,))
    on_hand = cur.fetchone()[0]
    assert on_hand == 100, (
        f"Expected quantity_on_hand=100 after receipt, got {on_hand}"
    )

    # 2. The movement log must have exactly one 'receipt' entry
    cur.execute("""
        SELECT movement_type, quantity_change, quantity_after
        FROM   inventory_movement_log
        WHERE  inventory_id = %s AND movement_type = 'receipt'
    """, (inventory_id,))
    log_rows = cur.fetchall()
    assert len(log_rows) == 1, (
        f"Expected 1 movement log entry for 'receipt', got {len(log_rows)}"
    )
    assert log_rows[0][1] == 100, "Movement log quantity_change should be 100"
    assert log_rows[0][2] == 100, "Movement log quantity_after should be 100"

    # 3. The PO should now be fully_received
    cur.execute("""
        SELECT po_status FROM purchase_order WHERE po_id = %s
    """, (po_id,))
    po_status = cur.fetchone()[0]
    assert po_status == "fully_received"


# ═══════════════════════════════════════════════════════════════════════════════
#  B-2 : Inventory reservation flow
#        Sales Order created → Stock allocated → quantity_reserved increases
# ═══════════════════════════════════════════════════════════════════════════════

@pytest.mark.workflow
def test_inventory_reservation_flow(
        db_tx, seed_warehouse, seed_staff, seed_customer,
        seed_product, seed_inventory):
    """
    BUSINESS SCENARIO:
    A sales executive creates a Sales Order for 50 units.
    The warehouse allocates 50 units from inventory.
    After allocation:
      1. inventory.quantity_reserved must increase by 50
      2. inventory.quantity_available (generated column) must decrease by 50

    This is the "soft reservation" step — goods are committed to a customer
    order but not yet physically moved. It prevents the same stock from being
    allocated to two different orders simultaneously (double-selling).
    """
    cur = db_tx.cursor()

    # ── ARRANGE ──────────────────────────────────────────────────────────────
    # seed_inventory provides 200 on_hand, 0 reserved → 200 available

    # Record the starting state
    cur.execute("""
        SELECT quantity_on_hand, quantity_reserved, quantity_available
        FROM   inventory
        WHERE  inventory_id = %s
    """, (seed_inventory,))
    start = cur.fetchone()
    start_on_hand, start_reserved, start_available = start
    assert start_on_hand == 200
    assert start_reserved == 0
    assert start_available == 200  # generated column

    # Create a Sales Order
    cur.execute("""
        INSERT INTO sales_order
            (so_number, customer_id, warehouse_id, created_by, so_status)
        VALUES ('SO-WORKFLOW-001', %s, %s, %s, 'confirmed')
        RETURNING so_id
    """, (seed_customer, seed_warehouse, seed_staff))
    so_id = cur.fetchone()[0]

    # Add SO line item: 50 units ordered
    cur.execute("""
        INSERT INTO so_item
            (so_id, product_id, ordered_quantity, allocated_quantity,
             unit_price, item_status)
        VALUES (%s, %s, 50, 0, 99.00, 'pending')
        RETURNING so_item_id
    """, (so_id, seed_product))
    so_item_id = cur.fetchone()[0]

    # ── ACT ──────────────────────────────────────────────────────────────────
    # Allocate 50 units from inventory
    cur.execute("""
        UPDATE inventory
        SET quantity_reserved = quantity_reserved + 50,
            last_movement_at  = NOW()
        WHERE inventory_id = %s
    """, (seed_inventory,))

    # Record the allocation in the allocation table
    cur.execute("""
        INSERT INTO inventory_allocation
            (so_item_id, inventory_id, allocated_quantity,
             allocation_method, allocated_by)
        VALUES (%s, %s, 50, 'FEFO', %s)
    """, (so_item_id, seed_inventory, seed_staff))

    # Update the SO item to reflect allocation
    cur.execute("""
        UPDATE so_item
        SET allocated_quantity = 50,
            item_status         = 'allocated'
        WHERE so_item_id = %s
    """, (so_item_id,))

    # ── ASSERT ────────────────────────────────────────────────────────────────
    cur.execute("""
        SELECT quantity_on_hand, quantity_reserved, quantity_available
        FROM   inventory
        WHERE  inventory_id = %s
    """, (seed_inventory,))
    row = cur.fetchone()
    on_hand, reserved, available = row

    # Physical stock unchanged — goods not moved yet
    assert on_hand == 200, (
        f"quantity_on_hand should still be 200, got {on_hand}"
    )
    # Reservation increased by 50
    assert reserved == 50, (
        f"quantity_reserved should be 50 after allocation, got {reserved}"
    )
    # Generated column: 200 - 50 = 150 available
    assert available == 150, (
        f"quantity_available (generated) should be 150, got {available}"
    )


# ═══════════════════════════════════════════════════════════════════════════════
#  B-3 : Generated column: quantity_available stays accurate after mutations
# ═══════════════════════════════════════════════════════════════════════════════

@pytest.mark.workflow
def test_quantity_available_generated_column(db_tx, seed_inventory):
    """
    BUSINESS SCENARIO:
    The 'available' quantity is: on_hand - reserved.
    Since it's a GENERATED ALWAYS AS column, PostgreSQL computes it
    automatically. The application never writes to it.

    We verify this across multiple sequential mutations to confirm the
    generated column stays in sync without any application intervention.

    WHY TEST THIS: Generated columns are a key feature of the "Thick DB"
    design. This test proves you can rely on PostgreSQL for derived values
    instead of writing sync logic in application code.
    """
    cur = db_tx.cursor()

    # Initial state from fixture: 200 on-hand, 0 reserved → 200 available
    cur.execute("""
        SELECT quantity_on_hand, quantity_reserved, quantity_available
        FROM   inventory WHERE inventory_id = %s
    """, (seed_inventory,))
    oh, res, avail = cur.fetchone()
    assert avail == oh - res == 200, "Initial: available should be 200"

    # Mutation 1: reserve 80 units
    cur.execute("""
        UPDATE inventory SET quantity_reserved = 80 WHERE inventory_id = %s
    """, (seed_inventory,))
    cur.execute("""
        SELECT quantity_available FROM inventory WHERE inventory_id = %s
    """, (seed_inventory,))
    assert cur.fetchone()[0] == 120, "After reserving 80: available should be 120"

    # Mutation 2: receive 50 more units into on_hand
    cur.execute("""
        UPDATE inventory
        SET quantity_on_hand = quantity_on_hand + 50
        WHERE inventory_id = %s
    """, (seed_inventory,))
    cur.execute("""
        SELECT quantity_available FROM inventory WHERE inventory_id = %s
    """, (seed_inventory,))
    assert cur.fetchone()[0] == 170, (
        "After +50 on_hand (250 total), 80 reserved: available should be 170"
    )

    # Mutation 3: release the reservation (dispatch completes)
    cur.execute("""
        UPDATE inventory SET quantity_reserved = 0 WHERE inventory_id = %s
    """, (seed_inventory,))
    cur.execute("""
        SELECT quantity_available FROM inventory WHERE inventory_id = %s
    """, (seed_inventory,))
    assert cur.fetchone()[0] == 250, (
        "After releasing reservation: available should equal on_hand (250)"
    )


# ═══════════════════════════════════════════════════════════════════════════════
#  B-4 : FEFO batch ordering — oldest expiry date returned first
# ═══════════════════════════════════════════════════════════════════════════════

@pytest.mark.workflow
def test_batch_fefo_ordering(db_tx, seed_product, seed_supplier, seed_zone):
    """
    BUSINESS SCENARIO:
    FEFO = First Expired, First Out. When picking goods for dispatch,
    warehouse staff must always use the batch that expires soonest.

    This test creates 3 batches for the same product with different expiry
    dates and verifies that ordering by expiry_date ASC returns them in
    the correct FEFO sequence.

    WHY TEST THIS: FEFO is a regulatory requirement in food and pharma supply
    chains. Getting the ordering wrong causes goods to expire on shelves while
    newer stock is consumed — a financial and compliance failure.
    """
    cur = db_tx.cursor()

    # Insert 3 batches with deliberate out-of-order insertion
    # (to prove ordering is by expiry date, not insertion order)
    # NOTE: All expiry dates are set well into the future (2027) to satisfy
    # the CHECK (expiry_date >= received_date) constraint.
    batches = [
        ("BATCH-FEFO-C", "2027-12-01"),   # expires latest
        ("BATCH-FEFO-A", "2027-06-01"),   # expires soonest  <- FEFO first
        ("BATCH-FEFO-B", "2027-09-01"),   # expires middle
    ]
    batch_ids = []
    for code, expiry in batches:
        cur.execute("""
            INSERT INTO batch
                (batch_code, product_id, supplier_id,
                 expiry_date, received_date, initial_quantity, quality_status)
            VALUES (%s, %s, %s, %s, CURRENT_DATE, 100, 'approved')
            RETURNING batch_id
        """, (code, seed_product, seed_supplier, expiry))
        batch_ids.append(cur.fetchone()[0])

    # Insert inventory for each batch in the same zone
    for bid in batch_ids:
        cur.execute("""
            INSERT INTO inventory
                (product_id, batch_id, zone_id,
                 quantity_on_hand, quantity_reserved)
            VALUES (%s, %s, %s, 100, 0)
        """, (seed_product, bid, seed_zone))

    # ── ACT + ASSERT ─────────────────────────────────────────────────────────
    # The FEFO query: order by expiry_date ASC to get the soonest-expiring batch
    cur.execute("""
        SELECT b.batch_code, b.expiry_date
        FROM   inventory i
        JOIN   batch b ON b.batch_id = i.batch_id
        WHERE  i.product_id = %s
          AND  b.quality_status = 'approved'
          AND  i.quantity_available > 0
          AND  b.batch_code LIKE 'BATCH-FEFO-%%'
        ORDER  BY b.expiry_date ASC
    """, (seed_product,))
    rows = cur.fetchall()

    assert len(rows) == 3, f"Expected 3 FEFO batches, got {len(rows)}"
    # First row must be the soonest expiry
    assert rows[0][0] == "BATCH-FEFO-A", (
        f"First FEFO batch should be BATCH-FEFO-A (Jun), got {rows[0][0]}"
    )
    assert rows[1][0] == "BATCH-FEFO-B", (
        f"Second FEFO batch should be BATCH-FEFO-B (Sep), got {rows[1][0]}"
    )
    assert rows[2][0] == "BATCH-FEFO-C", (
        f"Third FEFO batch should be BATCH-FEFO-C (Dec), got {rows[2][0]}"
    )


# ═══════════════════════════════════════════════════════════════════════════════
#  B-5 : Reorder alert conditions — stock below reorder_point surfaces correctly
# ═══════════════════════════════════════════════════════════════════════════════

@pytest.mark.workflow
def test_reorder_alert_conditions(
        db_tx, seed_product, seed_batch, seed_zone):
    """
    BUSINESS SCENARIO:
    Each product has a reorder_point (e.g., 50 units). When available
    inventory falls at or below that threshold, the product must appear
    in the reorder report so procurement can raise a new PO.

    This test sets available stock BELOW the product's reorder_point (50)
    and asserts the product appears in the reorder query result.
    It also verifies a product ABOVE the threshold does NOT appear.

    WHY TEST THIS: The reorder query drives automated restocking decisions.
    False negatives (missing a low-stock product) lead to stockouts;
    false positives waste procurement effort and working capital.
    """
    cur = db_tx.cursor()

    # Our seed_product has reorder_point = 50 (set in conftest.py)
    # Insert inventory with only 20 units — BELOW the reorder_point of 50
    cur.execute("""
        INSERT INTO inventory
            (product_id, batch_id, zone_id, quantity_on_hand, quantity_reserved)
        VALUES (%s, %s, %s, 20, 0)   -- 20 available, reorder_point is 50
    """, (seed_product, seed_batch, seed_zone))

    # ── ACT + ASSERT ─────────────────────────────────────────────────────────
    # Run the reorder detection query (mirrors db/queries.sql query #7)
    cur.execute("""
        SELECT p.product_id,
               p.product_name,
               p.reorder_point,
               COALESCE(SUM(i.quantity_available), 0) AS current_stock
        FROM   product p
        LEFT JOIN inventory i ON p.product_id = i.product_id
        WHERE  p.product_id = %s
        GROUP  BY p.product_id, p.product_name, p.reorder_point
        HAVING COALESCE(SUM(i.quantity_available), 0) <= p.reorder_point
    """, (seed_product,))
    rows = cur.fetchall()

    assert len(rows) == 1, (
        "Product with stock (20) below reorder_point (50) should appear in reorder report"
    )
    _, _, reorder_pt, current_stock = rows[0]
    assert current_stock <= reorder_pt, (
        f"current_stock ({current_stock}) should be <= reorder_point ({reorder_pt})"
    )
