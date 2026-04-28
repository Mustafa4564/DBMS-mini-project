// ============================================
// RetailHub - Express + MySQL Backend
// ============================================

const express = require('express');
const mysql   = require('mysql2/promise');
const cors    = require('cors');
const path    = require('path');

const app  = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname)));

// ============================================
// DATABASE CONNECTION POOL
// ============================================

const pool = mysql.createPool({
  host:     process.env.DB_HOST     || 'localhost',
  user:     process.env.DB_USER     || 'root',
  password: process.env.DB_PASS     || '',       // ← change to your MySQL password
  database: process.env.DB_NAME     || 'retailhub',
  waitForConnections: true,
  connectionLimit:    10,
});

// ============================================
// PRODUCTS API
// ============================================

// GET all products
app.get('/api/products', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM products ORDER BY created_at DESC');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST add product
app.post('/api/products', async (req, res) => {
  const { name, price, stock, category, description } = req.body;
  try {
    const [result] = await pool.query(
      'INSERT INTO products (name, price, stock, category, description) VALUES (?, ?, ?, ?, ?)',
      [name, price, stock, category, description]
    );
    const [rows] = await pool.query('SELECT * FROM products WHERE id = ?', [result.insertId]);
    res.status(201).json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PATCH update product stock
app.patch('/api/products/:id', async (req, res) => {
  const { stock } = req.body;
  try {
    await pool.query('UPDATE products SET stock = ? WHERE id = ?', [stock, req.params.id]);
    const [rows] = await pool.query('SELECT * FROM products WHERE id = ?', [req.params.id]);
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE product
app.delete('/api/products/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM products WHERE id = ?', [req.params.id]);
    res.json({ message: 'Product deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ============================================
// CUSTOMERS API
// ============================================

// GET all customers with order summary (via VIEW)
app.get('/api/customers', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM customer_summary ORDER BY date_joined DESC');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST add customer
app.post('/api/customers', async (req, res) => {
  const { name, email, phone, address } = req.body;
  try {
    const [result] = await pool.query(
      'INSERT INTO customers (name, email, phone, address) VALUES (?, ?, ?, ?)',
      [name, email, phone, address]
    );
    const [rows] = await pool.query('SELECT * FROM customers WHERE id = ?', [result.insertId]);
    res.status(201).json(rows[0]);
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(400).json({ error: 'Email already exists' });
    }
    res.status(500).json({ error: err.message });
  }
});

// DELETE customer
app.delete('/api/customers/:id', async (req, res) => {
  try {
    await pool.query('DELETE FROM customers WHERE id = ?', [req.params.id]);
    res.json({ message: 'Customer deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ============================================
// ORDERS API
// ============================================

// GET all orders (via VIEW with JOIN details)
app.get('/api/orders', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT * FROM order_details ORDER BY created_at DESC');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST place order (uses stored procedure)
app.post('/api/orders', async (req, res) => {
  const { customer_id, product_id, quantity } = req.body;
  try {
    // Call stored procedure
    const [results] = await pool.query(
      'CALL place_order(?, ?, ?, @order_id, @msg)',
      [customer_id, product_id, quantity]
    );
    const [[out]] = await pool.query('SELECT @order_id AS order_id, @msg AS message');

    if (out.order_id === 0) {
      return res.status(400).json({ error: out.message });
    }
    res.status(201).json({ order_id: out.order_id, message: out.message });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// PATCH update order status
app.patch('/api/orders/:id/status', async (req, res) => {
  const { status } = req.body;
  try {
    await pool.query('UPDATE orders SET status = ? WHERE id = ?', [status, req.params.id]);
    res.json({ message: 'Order status updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ============================================
// DASHBOARD / ANALYTICS API
// ============================================

app.get('/api/dashboard', async (req, res) => {
  try {
    const [[{ total_products }]] = await pool.query('SELECT COUNT(*) AS total_products FROM products');
    const [[{ total_customers }]] = await pool.query('SELECT COUNT(*) AS total_customers FROM customers');
    const [[{ total_orders }]] = await pool.query('SELECT COUNT(*) AS total_orders FROM orders');
    const [[{ revenue }]] = await pool.query('SELECT get_total_revenue() AS revenue');
    const [recent_orders] = await pool.query(
      'SELECT * FROM order_details ORDER BY created_at DESC LIMIT 5'
    );

    res.json({ total_products, total_customers, total_orders, revenue, recent_orders });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ============================================
// SERVE FRONTEND
// ============================================

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

// ============================================
// START SERVER
// ============================================

app.listen(PORT, () => {
  console.log(`✅ RetailHub running at http://localhost:${PORT}`);
  console.log(`   Connected to MySQL database: retailhub`);
});
