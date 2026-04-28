-- ============================================
-- RetailHub - MySQL Database Schema
-- ============================================

CREATE DATABASE IF NOT EXISTS retailhub;
USE retailhub;

-- ============================================
-- TABLES
-- ============================================

CREATE TABLE IF NOT EXISTS products (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(255)    NOT NULL,
  price       DECIMAL(10, 2)  NOT NULL,
  stock       INT             NOT NULL DEFAULT 0,
  category    VARCHAR(100),
  description TEXT,
  created_at  TIMESTAMP       DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS customers (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(255)    NOT NULL,
  email       VARCHAR(255)    UNIQUE NOT NULL,
  phone       VARCHAR(50),
  address     TEXT,
  date_joined TIMESTAMP       DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS orders (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  order_code  VARCHAR(20)     UNIQUE,
  customer_id INT             NOT NULL,
  product_id  INT             NOT NULL,
  quantity    INT             NOT NULL,
  total       DECIMAL(10, 2)  NOT NULL,
  status      ENUM('pending', 'shipped', 'delivered', 'cancelled') DEFAULT 'pending',
  created_at  TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id)  REFERENCES products(id)  ON DELETE CASCADE
);

-- ============================================
-- INDEXES (for faster query performance)
-- ============================================

CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_product  ON orders(product_id);
CREATE INDEX idx_orders_status   ON orders(status);
CREATE INDEX idx_products_category ON products(category);

-- ============================================
-- VIEWS
-- ============================================

-- View: Orders with customer and product details
CREATE OR REPLACE VIEW order_details AS
  SELECT
    o.id,
    o.order_code,
    c.name  AS customer_name,
    c.email AS customer_email,
    p.name  AS product_name,
    p.price AS unit_price,
    o.quantity,
    o.total,
    o.status,
    o.created_at
  FROM orders o
  JOIN customers c ON o.customer_id = c.id
  JOIN products  p ON o.product_id  = p.id;

-- View: Customer summary with total orders and revenue
CREATE OR REPLACE VIEW customer_summary AS
  SELECT
    c.id,
    c.name,
    c.email,
    c.phone,
    c.address,
    c.date_joined,
    COUNT(o.id)   AS total_orders,
    COALESCE(SUM(o.total), 0) AS total_spent
  FROM customers c
  LEFT JOIN orders o ON c.id = o.customer_id
  GROUP BY c.id, c.name, c.email, c.phone, c.address, c.date_joined;

-- ============================================
-- STORED PROCEDURES
-- ============================================

DELIMITER //

-- Procedure: Place a new order
CREATE PROCEDURE place_order(
  IN p_customer_id INT,
  IN p_product_id  INT,
  IN p_quantity    INT,
  OUT p_order_id   INT,
  OUT p_message    VARCHAR(255)
)
BEGIN
  DECLARE v_stock INT;
  DECLARE v_price DECIMAL(10,2);
  DECLARE v_total DECIMAL(10,2);
  DECLARE v_order_code VARCHAR(20);

  -- Check stock availability
  SELECT stock, price INTO v_stock, v_price
  FROM products WHERE id = p_product_id;

  IF v_stock IS NULL THEN
    SET p_order_id = 0;
    SET p_message  = 'Product not found';
  ELSEIF v_stock < p_quantity THEN
    SET p_order_id = 0;
    SET p_message  = 'Insufficient stock';
  ELSE
    SET v_total = v_price * p_quantity;

    -- Insert order
    INSERT INTO orders (customer_id, product_id, quantity, total)
    VALUES (p_customer_id, p_product_id, p_quantity, v_total);

    SET p_order_id   = LAST_INSERT_ID();
    SET v_order_code = CONCAT('ORD-', LPAD(p_order_id, 4, '0'));

    -- Set order code
    UPDATE orders SET order_code = v_order_code WHERE id = p_order_id;

    -- Deduct stock
    UPDATE products SET stock = stock - p_quantity WHERE id = p_product_id;

    SET p_message = 'Order placed successfully';
  END IF;
END //

DELIMITER ;

-- ============================================
-- FUNCTIONS
-- ============================================

DELIMITER //

-- Function: Get total revenue from delivered orders
CREATE FUNCTION get_total_revenue() RETURNS DECIMAL(10,2)
DETERMINISTIC READS SQL DATA
BEGIN
  DECLARE v_total DECIMAL(10,2);
  SELECT COALESCE(SUM(total), 0) INTO v_total FROM orders WHERE status != 'cancelled';
  RETURN v_total;
END //

-- Function: Get stock status label
CREATE FUNCTION get_stock_status(p_stock INT) RETURNS VARCHAR(20)
DETERMINISTIC
BEGIN
  IF p_stock = 0 THEN
    RETURN 'Out of Stock';
  ELSEIF p_stock < 10 THEN
    RETURN 'Low Stock';
  ELSE
    RETURN 'In Stock';
  END IF;
END //

DELIMITER ;

-- ============================================
-- SAMPLE DATA
-- ============================================

INSERT INTO products (name, price, stock, category, description) VALUES
  ('Laptop',      999.99,  15, 'Electronics', 'High-performance laptop with i7 processor'),
  ('Mouse',        29.99,  50, 'Accessories', 'Wireless ergonomic mouse'),
  ('Keyboard',     79.99,  30, 'Accessories', 'Mechanical RGB keyboard'),
  ('Monitor',     399.99,  10, 'Electronics', '27-inch 4K IPS monitor'),
  ('Headphones',  149.99,  25, 'Audio',       'Noise-cancelling over-ear headphones'),
  ('Webcam',       89.99,  20, 'Accessories', '1080p HD webcam with microphone'),
  ('USB Hub',      39.99,  40, 'Accessories', '7-port USB 3.0 hub');

INSERT INTO customers (name, email, phone, address) VALUES
  ('John Doe',   'john@example.com',  '123-456-7890', '123 Main St, Springfield'),
  ('Jane Smith', 'jane@example.com',  '987-654-3210', '456 Oak Ave, Shelbyville'),
  ('Ali Khan',   'ali@example.com',   '555-123-4567', '789 Pine Rd, Pune');
