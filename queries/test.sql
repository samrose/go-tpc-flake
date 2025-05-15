-- Simple SELECT query
SELECT 1 as test;

-- Count query
SELECT COUNT(*) FROM pg_tables;

-- Join query
SELECT 
    t.tablename,
    c.column_name,
    c.data_type
FROM pg_tables t
JOIN information_schema.columns c ON t.tablename = c.table_name
LIMIT 10;

-- Aggregation query
SELECT 
    schemaname,
    COUNT(*) as table_count
FROM pg_tables
GROUP BY schemaname
ORDER BY table_count DESC;

-- Create test tables
CREATE TABLE IF NOT EXISTS test_orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER,
    order_date TIMESTAMP,
    total_amount DECIMAL(10,2)
);

CREATE TABLE IF NOT EXISTS test_customers (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    created_at TIMESTAMP
);

-- Insert test data
INSERT INTO test_customers (name, email, created_at)
SELECT 
    'Customer ' || i,
    'customer' || i || '@example.com',
    NOW() - (i * interval '1 day')
FROM generate_series(1, 1000) i;

INSERT INTO test_orders (customer_id, order_date, total_amount)
SELECT 
    (random() * 1000)::integer + 1,
    NOW() - (i * interval '1 hour'),
    (random() * 1000)::decimal(10,2)
FROM generate_series(1, 5000) i;

-- Complex queries to test performance

-- 1. Aggregation with grouping
SELECT 
    c.name,
    COUNT(o.order_id) as order_count,
    AVG(o.total_amount) as avg_order_value,
    SUM(o.total_amount) as total_spent
FROM test_customers c
LEFT JOIN test_orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
HAVING COUNT(o.order_id) > 0
ORDER BY total_spent DESC
LIMIT 10;

-- 2. Time-based analysis
SELECT 
    date_trunc('day', order_date) as order_day,
    COUNT(*) as orders_per_day,
    AVG(total_amount) as avg_daily_order_value
FROM test_orders
GROUP BY order_day
ORDER BY order_day DESC
LIMIT 10;

-- 3. Customer segmentation
SELECT 
    CASE 
        WHEN COUNT(o.order_id) > 10 THEN 'High Value'
        WHEN COUNT(o.order_id) > 5 THEN 'Medium Value'
        ELSE 'Low Value'
    END as customer_segment,
    COUNT(*) as customer_count,
    AVG(COUNT(o.order_id)) as avg_orders_per_customer
FROM test_customers c
LEFT JOIN test_orders o ON c.customer_id = o.customer_id
GROUP BY 
    CASE 
        WHEN COUNT(o.order_id) > 10 THEN 'High Value'
        WHEN COUNT(o.order_id) > 5 THEN 'Medium Value'
        ELSE 'Low Value'
    END;

-- Clean up
DROP TABLE IF EXISTS test_orders;
DROP TABLE IF EXISTS test_customers; 