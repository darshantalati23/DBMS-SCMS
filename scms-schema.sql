DROP SCHEMA IF EXISTS scms CASCADE;
CREATE SCHEMA scms;
SET search_path TO scms;

-- ============================================================
--  SECTION 1 — ENUM TYPES
--  Defined once here, referenced by column definitions below.
-- ============================================================

CREATE TYPE supplier_tier_enum AS ENUM (
    'strategic', 'preferred', 'approved', 'blacklisted'
);

CREATE TYPE warehouse_type_enum AS ENUM (
    'central', 'regional', 'cold_storage', 'transit_hub'
);

CREATE TYPE zone_type_enum AS ENUM (
    'receiving', 'storage', 'picking', 'dispatch', 'quarantine'
);

CREATE TYPE quality_status_enum AS ENUM (
    'approved', 'quarantine', 'rejected'
);

CREATE TYPE po_status_enum AS ENUM (
    'draft', 'submitted', 'approved',
    'partially_received', 'fully_received', 'cancelled'
);

CREATE TYPE grn_status_enum AS ENUM (
    'pending_inspection', 'passed', 'failed', 'putaway_done'
);

CREATE TYPE payment_status_enum AS ENUM (
    'unpaid', 'partially_paid', 'paid'
);

CREATE TYPE item_status_po_enum AS ENUM (
    'pending', 'partially_received', 'fully_received', 'cancelled'
);

CREATE TYPE customer_type_enum AS ENUM (
    'retail', 'wholesale', 'institutional', 'ecommerce_platform'
);

CREATE TYPE so_status_enum AS ENUM (
    'draft', 'confirmed', 'allocated', 'picking',
    'packed', 'dispatched', 'delivered', 'cancelled', 'returned'
);

CREATE TYPE priority_enum AS ENUM (
    'standard', 'express', 'urgent'
);

CREATE TYPE item_status_so_enum AS ENUM (
    'pending', 'allocated', 'picked', 'shipped', 'cancelled'
);

CREATE TYPE shipment_status_enum AS ENUM (
    'scheduled', 'loading', 'in_transit',
    'out_for_delivery', 'delivered', 'failed', 'returned'
);

CREATE TYPE return_reason_enum AS ENUM (
    'damaged', 'wrong_item', 'quality_issue', 'excess', 'expired'
);

CREATE TYPE return_status_enum AS ENUM (
    'requested', 'approved', 'picked_up',
    'inspected', 'restocked', 'refunded'
);

CREATE TYPE condition_arrival_enum AS ENUM (
    'resellable', 'damaged', 'expired', 'quarantine'
);

CREATE TYPE staff_role_enum AS ENUM (
    'procurement_manager', 'warehouse_operator', 'sales_executive',
    'logistics_coordinator', 'admin', 'auditor'
);

CREATE TYPE allocation_method_enum AS ENUM (
    'FEFO', 'manual'
);

CREATE TYPE audit_action_enum AS ENUM (
    'INSERT', 'UPDATE', 'DELETE'
);

CREATE TYPE alert_status_enum AS ENUM (
    'open', 'po_raised', 'dismissed'
);

CREATE TYPE movement_type_enum AS ENUM (
    'receipt', 'allocation', 'deallocation',
    'dispatch', 'return', 'adjustment', 'write_off'
);

-- ============================================================
--  SECTION 2 — WAREHOUSE
--  Created before STAFF because STAFF references WAREHOUSE.
-- ============================================================

CREATE TABLE warehouse (
    warehouse_id            SERIAL              PRIMARY KEY,
    warehouse_code          VARCHAR(20)         NOT NULL UNIQUE,
    warehouse_name          VARCHAR(200)        NOT NULL,
    warehouse_type          warehouse_type_enum NOT NULL,
    city                    VARCHAR(100),
    state                   VARCHAR(100),
    pincode                 VARCHAR(10),
    total_capacity_sqft     INT,
    temperature_controlled  BOOLEAN             NOT NULL DEFAULT FALSE,
    is_active               BOOLEAN             NOT NULL DEFAULT TRUE
);

-- ============================================================
--  SECTION 3 — STAFF
-- ============================================================

CREATE TABLE staff (
    staff_id        SERIAL          PRIMARY KEY,
    warehouse_id    INT,            -- nullable FK → warehouse
    employee_code   VARCHAR(20)     NOT NULL UNIQUE,
    full_name       VARCHAR(150)    NOT NULL,
    role            staff_role_enum NOT NULL,
    email           VARCHAR(150)    UNIQUE,
    phone           VARCHAR(20),
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    last_login      TIMESTAMP,

    CONSTRAINT fk_staff_warehouse
        FOREIGN KEY (warehouse_id)
        REFERENCES warehouse (warehouse_id)
        ON DELETE SET NULL
);

-- ============================================================
--  SECTION 4 — SUPPLIER  [Strong Entity]
-- ============================================================

CREATE TABLE supplier (
    supplier_id             SERIAL              PRIMARY KEY,
    supplier_code           VARCHAR(20)         NOT NULL UNIQUE,
    company_name            VARCHAR(200)        NOT NULL,
    contact_person          VARCHAR(100),
    email                   VARCHAR(150)        UNIQUE,
    phone                   VARCHAR(20),
    gstin                   VARCHAR(15)         UNIQUE,
    city                    VARCHAR(100),
    state                   VARCHAR(100),
    country                 VARCHAR(100),
    credit_limit            NUMERIC(14,2)       NOT NULL DEFAULT 0,
    payment_terms_days      INT,
    supplier_tier           supplier_tier_enum  NOT NULL DEFAULT 'approved',
    on_time_delivery_rate   NUMERIC(5,2),
    quality_rejection_rate  NUMERIC(5,2),
    supplier_rating  NUMERIC(5,2)
                            GENERATED ALWAYS AS (
                                ROUND((on_time_delivery_rate * 0.6) + ((100 - quality_rejection_rate) * 0.4), 2)
                            ) STORED,
    is_active               BOOLEAN             NOT NULL DEFAULT TRUE,
    created_at              TIMESTAMP           DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP           DEFAULT CURRENT_TIMESTAMP
);


-- ============================================================
--  SECTION 5 — PRODUCT CATALOG
-- ============================================================

-- ── 5.1 PRODUCT_CATEGORY  [Strong Entity — Recursive] ───────

CREATE TABLE product_category (
    category_id         SERIAL          PRIMARY KEY,
    category_name       VARCHAR(150)    NOT NULL UNIQUE,
    parent_category_id  INT,
    description         TEXT,

    CONSTRAINT fk_category_parent
        FOREIGN KEY (parent_category_id)
        REFERENCES product_category (category_id)
        ON DELETE SET NULL
        DEFERRABLE INITIALLY DEFERRED
);

-- ── 5.2 PRODUCT  [Strong Entity] ────────────────────────────

CREATE TABLE product (
    product_id          SERIAL          PRIMARY KEY,
    category_id         INT             NOT NULL,
    sku_code            VARCHAR(50)     NOT NULL UNIQUE,
    product_name        VARCHAR(200)    NOT NULL,
    unit_of_measure     VARCHAR(20)     NOT NULL,
    is_perishable       BOOLEAN         NOT NULL DEFAULT FALSE,
    shelf_life_days     INT,
    standard_cost       NUMERIC(14,2),
    reorder_point       INT             NOT NULL DEFAULT 0,
    reorder_quantity    INT             NOT NULL DEFAULT 0,
    weight_kg           NUMERIC(10,3),
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,

    CONSTRAINT fk_product_category
        FOREIGN KEY (category_id)
        REFERENCES product_category (category_id)
);

-- ── 5.3 SUPPLIES  [Associative Entity — M:N Supplier×Product]

CREATE TABLE supplies (
    supplier_product_id     SERIAL          PRIMARY KEY,
    supplier_id             INT             NOT NULL,
    product_id              INT             NOT NULL,
    unit_price              NUMERIC(14,2)   NOT NULL,
    currency                CHAR(3)         NOT NULL DEFAULT 'INR',
    minimum_order_qty       INT,
    lead_time_days          INT,
    price_valid_from        DATE            NOT NULL,
    price_valid_until       DATE,
    is_preferred_supplier   BOOLEAN         NOT NULL DEFAULT FALSE,

    CONSTRAINT fk_supplies_supplier
        FOREIGN KEY (supplier_id)
        REFERENCES supplier (supplier_id),
    CONSTRAINT fk_supplies_product
        FOREIGN KEY (product_id)
        REFERENCES product (product_id),
    CONSTRAINT uq_supplies_contract
        UNIQUE (supplier_id, product_id, price_valid_from)
);


-- ============================================================
--  SECTION 6 — WAREHOUSE ZONE  [Weak Entity — owner: Warehouse]
-- ============================================================

CREATE TABLE warehouse_zone (
    zone_id             SERIAL          PRIMARY KEY,
    warehouse_id        INT             NOT NULL,
    zone_code           VARCHAR(30)     NOT NULL,
    zone_type           zone_type_enum  NOT NULL,
    capacity_units      INT,
    temperature_zone    VARCHAR(20),
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,

    CONSTRAINT fk_zone_warehouse
        FOREIGN KEY (warehouse_id)
        REFERENCES warehouse (warehouse_id)
        ON DELETE CASCADE,
    CONSTRAINT uq_zone_per_warehouse
        UNIQUE (warehouse_id, zone_code)
);

-- ============================================================
--  SECTION 7 — PROCUREMENT CHAIN
-- ============================================================

-- ── 7.1 PURCHASE_ORDER  [Strong Entity] ─────────────────────

CREATE TABLE purchase_order (
    po_id                   SERIAL              PRIMARY KEY,
    po_number               VARCHAR(30)         NOT NULL UNIQUE,
    supplier_id             INT                 NOT NULL,
    warehouse_id            INT                 NOT NULL,
    created_by              INT                 NOT NULL,
    approved_by             INT,
    po_status               po_status_enum      NOT NULL DEFAULT 'draft',
    order_date              DATE                NOT NULL DEFAULT CURRENT_DATE,
    expected_delivery_date  DATE,
    actual_delivery_date    DATE,
    received_by             INT,
    grn_status              grn_status_enum,
    rejection_reason        TEXT,
    payment_terms           VARCHAR(50),
    payment_status          payment_status_enum NOT NULL DEFAULT 'unpaid',
    total_amount            NUMERIC(14,2)       DEFAULT 0,

    CONSTRAINT fk_po_supplier
        FOREIGN KEY (supplier_id)
        REFERENCES supplier (supplier_id),
    CONSTRAINT fk_po_warehouse
        FOREIGN KEY (warehouse_id)
        REFERENCES warehouse (warehouse_id),
    CONSTRAINT fk_po_created_by
        FOREIGN KEY (created_by)
        REFERENCES staff (staff_id),
    CONSTRAINT fk_po_approved_by
        FOREIGN KEY (approved_by)
        REFERENCES staff (staff_id),
    CONSTRAINT fk_po_received_by
        FOREIGN KEY (received_by)
        REFERENCES staff (staff_id)
);

-- ── 7.2 PO_ITEM  [Weak Entity — owner: Purchase_Order] ──────

CREATE TABLE po_item (
    po_item_id          SERIAL              PRIMARY KEY,
    po_id               INT                 NOT NULL,
    product_id          INT                 NOT NULL,
    supplier_product_id INT,
    ordered_quantity    INT                 NOT NULL CHECK (ordered_quantity > 0),
    received_quantity   INT                 NOT NULL DEFAULT 0,
    unit_price          NUMERIC(14,2)       NOT NULL,
    line_total          NUMERIC(14,2)
                            GENERATED ALWAYS AS
                            (ordered_quantity * unit_price) STORED,
    item_status         item_status_po_enum NOT NULL DEFAULT 'pending',

    CONSTRAINT fk_po_item_po
        FOREIGN KEY (po_id)
        REFERENCES purchase_order (po_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_po_item_product
        FOREIGN KEY (product_id)
        REFERENCES product (product_id),
    CONSTRAINT fk_po_item_supplies
        FOREIGN KEY (supplier_product_id)
        REFERENCES supplies (supplier_product_id)
        ON DELETE SET NULL,
    CONSTRAINT uq_po_item
        UNIQUE (po_id, product_id),
    CONSTRAINT chk_received_lte_ordered
        CHECK (received_quantity <= ordered_quantity)
);

-- ── 7.3 BATCH  [Strong Entity] ───────────────────────────────

CREATE TABLE batch (
    batch_id            SERIAL              PRIMARY KEY,
    batch_code          VARCHAR(50)         NOT NULL UNIQUE,
    product_id          INT                 NOT NULL,
    supplier_id         INT                 NOT NULL,
    po_item_id          INT,
    manufactured_date   DATE,
    expiry_date         DATE                NOT NULL,
    received_date       DATE                NOT NULL DEFAULT CURRENT_DATE,
    initial_quantity    INT                 NOT NULL CHECK (initial_quantity > 0),
    unit_of_measure     VARCHAR(20),
    quality_status      quality_status_enum NOT NULL DEFAULT 'quarantine',

    CONSTRAINT fk_batch_product
        FOREIGN KEY (product_id)
        REFERENCES product (product_id),
    CONSTRAINT fk_batch_supplier
        FOREIGN KEY (supplier_id)
        REFERENCES supplier (supplier_id),
    CONSTRAINT fk_batch_po_item
        FOREIGN KEY (po_item_id)
        REFERENCES po_item (po_item_id)
        ON DELETE SET NULL,
    CONSTRAINT chk_expiry_after_received
        CHECK (expiry_date >= received_date)
);

-- ============================================================
--  SECTION 8 — SALES CHAIN
-- ============================================================

-- ── 8.1 CUSTOMER  [Strong Entity] ───────────────────────────

CREATE TABLE customer (
    customer_id         SERIAL              PRIMARY KEY,
    customer_code       VARCHAR(20)         NOT NULL UNIQUE,
    customer_type       customer_type_enum  NOT NULL,
    company_name        VARCHAR(200)        NOT NULL,
    contact_person      VARCHAR(100),
    email               VARCHAR(150)        UNIQUE,
    phone               VARCHAR(20),
    billing_address     VARCHAR(300),
    outstanding_balance NUMERIC(12, 2)      NOT NULL DEFAULT 0.00,
    credit_limit        NUMERIC(14,2)       NOT NULL DEFAULT 0,
    is_credit_hold      BOOLEAN             NOT NULL DEFAULT FALSE,
    payment_terms_days  INT,
    kyc_verified        BOOLEAN             NOT NULL DEFAULT FALSE
);

-- ── 8.2 SALES_ORDER  [Strong Entity] ────────────────────────

CREATE TABLE sales_order (
    so_id                   SERIAL              PRIMARY KEY,
    so_number               VARCHAR(30)         NOT NULL UNIQUE,
    customer_id             INT                 NOT NULL,
    warehouse_id            INT                 NOT NULL,
    created_by              INT                 NOT NULL,
    so_status               so_status_enum      NOT NULL DEFAULT 'draft',
    order_date              DATE                NOT NULL DEFAULT CURRENT_DATE,
    requested_delivery_date DATE,
    priority_level          priority_enum       NOT NULL DEFAULT 'standard',
    dest_street             VARCHAR(200),
    dest_city               VARCHAR(100),
    dest_state              VARCHAR(100),
    dest_pincode            VARCHAR(10),
    total_amount            NUMERIC(14,2)       DEFAULT 0,
    payment_status          payment_status_enum NOT NULL DEFAULT 'unpaid',

    CONSTRAINT fk_so_customer
        FOREIGN KEY (customer_id)
        REFERENCES customer (customer_id),
    CONSTRAINT fk_so_warehouse
        FOREIGN KEY (warehouse_id)
        REFERENCES warehouse (warehouse_id),
    CONSTRAINT fk_so_created_by
        FOREIGN KEY (created_by)
        REFERENCES staff (staff_id)
);

-- ── 8.3 SO_ITEM  [Weak Entity — owner: Sales_Order] ─────────

CREATE TABLE so_item (
    so_item_id          SERIAL              PRIMARY KEY,
    so_id               INT                 NOT NULL,
    product_id          INT                 NOT NULL,
    ordered_quantity    INT                 NOT NULL CHECK (ordered_quantity > 0),
    allocated_quantity  INT                 NOT NULL DEFAULT 0,
    picked_quantity     INT                 NOT NULL DEFAULT 0,
    shipped_quantity    INT                 NOT NULL DEFAULT 0,
    unit_price          NUMERIC(14,2)       NOT NULL,
    line_total          NUMERIC(14,2)
                            GENERATED ALWAYS AS
                            (ordered_quantity * unit_price) STORED,
    item_status         item_status_so_enum NOT NULL DEFAULT 'pending',

    CONSTRAINT fk_so_item_so
        FOREIGN KEY (so_id)
        REFERENCES sales_order (so_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_so_item_product
        FOREIGN KEY (product_id)
        REFERENCES product (product_id),
    CONSTRAINT uq_so_item
        UNIQUE (so_id, product_id),
    CONSTRAINT chk_allocated_lte_ordered
        CHECK (allocated_quantity <= ordered_quantity),
    CONSTRAINT chk_picked_lte_allocated
        CHECK (picked_quantity <= allocated_quantity),
    CONSTRAINT chk_shipped_lte_picked
        CHECK (shipped_quantity <= picked_quantity)
);

-- ============================================================
--  SECTION 9 — INVENTORY
-- ============================================================

-- ── 9.1 INVENTORY  [Ternary Associative — Product×Batch×Zone]

CREATE TABLE inventory (
    inventory_id        SERIAL          PRIMARY KEY,
    product_id          INT             NOT NULL,
    batch_id            INT             NOT NULL,
    zone_id             INT             NOT NULL,
    quantity_on_hand    INT             NOT NULL DEFAULT 0,
    quantity_reserved   INT             NOT NULL DEFAULT 0,
    quantity_available  INT
                            GENERATED ALWAYS AS
                            (quantity_on_hand - quantity_reserved) STORED,
    last_movement_at    TIMESTAMP       DEFAULT NOW(),

    CONSTRAINT fk_inventory_product
        FOREIGN KEY (product_id)
        REFERENCES product (product_id),
    CONSTRAINT fk_inventory_batch
        FOREIGN KEY (batch_id)
        REFERENCES batch (batch_id),
    CONSTRAINT fk_inventory_zone
        FOREIGN KEY (zone_id)
        REFERENCES warehouse_zone (zone_id),
    CONSTRAINT uq_inventory_batch_zone
        UNIQUE (batch_id, zone_id),
    CONSTRAINT chk_on_hand_non_negative
        CHECK (quantity_on_hand >= 0),
    CONSTRAINT chk_reserved_lte_on_hand
        CHECK (quantity_reserved <= quantity_on_hand)
);

-- ── 9.2 INVENTORY_ALLOCATION  [Associative — SO_Item×Inventory]

CREATE TABLE inventory_allocation (
    allocation_id       SERIAL                  PRIMARY KEY,
    so_item_id          INT                     NOT NULL,
    inventory_id        INT                     NOT NULL,
    allocated_quantity  INT                     NOT NULL CHECK (allocated_quantity > 0),
    allocation_method   allocation_method_enum  NOT NULL DEFAULT 'FEFO',
    allocated_at        TIMESTAMP               NOT NULL DEFAULT NOW(),
    allocated_by        INT,

    CONSTRAINT fk_alloc_so_item
        FOREIGN KEY (so_item_id)
        REFERENCES so_item (so_item_id),
    CONSTRAINT fk_alloc_inventory
        FOREIGN KEY (inventory_id)
        REFERENCES inventory (inventory_id),
    CONSTRAINT fk_alloc_staff
        FOREIGN KEY (allocated_by)
        REFERENCES staff (staff_id)
        ON DELETE SET NULL
);

-- ============================================================
--  SECTION 10 — LOGISTICS
-- ============================================================

-- ── 10.1 SHIPMENT  [Strong Entity] ──────────────────────────

CREATE TABLE shipment (
    shipment_id             SERIAL                  PRIMARY KEY,
    shipment_number         VARCHAR(30)             NOT NULL UNIQUE,
    origin_warehouse_id     INT                     NOT NULL,
    vehicle_registration    VARCHAR(20),
    carrier_name            VARCHAR(100),
    driver_name             VARCHAR(100),
    driver_phone            VARCHAR(20),
    shipment_status         shipment_status_enum    NOT NULL DEFAULT 'scheduled',
    dispatch_at             TIMESTAMP,
    estimated_arrival       TIMESTAMP,
    actual_arrival          TIMESTAMP,
    total_weight_kg         NUMERIC(10,2),
    total_volume_cubic_m    NUMERIC(10,3),
    freight_cost            NUMERIC(14,2),

    CONSTRAINT fk_shipment_warehouse
        FOREIGN KEY (origin_warehouse_id)
        REFERENCES warehouse (warehouse_id)
);

-- ── 10.2 SHIPMENT_ITEM  [Weak Entity — owner: Shipment] ─────

CREATE TABLE shipment_item (
    shipment_item_id    SERIAL  PRIMARY KEY,
    shipment_id         INT     NOT NULL,
    so_item_id          INT     NOT NULL,
    quantity_shipped    INT     NOT NULL CHECK (quantity_shipped > 0),

    CONSTRAINT fk_ship_item_shipment
        FOREIGN KEY (shipment_id)
        REFERENCES shipment (shipment_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_ship_item_so_item
        FOREIGN KEY (so_item_id)
        REFERENCES so_item (so_item_id),
    CONSTRAINT uq_ship_item
        UNIQUE (shipment_id, so_item_id)
);

-- ============================================================
--  SECTION 11 — RETURNS
-- ============================================================

-- ── 11.1 RETURN_REQUEST  [Strong Entity] ────────────────────

CREATE TABLE return_request (
    return_id       SERIAL              PRIMARY KEY,
    so_id           INT                 NOT NULL,
    customer_id     INT                 NOT NULL,
    approved_by     INT,
    return_reason   return_reason_enum  NOT NULL,
    return_status   return_status_enum  NOT NULL DEFAULT 'requested',
    requested_at    TIMESTAMP           NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_return_so
        FOREIGN KEY (so_id)
        REFERENCES sales_order (so_id),
    CONSTRAINT fk_return_customer
        FOREIGN KEY (customer_id)
        REFERENCES customer (customer_id),
    CONSTRAINT fk_return_approved_by
        FOREIGN KEY (approved_by)
        REFERENCES staff (staff_id)
        ON DELETE SET NULL
);

-- ── 11.2 RETURN_ITEM  [Weak Entity — owner: Return_Request] ─

CREATE TABLE return_item (
    return_item_id              SERIAL                  PRIMARY KEY,
    return_id                   INT                     NOT NULL,
    so_item_id                  INT                     NOT NULL,
    returned_quantity           INT                     NOT NULL CHECK (returned_quantity > 0),
    condition_on_arrival        condition_arrival_enum  NOT NULL,
    restocked_to_inventory_id   INT,
    disposal_method             VARCHAR(100),

    CONSTRAINT fk_return_item_request
        FOREIGN KEY (return_id)
        REFERENCES return_request (return_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_return_item_so_item
        FOREIGN KEY (so_item_id)
        REFERENCES so_item (so_item_id),
    CONSTRAINT fk_return_item_inventory
        FOREIGN KEY (restocked_to_inventory_id)
        REFERENCES inventory (inventory_id)
        ON DELETE SET NULL,
    CONSTRAINT uq_return_item
        UNIQUE (return_id, so_item_id)
);

-- ============================================================
--  SECTION 12 — LOG and ALERT TABLES
-- ============================================================

-- ── 12.1 REORDER_ALERT ──────────────────────────────────────

CREATE TABLE reorder_alert (
    alert_id                SERIAL              PRIMARY KEY,
    product_id              INT                 NOT NULL,
    warehouse_id            INT                 NOT NULL,
    preferred_supplier_id   INT,
    current_stock           INT                 NOT NULL,
    reorder_point           INT                 NOT NULL,
    suggested_order_quantity INT                NOT NULL,
    alert_status            alert_status_enum   NOT NULL DEFAULT 'open',
    triggered_at            TIMESTAMP           NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_alert_product
        FOREIGN KEY (product_id)
        REFERENCES product (product_id),
    CONSTRAINT fk_alert_warehouse
        FOREIGN KEY (warehouse_id)
        REFERENCES warehouse (warehouse_id),
    CONSTRAINT fk_alert_supplier
        FOREIGN KEY (preferred_supplier_id)
        REFERENCES supplier (supplier_id)
        ON DELETE SET NULL
);

-- ── 12.2 AUDIT_LOG ──────────────────────────────────────────

CREATE TABLE audit_log (
    log_id          BIGSERIAL               PRIMARY KEY,
    staff_id        INT,
    action_type     audit_action_enum       NOT NULL,
    table_name      VARCHAR(50)             NOT NULL,
    record_id       INT                     NOT NULL,
    old_value       JSONB,
    new_value       JSONB,
    performed_at    TIMESTAMP               NOT NULL DEFAULT NOW(),
    ip_address      VARCHAR(45),

    CONSTRAINT fk_audit_staff
        FOREIGN KEY (staff_id)
        REFERENCES staff (staff_id)
        ON DELETE SET NULL
);

-- ── 12.3 INVENTORY_MOVEMENT_LOG ─────────────────────────────

CREATE TABLE inventory_movement_log (
    movement_id     BIGSERIAL               PRIMARY KEY,
    inventory_id    INT                     NOT NULL,
    movement_type   movement_type_enum      NOT NULL,
    quantity_change INT                     NOT NULL,
    quantity_after  INT                     NOT NULL,
    batch_id        INT,
    zone_id         INT,
    reference_id    INT,
    reference_table VARCHAR(50),
    performed_by    INT,
    performed_at    TIMESTAMP               NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_mvt_inventory
        FOREIGN KEY (inventory_id)
        REFERENCES inventory (inventory_id),
    CONSTRAINT fk_mvt_batch
        FOREIGN KEY (batch_id)
        REFERENCES batch (batch_id)
        ON DELETE SET NULL,
    CONSTRAINT fk_mvt_zone
        FOREIGN KEY (zone_id)
        REFERENCES warehouse_zone (zone_id)
        ON DELETE SET NULL,
    CONSTRAINT fk_mvt_staff
        FOREIGN KEY (performed_by)
        REFERENCES staff (staff_id)
        ON DELETE SET NULL
);

-- ============================================================
--  DONE — Sanity check: list all tables created
-- ============================================================

SELECT table_name
FROM   information_schema.tables
WHERE  table_schema = 'scms'
ORDER  BY table_name;