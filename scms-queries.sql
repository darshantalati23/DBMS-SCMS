-- 1. Identifies customers whose outstanding balance exceeds their approved credit limit, triggering a financial risk flag for the accounts receivable team to escalate.
SELECT company_name, outstanding_balance, credit_limit 
FROM customer 
WHERE outstanding_balance > credit_limit;

-- 2. Ranks all active, non-cancelled sales orders by lifetime revenue contribution per customer, supporting strategic account prioritisation and key account management decisions.
SELECT c.customer_code, c.company_name, 
       COUNT(so.so_id) AS total_orders,
       SUM(so.total_amount) AS lifetime_revenue
FROM customer c
JOIN sales_order so ON c.customer_id = so.customer_id
WHERE so.so_status != 'cancelled'
GROUP BY c.customer_id, c.customer_code, c.company_name
ORDER BY lifetime_revenue DESC
LIMIT 10;

-- 3. Quantifies the total on-hand inventory value per warehouse at standard cost, enabling finance to report working capital tied up in stock by location.
SELECT w.warehouse_code, w.warehouse_name,
       SUM(i.quantity_on_hand * p.standard_cost) AS total_inventory_value
FROM inventory i
JOIN product p ON i.product_id = p.product_id
JOIN warehouse_zone z ON i.zone_id = z.zone_id
JOIN warehouse w ON z.warehouse_id = w.warehouse_id
GROUP BY w.warehouse_id, w.warehouse_code, w.warehouse_name
ORDER BY total_inventory_value DESC;

-- 4. Flags all approved batches expiring within 60 days with their residual quantity and potential write-off value, enabling proactive markdown or liquidation decisions.
SELECT p.sku_code, p.product_name, b.batch_code, b.expiry_date, 
       i.quantity_available,
       (i.quantity_available * p.standard_cost) AS potential_financial_loss
FROM inventory i
JOIN batch b ON i.batch_id = b.batch_id
JOIN product p ON i.product_id = p.product_id
WHERE b.expiry_date <= CURRENT_DATE + INTERVAL '60 days'
  AND i.quantity_available > 0
  AND b.quality_status = 'approved'
ORDER BY potential_financial_loss DESC;

-- 5. Surfaces all sales order line items where allocated quantity falls short of ordered quantity, revealing active stockout or fulfilment gaps that require procurement or reallocation action.
SELECT so.so_number, c.company_name, p.product_name, si.ordered_quantity, si.allocated_quantity,
       (si.ordered_quantity - si.allocated_quantity) AS shortage
FROM so_item si
JOIN sales_order so ON si.so_id = so.so_id
JOIN customer c ON so.customer_id = c.customer_id
JOIN product p ON si.product_id = p.product_id
WHERE si.allocated_quantity < si.ordered_quantity
  AND si.item_status != 'cancelled'
ORDER BY shortage DESC;

-- 6. Lists all unpaid sales orders sorted by order age, providing the collections team with a prioritised receivables worklist to reduce days sales outstanding (DSO).
SELECT so.so_number, c.company_name, so.order_date, so.total_amount
FROM sales_order so
JOIN customer c ON so.customer_id = c.customer_id
WHERE so.payment_status != 'paid'
ORDER BY so.order_date ASC;

-- 7. Highlights products whose current warehouse stock has fallen to or below the defined reorder point, triggering replenishment review before stockout occurs.
SELECT p.product_name, p.reorder_point, COALESCE(SUM(i.quantity_available), 0) AS current_stock
FROM product p
LEFT JOIN inventory i ON p.product_id = i.product_id
GROUP BY p.product_id, p.product_name, p.reorder_point
HAVING COALESCE(SUM(i.quantity_available), 0) <= p.reorder_point;

-- 8. Detects approved-batch inventory with no movement in the last 90 days, identifying dead stock that ties up warehouse space and working capital.
SELECT p.product_name, w.warehouse_name, z.zone_code, i.quantity_on_hand, i.last_movement_at
FROM inventory i
JOIN product p ON i.product_id = p.product_id
JOIN warehouse_zone z ON i.zone_id = z.zone_id
JOIN warehouse w ON z.warehouse_id = w.warehouse_id
WHERE i.last_movement_at < CURRENT_DATE - INTERVAL '90 days'
  AND i.quantity_on_hand > 0
ORDER BY i.last_movement_at ASC;

-- 9. Computes the variance between the unit price paid on each purchase order line and the product standard cost, surfacing procurement overspend for supplier renegotiation.
SELECT po.po_number, s.company_name, p.product_name,
       pi.unit_price AS paid_price, p.standard_cost,
       (pi.unit_price - p.standard_cost) AS cost_variance,
       ROUND(((pi.unit_price - p.standard_cost) / p.standard_cost) * 100, 2) AS variance_pct
FROM po_item pi
JOIN purchase_order po ON pi.po_id = po.po_id
JOIN product p ON pi.product_id = p.product_id
JOIN supplier s ON po.supplier_id = s.supplier_id
WHERE p.standard_cost > 0 
  AND pi.unit_price > p.standard_cost
  AND po.po_status != 'cancelled'
ORDER BY cost_variance DESC;

-- 10. Lists all confirmed and allocated sales order lines still awaiting picking, sorted by business priority level and order age to guide warehouse dispatch sequencing.
SELECT so.so_number, so.priority_level, p.product_name, 
       si.ordered_quantity, si.allocated_quantity, si.picked_quantity
FROM so_item si
JOIN sales_order so ON si.so_id = so.so_id
JOIN product p ON si.product_id = p.product_id
WHERE si.item_status IN ('pending', 'allocated')
  AND so.so_status IN ('confirmed', 'allocated')
ORDER BY 
  CASE WHEN so.priority_level = 'urgent' THEN 1
       WHEN so.priority_level = 'express' THEN 2
       ELSE 3 END ASC,
  so.order_date ASC;

-- 11. Warns of approved-batch inventory expiring within 30 days with non-zero available quantity, enabling FEFO dispatch teams to prioritise these batches in outbound order fulfilment.
SELECT b.batch_code, p.product_name, b.expiry_date, i.quantity_available
FROM batch b
JOIN product p ON b.product_id = p.product_id
JOIN inventory i ON b.batch_id = i.batch_id
WHERE b.expiry_date <= CURRENT_DATE + INTERVAL '30 days'
  AND i.quantity_available > 0
ORDER BY b.expiry_date ASC;

-- 12. Traces all active in-transit shipments to their originating sales orders and customers, enabling logistics teams to respond to customer delivery enquiries with live carrier data.
SELECT sh.shipment_number, sh.carrier_name, sh.shipment_status, so.so_number, c.company_name
FROM shipment sh
JOIN shipment_item shi ON sh.shipment_id = shi.shipment_id
JOIN so_item si ON shi.so_item_id = si.so_item_id
JOIN sales_order so ON si.so_id = so.so_id
JOIN customer c ON so.customer_id = c.customer_id
WHERE sh.shipment_status = 'in_transit';

-- 13. Ranks the top 5 products by total units sold across all non-cancelled sales orders, informing demand planning, promotional focus, and replenishment prioritisation.
SELECT p.product_name, SUM(si.ordered_quantity) AS total_units_sold
FROM so_item si
JOIN product p ON si.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_units_sold DESC
LIMIT 5;

-- 14. Computes the aggregate total amount committed on non-cancelled, non-fully-received purchase orders per supplier, measuring active procurement exposure against supplier credit limits.
SELECT s.company_name, s.supplier_tier, s.credit_limit,
       COUNT(po.po_id) AS open_po_count,
       SUM(po.total_amount) AS total_committed_spend
FROM purchase_order po
JOIN supplier s ON po.supplier_id = s.supplier_id
WHERE po.po_status NOT IN ('cancelled', 'fully_received')
GROUP BY s.supplier_id, s.company_name, s.supplier_tier, s.credit_limit
ORDER BY total_committed_spend DESC;

-- 15. Identifies products whose total available stock exists across multiple warehouses, quantifying cross-location consolidation opportunities to reduce split-shipment overhead.
SELECT p.product_name,
       COUNT(DISTINCT z.warehouse_id) AS warehouses_holding,
       SUM(i.quantity_available) AS total_available,
       MIN(i.quantity_available) AS min_at_any_location,
       MAX(i.quantity_available) AS max_at_any_location
FROM inventory i
JOIN product p ON i.product_id = p.product_id
JOIN warehouse_zone z ON i.zone_id = z.zone_id
WHERE i.quantity_available > 0
GROUP BY p.product_id, p.product_name
HAVING COUNT(DISTINCT z.warehouse_id) > 1
ORDER BY warehouses_holding DESC, total_available DESC;

-- 16. Identifies all purchase orders that arrived after their expected delivery date, computing the delay in days per supplier to support vendor scorecard and penalty clause evaluation.
SELECT po.po_number, s.company_name, po.expected_delivery_date, po.actual_delivery_date,
       (po.actual_delivery_date - po.expected_delivery_date) AS days_delayed
FROM purchase_order po
JOIN supplier s ON po.supplier_id = s.supplier_id
WHERE po.actual_delivery_date > po.expected_delivery_date
  AND po.po_status = 'fully_received'
ORDER BY days_delayed DESC;

-- 17. Measures the return rate per product by total returned quantity and return instance count, flagging quality or fulfilment issues requiring supplier or process corrective action.
SELECT p.sku_code, p.product_name, COUNT(ri.return_item_id) AS total_return_instances, SUM(ri.returned_quantity) AS total_quantity_returned
FROM return_item ri
JOIN so_item si ON ri.so_item_id = si.so_item_id
JOIN product p ON si.product_id = p.product_id
GROUP BY p.product_id, p.sku_code, p.product_name
ORDER BY total_quantity_returned DESC
LIMIT 5;

-- 18. Lists all return requests currently in 'requested' status awaiting approval, providing the returns management team a pending action queue with customer context.
SELECT r.return_id, c.company_name, r.return_reason, r.requested_at
FROM return_request r
JOIN customer c ON r.customer_id = c.customer_id
WHERE r.return_status = 'requested';

-- 19. Analyses active KYC-verified customers' credit utilisation and contracted payment terms segmented by customer type, to refine credit policy and exposure management.
SELECT c.customer_type,
       COUNT(DISTINCT c.customer_id) AS customer_count,
       ROUND(AVG(c.payment_terms_days), 1) AS avg_contracted_terms_days,
       SUM(c.outstanding_balance) AS total_outstanding,
       SUM(c.credit_limit) AS total_credit_extended,
       ROUND(SUM(c.outstanding_balance) / NULLIF(SUM(c.credit_limit), 0) * 100, 2) AS utilisation_pct
FROM customer c
WHERE c.kyc_verified = TRUE
GROUP BY c.customer_type
ORDER BY utilisation_pct DESC;

-- 20. Identifies all purchase orders in approved or partially-received state that have not yet been fully fulfilled, sorted by expected delivery date to flag overdue inbounds.
SELECT po_number, order_date, expected_delivery_date, po_status 
FROM purchase_order 
WHERE po_status IN ('approved', 'partially_received')
ORDER BY expected_delivery_date ASC;

-- 21. Retrieves the precise physical location of every inventory lot for a given product across all warehouses, zones, and batches, supporting stock audit and pick-path planning.
SELECT p.product_name, w.warehouse_name, z.zone_code, b.batch_code, i.quantity_available
FROM inventory i
JOIN product p ON i.product_id = p.product_id
JOIN batch b ON i.batch_id = b.batch_id
JOIN warehouse_zone z ON i.zone_id = z.zone_id
JOIN warehouse w ON z.warehouse_id = w.warehouse_id
WHERE p.product_name = 'Colgate Strong Teeth 200g';

-- 22. Analyses batches currently under quarantine hold with their on-hand quantity, providing QA teams visibility into blocked stock pending inspection or disposal decisions.
SELECT p.product_name, b.batch_code, b.quality_status, i.quantity_on_hand
FROM inventory i
JOIN batch b ON i.batch_id = b.batch_id
JOIN product p ON b.product_id = p.product_id
WHERE b.quality_status = 'quarantine';

-- 23. Aggregates active suppliers by tier, reporting average performance rating to support strategic sourcing decisions and annual vendor rationalisation reviews.
SELECT supplier_tier, COUNT(*) as total_suppliers, ROUND(AVG(supplier_rating), 2) as avg_rating
FROM supplier
WHERE is_active = TRUE
GROUP BY supplier_tier
ORDER BY avg_rating DESC;

-- 24. Traverses the full product category hierarchy using a recursive CTE, computing depth level for each node to support category management, reporting rollups, and UI tree rendering.
WITH RECURSIVE category_tree AS (
    SELECT category_id, category_name, parent_category_id, 1 AS level
    FROM product_category
    WHERE parent_category_id IS NULL
    
    UNION ALL
    
    SELECT pc.category_id, pc.category_name, pc.parent_category_id, ct.level + 1
    FROM product_category pc
    JOIN category_tree ct ON pc.parent_category_id = ct.category_id
)
SELECT * FROM category_tree ORDER BY level, category_name;

-- 25. Lists all perishable products alongside their shelf life in days, supporting cold chain planning, storage zone assignment, and FEFO dispatch policy configuration.
SELECT sku_code, product_name, shelf_life_days 
FROM product 
WHERE is_perishable = TRUE;