CREATE DATABASE indiakart;
USE indiakart;
SELECT DATABASE();
USE indiakart;

SHOW TABLES;
SELECT COUNT(*) AS total_rows
FROM orders_clean;
DESCRIBE orders_clean;
SELECT
    ROUND(SUM(final_amount), 2) AS gross_merchandise_value
FROM orders_clean;

SELECT
    COUNT(*) AS delivered_orders,
    ROUND(SUM(final_amount), 2) AS net_revenue
FROM orders_clean
WHERE status = 'Delivered';

SELECT
    COUNT(*) AS delivered_orders,
    ROUND(SUM(final_amount), 2) AS net_revenue,
    ROUND(SUM(final_amount) / COUNT(*), 2) AS average_order_value
FROM orders_clean
WHERE status = 'Delivered';

SELECT
    COUNT(*) AS total_orders,
    SUM(CASE
            WHEN status = 'Cancelled' THEN 1
            ELSE 0
        END) AS cancelled_orders,
    ROUND(
        SUM(CASE
                WHEN status = 'Cancelled' THEN 1
                ELSE 0
            END) * 100.0 / COUNT(*),
        2
    ) AS cancellation_rate
FROM orders_clean;

Show tables;
SELECT COUNT(*)
FROM returns_clean;

SELECT
    (SELECT COUNT(*) FROM returns_clean) AS total_return_records,
    SUM(
        CASE
            WHEN status = 'Delivered' THEN 1
            ELSE 0
        END
    ) AS delivered_orders,
    ROUND(
        (SELECT COUNT(*) FROM returns_clean) * 100.0 /
        SUM(
            CASE
                WHEN status = 'Delivered' THEN 1
                ELSE 0
            END
        ),
        2
    ) AS return_rate
FROM orders_clean;

SELECT
    COUNT(*) AS valid_returns,
    (
        SELECT COUNT(*)
        FROM orders_clean
        WHERE status = 'Delivered'
    ) AS delivered_orders,
    ROUND(
        COUNT(*) * 100.0 /
        (
            SELECT COUNT(*)
            FROM orders_clean
            WHERE status = 'Delivered'
        ),
        2
    ) AS valid_return_rate
FROM returns_clean r
JOIN orders_clean o
ON r.order_id = o.order_id
WHERE o.status = 'Delivered';

SELECT COUNT(*)
FROM customers_clean;

SELECT
    segment,
    COUNT(*) AS customer_count,
    ROUND(AVG(total_spent), 2) AS average_clv,
    ROUND(SUM(total_spent), 2) AS total_revenue
FROM customers_clean
GROUP BY segment
ORDER BY average_clv DESC;

WITH segment_clv AS (
    SELECT
        segment,
        AVG(total_spent) AS average_clv
    FROM customers_clean
    GROUP BY segment
)
SELECT
    ROUND(
        MAX(CASE WHEN segment = 'Premium' THEN average_clv END) /
        MAX(CASE WHEN segment = 'Regular' THEN average_clv END),
        2
    ) AS premium_to_regular_ratio
FROM segment_clv;

SELECT
    order_date,
    STR_TO_DATE(order_date, '%d-%m-%Y') AS converted_order_date
FROM orders_clean
LIMIT 10;

DESCRIBE orders_clean;

SELECT
    order_date,
    STR_TO_DATE(order_date, '%Y-%m-%d') AS converted_order_date
FROM orders_clean
LIMIT 10;

SELECT
    DATE_FORMAT(
        STR_TO_DATE(order_date, '%Y-%m-%d'),
        '%Y-%m'
    ) AS order_month
FROM orders_clean
LIMIT 10;

SELECT
    DATE_FORMAT(
        STR_TO_DATE(order_date, '%Y-%m-%d'),
        '%Y-%m'
    ) AS order_month,
    ROUND(SUM(final_amount), 2) AS monthly_gmv,
    COUNT(DISTINCT order_id) AS total_orders
FROM orders_clean
GROUP BY
    DATE_FORMAT(
        STR_TO_DATE(order_date, '%Y-%m-%d'),
        '%Y-%m'
    )
ORDER BY order_month;

WITH monthly_sales AS
(
    SELECT
        DATE_FORMAT(
            STR_TO_DATE(order_date,'%Y-%m-%d'),
            '%Y-%m'
        ) AS order_month,

        ROUND(SUM(final_amount),2) AS monthly_gmv

    FROM orders_clean

    GROUP BY
        DATE_FORMAT(
            STR_TO_DATE(order_date,'%Y-%m-%d'),
            '%Y-%m'
        )
)

SELECT
    order_month,
    monthly_gmv,

    LAG(monthly_gmv)
    OVER(ORDER BY order_month)
    AS previous_month_gmv

FROM monthly_sales;

WITH monthly_sales AS
(
    SELECT
        DATE_FORMAT(
            STR_TO_DATE(order_date,'%Y-%m-%d'),
            '%Y-%m'
        ) AS order_month,

        ROUND(SUM(final_amount),2) AS monthly_gmv

    FROM orders_clean

    GROUP BY
        DATE_FORMAT(
            STR_TO_DATE(order_date,'%Y-%m-%d'),
            '%Y-%m'
        )
)

SELECT
    order_month,

    monthly_gmv,

    LAG(monthly_gmv)
    OVER(ORDER BY order_month)
    AS previous_month_gmv,

    ROUND(
        (
            monthly_gmv -
            LAG(monthly_gmv)
            OVER(ORDER BY order_month)
        )
        /
        LAG(monthly_gmv)
        OVER(ORDER BY order_month)
        *100,
        2
    ) AS mom_growth_pct

FROM monthly_sales;

SHOW TABLES;
SELECT 
    COUNT(*) AS total_rows
FROM
    order_items_clean;
    
    DESCRIBE order_items_clean;
    SELECT
    COUNT(*) AS rows_after_join,
    SUM(CASE
            WHEN o.status IS NULL THEN 1
            ELSE 0
        END) AS missing_status
FROM order_items_clean oi
LEFT JOIN orders_clean o
ON oi.order_id = o.order_id;

SELECT
    COUNT(*) AS delivered_items
FROM order_items_clean oi
JOIN orders_clean o
ON oi.order_id = o.order_id
WHERE o.status = 'Delivered';

WITH category_revenue AS (
    SELECT
        oi.category,
        SUM(oi.total_price) AS category_revenue
    FROM order_items_clean oi
    JOIN orders_clean o
        ON oi.order_id = o.order_id
    WHERE o.status = 'Delivered'
    GROUP BY oi.category
),

total_revenue AS (
    SELECT
        SUM(category_revenue) AS total_delivered_revenue
    FROM category_revenue
)

SELECT
    cr.category,
    ROUND(cr.category_revenue, 2) AS category_revenue,
    ROUND(
        cr.category_revenue * 100.0
        / tr.total_delivered_revenue,
        2
    ) AS revenue_share_pct
FROM category_revenue cr
CROSS JOIN total_revenue tr
ORDER BY revenue_share_pct DESC;

SHOW TABLES;

SELECT COUNT(*) AS total_payments
FROM payments_clean;

DESCRIBE payments_clean;

SELECT
    COUNT(*) AS total_payments,
    SUM(CASE
            WHEN status = 'Failed' THEN 1
            ELSE 0
        END) AS failed_payments
FROM payments_clean;

SELECT
    COUNT(*) AS total_payments,

    SUM(CASE
            WHEN status = 'Failed' THEN 1
            ELSE 0
        END) AS failed_payments,

    ROUND(
        SUM(CASE
                WHEN status = 'Failed' THEN 1
                ELSE 0
            END) * 100.0
        / COUNT(*),
        2
    ) AS payment_failure_rate
FROM payments_clean;

SELECT COUNT(*) AS total_skus
FROM inventory_clean;

DESCRIBE inventory_clean;

SELECT
    COUNT(*) AS total_skus,
    SUM(
        CASE
            WHEN status = 'In Stock' THEN 1
            ELSE 0
        END
    ) AS in_stock_skus
FROM inventory_clean;

SELECT
    COUNT(*) AS total_skus,

    SUM(
        CASE
            WHEN status = 'In Stock' THEN 1
            ELSE 0
        END
    ) AS in_stock_skus,

    ROUND(
        SUM(
            CASE
                WHEN status = 'In Stock' THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS inventory_fill_rate
FROM inventory_clean;

USE indiakart;

SHOW TABLES;