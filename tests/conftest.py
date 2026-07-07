"""
conftest.py — Shared pytest fixtures for the SCMS test suite
=============================================================

Design philosophy: "Real DB, Real Constraints, Zero Pollution"

Every test that touches the database:
  1. Connects to the real PostgreSQL SCMS schema (with seeded data)
  2. Wraps its work in a SAVEPOINT
  3. Always rolls back to that SAVEPOINT when done

This means:
  - We test against real constraints and real data (no mocks)
  - No test ever leaves dirty data in the database
  - Tests can run in any order without interfering with each other
  - No separate "test database" is required

Connection is configured via environment variables (same as the CLI):
  PGHOST, PGPORT, PGDATABASE, PGUSER, PGPASSWORD

If PGPASSWORD is not set, tests will be skipped rather than hang on a prompt.
"""

import os
import sys
import pytest
import psycopg2
import psycopg2.extras

# ── Add src/ to path so CLI tests can import or invoke scms_cli.py ──────────
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

# ── Connection helpers ───────────────────────────────────────────────────────

def _get_dsn() -> dict:
    """Build a psycopg2 DSN dict from environment variables."""
    return {
        "host":     os.environ.get("PGHOST",     "localhost"),
        "port":     int(os.environ.get("PGPORT", "5432")),
        "dbname":   os.environ.get("PGDATABASE", "postgres"),
        "user":     os.environ.get("PGUSER",     "postgres"),
        "password": os.environ.get("PGPASSWORD", ""),
        "options":  "-c search_path=scms,public",
    }


# ── Session-scoped connection ────────────────────────────────────────────────

@pytest.fixture(scope="session")
def db_conn():
    """
    A single psycopg2 connection shared across the entire test session.

    Scope: session — one connection, opened once, closed at the end.
    autocommit=False so that SAVEPOINT / ROLLBACK work correctly.

    If the connection fails (wrong creds, DB not running), ALL tests that
    depend on this fixture will be skipped with a clear message.
    """
    dsn = _get_dsn()

    if not dsn["password"]:
        pytest.skip(
            "PGPASSWORD environment variable not set. "
            "Export it before running tests:\n"
            "  $env:PGPASSWORD='your_password'  (PowerShell)\n"
            "  export PGPASSWORD=your_password   (bash)"
        )

    try:
        conn = psycopg2.connect(**dsn)
        conn.autocommit = False
    except psycopg2.OperationalError as e:
        pytest.skip(f"Cannot connect to PostgreSQL: {e}")

    yield conn
    conn.close()


# ── Per-test SAVEPOINT isolation ─────────────────────────────────────────────

@pytest.fixture
def db_tx(db_conn):
    """
    Wraps each individual test in a SAVEPOINT + ROLLBACK.

    Usage in tests:
        def test_something(db_tx):
            cur = db_tx.cursor()
            cur.execute("INSERT INTO ...")   # this will be rolled back
            ...

    The SAVEPOINT is always rolled back -- even if the test fails --
    so the seeded database is never corrupted.
    """
    with db_conn.cursor() as cur:
        cur.execute("SAVEPOINT test_isolation")
    yield db_conn
    with db_conn.cursor() as cur:
        cur.execute("ROLLBACK TO SAVEPOINT test_isolation")
        cur.execute("RELEASE SAVEPOINT test_isolation")


# ── Minimal test-data factories ───────────────────────────────────────────────
# These return the IDs of rows created so tests can reference them.
# All inserts happen inside the db_tx SAVEPOINT and are rolled back after.

@pytest.fixture
def seed_warehouse(db_tx):
    """Insert a minimal warehouse row; return its warehouse_id."""
    cur = db_tx.cursor()
    cur.execute("""
        INSERT INTO warehouse
            (warehouse_code, warehouse_name, warehouse_type, city, is_active)
        VALUES ('WH-TEST-99', 'Test Warehouse', 'regional', 'Testville', TRUE)
        RETURNING warehouse_id
    """)
    wid = cur.fetchone()[0]
    return wid


@pytest.fixture
def seed_staff(db_tx, seed_warehouse):
    """Insert a minimal staff row; return staff_id."""
    cur = db_tx.cursor()
    cur.execute("""
        INSERT INTO staff
            (warehouse_id, employee_code, full_name, role, is_active)
        VALUES (%s, 'EMP-TEST-99', 'Test Staff', 'admin', TRUE)
        RETURNING staff_id
    """, (seed_warehouse,))
    return cur.fetchone()[0]


@pytest.fixture
def seed_supplier(db_tx):
    """Insert a minimal supplier row; return supplier_id."""
    cur = db_tx.cursor()
    cur.execute("""
        INSERT INTO supplier
            (supplier_code, company_name, credit_limit, supplier_tier,
             on_time_delivery_rate, quality_rejection_rate, is_active)
        VALUES ('SUP-TEST-99', 'Test Supplier Ltd', 100000, 'approved',
                90.0, 2.0, TRUE)
        RETURNING supplier_id
    """)
    return cur.fetchone()[0]


@pytest.fixture
def seed_category(db_tx):
    """Insert a minimal product category; return category_id."""
    cur = db_tx.cursor()
    cur.execute("""
        INSERT INTO product_category (category_name, description)
        VALUES ('Test Category', 'Category for test isolation')
        RETURNING category_id
    """)
    return cur.fetchone()[0]


@pytest.fixture
def seed_product(db_tx, seed_category):
    """Insert a minimal product row; return product_id."""
    cur = db_tx.cursor()
    cur.execute("""
        INSERT INTO product
            (category_id, sku_code, product_name, unit_of_measure,
             reorder_point, reorder_quantity, standard_cost, is_active)
        VALUES (%s, 'SKU-TEST-9999', 'Test Product Unit', 'Unit',
                50, 100, 99.00, TRUE)
        RETURNING product_id
    """, (seed_category,))
    return cur.fetchone()[0]


@pytest.fixture
def seed_zone(db_tx, seed_warehouse):
    """Insert a storage zone in the test warehouse; return zone_id."""
    cur = db_tx.cursor()
    cur.execute("""
        INSERT INTO warehouse_zone
            (warehouse_id, zone_code, zone_type, is_active)
        VALUES (%s, 'ZONE-TEST-99', 'storage', TRUE)
        RETURNING zone_id
    """, (seed_warehouse,))
    return cur.fetchone()[0]


@pytest.fixture
def seed_batch(db_tx, seed_product, seed_supplier):
    """Insert a minimal approved batch; return batch_id."""
    cur = db_tx.cursor()
    cur.execute("""
        INSERT INTO batch
            (batch_code, product_id, supplier_id,
             expiry_date, received_date, initial_quantity, quality_status)
        VALUES ('BATCH-TEST-99', %s, %s,
                CURRENT_DATE + INTERVAL '365 days',
                CURRENT_DATE, 500, 'approved')
        RETURNING batch_id
    """, (seed_product, seed_supplier))
    return cur.fetchone()[0]


@pytest.fixture
def seed_inventory(db_tx, seed_product, seed_batch, seed_zone):
    """
    Insert an inventory row (200 on-hand, 0 reserved).
    Returns inventory_id.
    """
    cur = db_tx.cursor()
    cur.execute("""
        INSERT INTO inventory
            (product_id, batch_id, zone_id, quantity_on_hand, quantity_reserved)
        VALUES (%s, %s, %s, 200, 0)
        RETURNING inventory_id
    """, (seed_product, seed_batch, seed_zone))
    return cur.fetchone()[0]


@pytest.fixture
def seed_customer(db_tx):
    """Insert a minimal customer row; return customer_id."""
    cur = db_tx.cursor()
    cur.execute("""
        INSERT INTO customer
            (customer_code, customer_type, company_name,
             credit_limit, outstanding_balance, kyc_verified)
        VALUES ('CUST-TEST-99', 'retail', 'Test Customer Co',
                50000, 0, TRUE)
        RETURNING customer_id
    """)
    return cur.fetchone()[0]
