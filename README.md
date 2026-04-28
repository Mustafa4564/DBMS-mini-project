# 📦 RetailHub — MySQL Edition

A full-stack Online Retail Store Management System rebuilt with:
- **Frontend**: HTML5 / CSS3 / Vanilla JS (Fetch API)
- **Backend**: Node.js + Express.js
- **Database**: MySQL (with Views, Stored Procedures, Functions, Indexes)

---

## 📁 Project Structure

```
retailhub-mysql/
├── schema.sql      ← MySQL database setup (run this first)
├── server.js       ← Express REST API backend
├── index.html      ← Frontend UI (served by Express)
├── package.json    ← Node.js dependencies
└── README.md       ← This file
```

---

## 🚀 Setup Instructions

### Step 1 — Install Node.js dependencies

```bash
npm install
```

### Step 2 — Set up MySQL database

Open MySQL Workbench or your terminal and run:

```bash
mysql -u root -p < schema.sql
```

Or paste the contents of `schema.sql` directly into MySQL Workbench and execute.

This will create:
- `retailhub` database
- `products`, `customers`, `orders` tables
- Views: `order_details`, `customer_summary`
- Stored Procedure: `place_order`
- Functions: `get_total_revenue`, `get_stock_status`
- Indexes for performance
- Sample data (7 products, 3 customers)

### Step 3 — Configure database credentials

Edit `server.js` and update this section:

```js
const pool = mysql.createPool({
  host:     'localhost',
  user:     'root',
  password: 'YOUR_MYSQL_PASSWORD',   // ← change this
  database: 'retailhub',
});
```

### Step 4 — Start the server

```bash
npm start           # production
npm run dev         # development (auto-restart with nodemon)
```

### Step 5 — Open in browser

```
http://localhost:3000
```

---

## 🔌 API Endpoints

| Method | Endpoint                   | Description              |
|--------|----------------------------|--------------------------|
| GET    | /api/dashboard             | Stats + recent orders    |
| GET    | /api/products              | All products             |
| POST   | /api/products              | Add product              |
| PATCH  | /api/products/:id          | Update stock             |
| DELETE | /api/products/:id          | Delete product           |
| GET    | /api/customers             | All customers (summary)  |
| POST   | /api/customers             | Add customer             |
| DELETE | /api/customers/:id         | Delete customer          |
| GET    | /api/orders                | All orders (with joins)  |
| POST   | /api/orders                | Place order (via SP)     |
| PATCH  | /api/orders/:id/status     | Update order status      |

---

## 🗄️ MySQL Features Used

| Feature            | Usage                                             |
|--------------------|---------------------------------------------------|
| Tables             | products, customers, orders                       |
| Foreign Keys       | orders → customers, orders → products             |
| Views              | order_details (JOIN), customer_summary (GROUP BY) |
| Stored Procedure   | place_order (stock check + insert + deduct)       |
| Functions          | get_total_revenue, get_stock_status               |
| Indexes            | customer_id, product_id, status, category         |
| ENUM               | order status field                                |
| DECIMAL            | price and total fields                            |

---

## ✅ Features

- **Dashboard** – Live stats (products, customers, orders, revenue)
- **Products** – Add, view, delete products; category icons
- **Orders** – Place orders via stored procedure; update status
- **Customers** – Manage customers; view order count & total spent
- **Inventory** – View stock levels; adjust stock quantities

---

## 🔐 Environment Variables (optional)

```
DB_HOST=localhost
DB_USER=root
DB_PASS=yourpassword
DB_NAME=retailhub
PORT=3000
```
