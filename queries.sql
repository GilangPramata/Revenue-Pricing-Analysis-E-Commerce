-- ============================================================
-- Revenue & Pricing Analysis — PostgreSQL Queries
-- Portfolio 2 · UCI Online Retail
-- Source table: online_retail (load from data/online_retail_clean.csv)
-- ============================================================

-- ------------------------------------------------------------
-- 0. SCHEMA & LOAD
-- ------------------------------------------------------------
DROP TABLE IF EXISTS online_retail;
CREATE TABLE online_retail (
    invoice_no    VARCHAR(12),
    stock_code    VARCHAR(20),
    description   VARCHAR(200),
    quantity      INTEGER,
    invoice_date  TIMESTAMP,
    unit_price    NUMERIC(12,2),
    customer_id   NUMERIC,
    country       VARCHAR(50),
    revenue       NUMERIC(14,2),
    invoice_month VARCHAR(7),
    ref_price     NUMERIC(12,2),
    discount_pct  NUMERIC(6,4),
    is_promo      BOOLEAN,
    est_profit    NUMERIC(14,2),
    est_margin    NUMERIC(8,4)
);
-- \copy online_retail FROM 'online_retail_clean.csv' WITH (FORMAT csv, HEADER true);

-- Note: revenue = quantity * unit_price.
-- ref_price = modal (list) unit price per SKU; discount_pct = 1 - unit_price/ref_price.
-- est_profit assumes cost = 50% of list price (transparent estimate, not source data).


-- ------------------------------------------------------------
-- 1. HEADLINE KPIs — REVENUE, PROFIT, AOV, ASP, MARGIN
-- ------------------------------------------------------------
SELECT
    ROUND(SUM(revenue), 2)                                   AS total_revenue,
    ROUND(SUM(est_profit), 2)                                AS est_profit,
    ROUND(SUM(est_profit) / NULLIF(SUM(revenue),0) * 100, 2) AS est_margin_pct,
    COUNT(DISTINCT invoice_no)                               AS invoices,
    ROUND(SUM(revenue) / NULLIF(COUNT(DISTINCT invoice_no),0), 2) AS avg_order_value,
    ROUND(AVG(unit_price), 2)                                AS avg_selling_price,
    ROUND(AVG(CASE WHEN is_promo THEN 1 ELSE 0 END) * 100, 2) AS promo_line_share_pct
FROM online_retail;


-- ------------------------------------------------------------
-- 2. MONTHLY TREND — REVENUE, PROFIT, ASP, PROMO SHARE
-- ------------------------------------------------------------
SELECT
    invoice_month,
    ROUND(SUM(revenue), 2)                                    AS revenue,
    ROUND(SUM(est_profit), 2)                                 AS est_profit,
    ROUND(SUM(est_profit) / NULLIF(SUM(revenue),0) * 100, 1)  AS margin_pct,
    ROUND(AVG(unit_price), 2)                                 AS avg_selling_price,
    ROUND(AVG(CASE WHEN is_promo THEN 1 ELSE 0 END) * 100, 1) AS promo_share_pct
FROM online_retail
GROUP BY invoice_month
ORDER BY invoice_month;


-- ------------------------------------------------------------
-- 3. AVERAGE SELLING PRICE & DISCOUNT BY SKU
-- ------------------------------------------------------------
SELECT
    stock_code,
    MAX(description)                       AS description,
    ROUND(AVG(unit_price), 2)              AS avg_selling_price,
    ROUND(MAX(ref_price), 2)               AS list_price,
    ROUND(AVG(discount_pct) * 100, 1)      AS avg_discount_pct
FROM online_retail
GROUP BY stock_code
HAVING SUM(quantity) > 500
ORDER BY avg_discount_pct DESC
LIMIT 25;


-- ------------------------------------------------------------
-- 4. TOP SKUs BY REVENUE (+ estimated margin)
-- ------------------------------------------------------------
SELECT
    stock_code,
    MAX(description)                                          AS description,
    ROUND(SUM(revenue), 2)                                    AS revenue,
    SUM(quantity)                                             AS units,
    ROUND(AVG(unit_price), 2)                                 AS avg_selling_price,
    ROUND(SUM(est_profit) / NULLIF(SUM(revenue),0) * 100, 1)  AS est_margin_pct
FROM online_retail
GROUP BY stock_code
ORDER BY revenue DESC
LIMIT 15;


-- ------------------------------------------------------------
-- 5. PROMOTION IMPACT — VOLUME vs MARGIN PER SKU
--    Compares promoted vs baseline months to surface
--    "volume up, margin down" products.
-- ------------------------------------------------------------
WITH sku_month AS (
    SELECT
        stock_code,
        invoice_month,
        SUM(quantity)                  AS units,
        AVG(est_margin)                AS margin,
        AVG(CASE WHEN is_promo THEN 1 ELSE 0 END) AS promo_share
    FROM online_retail
    GROUP BY stock_code, invoice_month
),
classified AS (
    SELECT
        stock_code,
        CASE WHEN promo_share >= 0.30 THEN 'promoted'
             WHEN promo_share <  0.10 THEN 'baseline' END AS phase,
        units, margin
    FROM sku_month
    WHERE promo_share >= 0.30 OR promo_share < 0.10
)
SELECT
    c.stock_code,
    MAX(r.description)                                                       AS description,
    ROUND(AVG(CASE WHEN phase='promoted' THEN units END))                    AS avg_units_promo,
    ROUND(AVG(CASE WHEN phase='baseline' THEN units END))                    AS avg_units_base,
    ROUND(AVG(CASE WHEN phase='promoted' THEN margin END)*100, 1)            AS margin_promo_pct,
    ROUND(AVG(CASE WHEN phase='baseline' THEN margin END)*100, 1)            AS margin_base_pct
FROM classified c
JOIN online_retail r ON r.stock_code = c.stock_code
GROUP BY c.stock_code
HAVING COUNT(DISTINCT phase) = 2
   AND AVG(CASE WHEN phase='promoted' THEN units END) > AVG(CASE WHEN phase='baseline' THEN units END)
   AND AVG(CASE WHEN phase='promoted' THEN margin END) < AVG(CASE WHEN phase='baseline' THEN margin END)
ORDER BY avg_units_promo DESC
LIMIT 15;


-- ------------------------------------------------------------
-- 6. REVENUE BY COUNTRY
-- ------------------------------------------------------------
SELECT
    country,
    ROUND(SUM(revenue), 2)      AS revenue,
    COUNT(DISTINCT invoice_no)  AS invoices
FROM online_retail
GROUP BY country
ORDER BY revenue DESC
LIMIT 10;
