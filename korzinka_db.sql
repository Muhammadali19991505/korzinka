-- TOPSHIRIQ1.1

-- Har bir toifa bo‘yicha sotilgan jami mahsulotlar soni (total_quantity)

SELECT 
    p.category,
    SUM(oi.quantity) AS total_quantity
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'Yetkazildi'
GROUP BY p.category
ORDER BY total_quantity DESC;

-- Har bir toifa bo‘yicha sof daromad (net_revenue)

SELECT 
    p.category,
    ROUND(SUM(oi.quantity * p.selling_price * (1.0 - oi.discount_percent / 100.0)), 2) AS net_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'Yetkazildi'
GROUP BY p.category
ORDER BY net_revenue DESC;


-- Har bir toifa bo‘yicha yalpi foyda (gross_profit)

SELECT 
    p.category,
    ROUND(
        SUM(oi.quantity * p.selling_price * (1.0 - oi.discount_percent / 100.0)) 
        - SUM(oi.quantity * p.cost_price),                                     
        2
    ) AS gross_profit
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'Yetkazildi'
GROUP BY p.category
ORDER BY gross_profit DESC;

-- Foyda marjasi (profit_margin_percent) bo‘yicha saralash

WITH savdo_jadvali AS (
    SELECT 
        p.category,
        oi.quantity,
        (oi.quantity * p.selling_price * (1.0 - oi.discount_percent / 100.0)) AS qator_tushumi,
        (oi.quantity * p.cost_price) AS qator_tannarxi
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_status = 'Yetkazildi'
)
SELECT 
    category,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(qator_tushumi), 2) AS net_revenue,
    ROUND(SUM(qator_tushumi) - SUM(qator_tannarxi), 2) AS gross_profit,
    ROUND(
        ((SUM(qator_tushumi) - SUM(qator_tannarxi)) / SUM(qator_tushumi)) * 100.0, 
        2
    ) AS profit_margin_percent
FROM savdo_jadvali
GROUP BY category
ORDER BY profit_margin_percent DESC;

-- TOPSHIRIQ1.2

-- Har bir oy bo‘yicha buyurtmalar soni (orders_count)

SELECT 
    EXTRACT(MONTH FROM order_date) AS oy,
    COUNT(DISTINCT order_id) AS orders_count
FROM orders
WHERE order_status = 'Yetkazildi'
  AND EXTRACT(YEAR FROM order_date) = 2026
GROUP BY EXTRACT(MONTH FROM order_date)
ORDER BY oy;

-- Har bir oy bo‘yicha xarid qilgan unikal mijozlar soni (unique_customers)

SELECT 
    EXTRACT(MONTH FROM order_date) AS oy,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM orders
WHERE order_status = 'Yetkazildi'
  AND EXTRACT(YEAR FROM order_date) = 2026
GROUP BY EXTRACT(MONTH FROM order_date)
ORDER BY oy;

-- Har bir oy bo‘yicha sof daromad (net_revenue)

SELECT 
    EXTRACT(MONTH FROM o.order_date) AS oy,
    ROUND(SUM(oi.quantity * p.selling_price * (1.0 - oi.discount_percent / 100.0)), 2) AS net_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.order_status = 'Yetkazildi'
  AND EXTRACT(YEAR FROM o.order_date) = 2026
GROUP BY EXTRACT(MONTH FROM o.order_date)
ORDER BY oy;

-- To‘liq birlashtirilgan SQL so‘rovi (CTE orqali)

WITH oylik_savdo AS (
    SELECT 
        o.order_id,
        o.customer_id,
        EXTRACT(MONTH FROM o.order_date) AS oy,
        (oi.quantity * p.selling_price * (1.0 - oi.discount_percent / 100.0)) AS qator_tushumi
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE o.order_status = 'Yetkazildi'
      AND EXTRACT(YEAR FROM o.order_date) = 2026
)
SELECT 
    oy,
    ROUND(SUM(qator_tushumi), 2) AS net_revenue,
    COUNT(DISTINCT order_id) AS orders_count,
    ROUND(SUM(qator_tushumi) / COUNT(DISTINCT order_id), 2) AS aov,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM oylik_savdo
GROUP BY oy
ORDER BY oy;

-- Topshiriq 1.3: O'zbekiston shaharlari kesimida tahlil: 
-- har bir shahar bo'yicha eng yuqori o'rtacha chek (AOV) 
-- va eng ko'p ishlatilgan to'lov usulini (payment_method) aniqlang.

-- 1. Shaharlar bo'yicha o'rtacha chek (AOV)
WITH har_bir_chek AS (
    SELECT 
        o.order_id,
        c.city,
        SUM(oi.quantity * p.selling_price * (1.0 - oi.discount_percent / 100.0)) AS chek_summasi
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE o.order_status = 'Yetkazildi'
    GROUP BY o.order_id, c.city
)
SELECT 
    city,
    COUNT(order_id) AS jami_buyurtmalar,
    ROUND(SUM(chek_summasi), 2) AS jami_tushum,
    ROUND(AVG(chek_summasi), 2) AS aov 
FROM har_bir_chek
GROUP BY city
ORDER BY aov DESC;


-- 2. Shaharlar kesimida eng ommabop to'lov usuli
WITH tolovlar_soni AS (
    SELECT 
        c.city,
        o.payment_method,
        COUNT(o.order_id) AS ishlatilish_soni,
        ROW_NUMBER() OVER (
            PARTITION BY c.city 
            ORDER BY COUNT(o.order_id) DESC
        ) AS orin
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'Yetkazildi'
    GROUP BY c.city, o.payment_method
)
SELECT 
    city,
    payment_method AS eng_kop_tolov_usuli,
    ishlatilish_soni
FROM tolovlar_soni
WHERE orin = 1;


-- 2-BO'LIM: MIJOZLAR HARAKATI VA SAQLAB QOLISH (RETENTION)

-- Birinchi,oxirgi xarid sanasi va jami xaridlar soni (Frequency)

SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    MIN(o.order_date) AS birinchi_xarid_sanasi,
	MAX(o.order_date) AS oxirgi_xarid_sanasi,
	COUNT(o.order_id) AS jami_xaridlar_soni
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'Yetkazildi'
GROUP BY 
    c.customer_id, 
    c.first_name, 
    c.last_name
ORDER BY 
    c.customer_id;


-- Jami sarflangan summa (Monetar

SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    ROUND(SUM(oi.quantity * p.selling_price * (1 - oi.discount_percent / 100.0)), 2) AS jami_sarflangan_summa
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.order_status = 'Yetkazildi'
GROUP BY 
    c.customer_id, 
    c.first_name, 
    c.last_name
ORDER BY jami_sarflangan_summa DESC;

-- Oxirgi xariddan hozirgi kungacha o'tgan kunlar soni (Recency)

SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    MAX(o.order_date) AS oxirgi_xarid_sanasi,
    CURRENT_DATE - MAX(o.order_date) AS otgan_kunlar_soni
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'Yetkazildi'
GROUP BY 
    c.customer_id, 
    c.first_name, 
    c.last_name
ORDER BY 
    otgan_kunlar_soni ASC;
