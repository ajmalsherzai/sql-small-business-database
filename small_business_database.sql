-- SQL Small Business Sales & Inventory Database
-- Created by Ajmal Sherzai

DROP DATABASE IF EXISTS small_business_db;
CREATE DATABASE small_business_db;
USE small_business_db;

-- Customers Table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    phone VARCHAR(20),
    city VARCHAR(50),
    state VARCHAR(50)
);

-- Products Table
CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    product_name VARCHAR(100),
    category VARCHAR(50),
    unit_price DECIMAL(10,2),
    inventory_quantity INT
);

-- Orders Table
CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT,
    order_date DATE,
    order_status VARCHAR(50),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Order Details Table
CREATE TABLE order_details (
    order_detail_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    product_id INT,
    quantity INT,
    unit_price DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Payments Table
CREATE TABLE payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT,
    payment_date DATE,
    payment_amount DECIMAL(10,2),
    payment_method VARCHAR(50),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- Insert Customers
INSERT INTO customers (first_name, last_name, email, phone, city, state)
VALUES
('John', 'Smith', 'johnsmith@email.com', '916-555-1001', 'Sacramento', 'CA'),
('Maria', 'Garcia', 'mariagarcia@email.com', '916-555-1002', 'Elk Grove', 'CA'),
('David', 'Lee', 'davidlee@email.com', '916-555-1003', 'Roseville', 'CA'),
('Ashley', 'Brown', 'ashleybrown@email.com', '916-555-1004', 'Folsom', 'CA'),
('Michael', 'Johnson', 'mjohnson@email.com', '916-555-1005', 'Sacramento', 'CA');

-- Insert Products
INSERT INTO products (product_name, category, unit_price, inventory_quantity)
VALUES
('Laptop Stand', 'Office Supplies', 35.99, 50),
('Wireless Mouse', 'Electronics', 24.99, 80),
('Keyboard', 'Electronics', 49.99, 60),
('Desk Chair', 'Furniture', 149.99, 20),
('Notebook Pack', 'Office Supplies', 12.99, 100),
('USB-C Cable', 'Electronics', 14.99, 75);

-- Insert Orders
INSERT INTO orders (customer_id, order_date, order_status)
VALUES
(1, '2026-01-10', 'Completed'),
(2, '2026-01-15', 'Completed'),
(3, '2026-02-05', 'Completed'),
(4, '2026-02-18', 'Pending'),
(5, '2026-03-01', 'Completed');

-- Insert Order Details
INSERT INTO order_details (order_id, product_id, quantity, unit_price)
VALUES
(1, 1, 2, 35.99),
(1, 2, 1, 24.99),
(2, 4, 1, 149.99),
(2, 5, 3, 12.99),
(3, 3, 2, 49.99),
(3, 6, 4, 14.99),
(4, 2, 2, 24.99),
(5, 1, 1, 35.99),
(5, 4, 1, 149.99);

-- Insert Payments
INSERT INTO payments (order_id, payment_date, payment_amount, payment_method)
VALUES
(1, '2026-01-10', 96.97, 'Credit Card'),
(2, '2026-01-15', 188.96, 'Debit Card'),
(3, '2026-02-05', 159.94, 'Credit Card'),
(5, '2026-03-01', 185.98, 'Cash');

-- Query 1: View all orders with customer names
SELECT 
    o.order_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    o.order_date,
    o.order_status
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id;

-- Query 2: Total revenue by product
SELECT 
    p.product_name,
    p.category,
    SUM(od.quantity * od.unit_price) AS total_revenue
FROM order_details od
JOIN products p
    ON od.product_id = p.product_id
GROUP BY p.product_name, p.category
ORDER BY total_revenue DESC;

-- Query 3: Total spending by customer
SELECT 
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    SUM(od.quantity * od.unit_price) AS total_spent
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_details od
    ON o.order_id = od.order_id
GROUP BY customer_name
ORDER BY total_spent DESC;

-- Query 4: Monthly sales revenue
SELECT 
    DATE_FORMAT(o.order_date, '%Y-%m') AS sales_month,
    SUM(od.quantity * od.unit_price) AS monthly_revenue
FROM orders o
JOIN order_details od
    ON o.order_id = od.order_id
GROUP BY sales_month
ORDER BY sales_month;

-- Query 5: Low inventory products
SELECT 
    product_name,
    category,
    inventory_quantity
FROM products
WHERE inventory_quantity < 30
ORDER BY inventory_quantity ASC;

-- Query 6: Orders with payment status
SELECT 
    o.order_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    SUM(od.quantity * od.unit_price) AS order_total,
    COALESCE(SUM(p.payment_amount), 0) AS amount_paid,
    CASE
        WHEN COALESCE(SUM(p.payment_amount), 0) >= SUM(od.quantity * od.unit_price)
            THEN 'Paid'
        WHEN COALESCE(SUM(p.payment_amount), 0) = 0
            THEN 'Unpaid'
        ELSE 'Partially Paid'
    END AS payment_status
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN order_details od
    ON o.order_id = od.order_id
LEFT JOIN payments p
    ON o.order_id = p.order_id
GROUP BY o.order_id, customer_name;

-- Create View: Sales Summary
CREATE VIEW sales_summary AS
SELECT 
    o.order_id,
    o.order_date,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    p.product_name,
    od.quantity,
    od.unit_price,
    (od.quantity * od.unit_price) AS line_total
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN order_details od
    ON o.order_id = od.order_id
JOIN products p
    ON od.product_id = p.product_id;

-- Use the Sales Summary View
SELECT * FROM sales_summary;

-- Stored Procedure: Get customer order history
DELIMITER //

CREATE PROCEDURE GetCustomerOrderHistory(IN input_customer_id INT)
BEGIN
    SELECT 
        o.order_id,
        o.order_date,
        p.product_name,
        od.quantity,
        od.unit_price,
        (od.quantity * od.unit_price) AS total
    FROM orders o
    JOIN order_details od
        ON o.order_id = od.order_id
    JOIN products p
        ON od.product_id = p.product_id
    WHERE o.customer_id = input_customer_id
    ORDER BY o.order_date;
END //

DELIMITER ;

-- Example procedure call
CALL GetCustomerOrderHistory(1);

-- Trigger: Update inventory after an order detail is inserted
DELIMITER //

CREATE TRIGGER update_inventory_after_order
AFTER INSERT ON order_details
FOR EACH ROW
BEGIN
    UPDATE products
    SET inventory_quantity = inventory_quantity - NEW.quantity
    WHERE product_id = NEW.product_id;
END //

DELIMITER ;
