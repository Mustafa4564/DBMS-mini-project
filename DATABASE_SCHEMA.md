# RetailHub Database Schema Documentation

## Overview
RetailHub uses a client-side database system using browser LocalStorage. This document outlines the complete data structure and relationships.

## Data Collections

### 1. Products Collection

**Storage Key**: `products`

**Schema**:
```json
{
  "id": "number",
  "name": "string",
  "price": "number (decimal)",
  "stock": "number",
  "category": "string",
  "description": "string",
  "createdAt": "ISO 8601 timestamp",
  "updatedAt": "ISO 8601 timestamp (optional)"
}
```

**Example**:
```json
{
  "id": 1,
  "name": "Gaming Laptop",
  "price": 1299.99,
  "stock": 12,
  "category": "Electronics",
  "description": "High-performance gaming laptop with RTX graphics",
  "createdAt": "2024-01-15T10:30:00.000Z"
}
```

**Constraints**:
- `id`: Auto-generated, unique identifier
- `name`: Required, max 255 characters
- `price`: Required, positive number, 2 decimal places
- `stock`: Required, non-negative integer
- `category`: Required, max 100 characters
- `description`: Optional, max 1000 characters

**Indexes**:
- Primary: `id`
- Secondary: `category`, `name`

**Relationships**:
- Referenced by: `orders.productId`

### 2. Customers Collection

**Storage Key**: `customers`

**Schema**:
```json
{
  "id": "number",
  "name": "string",
  "email": "string (email format)",
  "phone": "string",
  "address": "string",
  "dateJoined": "ISO 8601 timestamp",
  "totalOrders": "number (calculated)",
  "totalSpent": "number (calculated)"
}
```

**Example**:
```json
{
  "id": 1,
  "name": "John Doe",
  "email": "john.doe@example.com",
  "phone": "+1-555-0123",
  "address": "123 Main Street, Pune, Maharashtra 411001",
  "dateJoined": "2024-01-10T08:15:00.000Z"
}
```

**Constraints**:
- `id`: Auto-generated, unique identifier
- `name`: Required, max 255 characters
- `email`: Required, unique, valid email format
- `phone`: Required, max 20 characters
- `address`: Required, max 500 characters
- `dateJoined`: Auto-generated on creation

**Indexes**:
- Primary: `id`
- Secondary: `email`

**Relationships**:
- References: Many-to-One with `orders`
- Calculated fields:
  - `totalOrders`: Count of orders where `customerId` = `id`
  - `totalSpent`: Sum of `total` from orders where `customerId` = `id`

### 3. Orders Collection

**Storage Key**: `orders`

**Schema**:
```json
{
  "id": "string (ORD-XXXXX format)",
  "customerId": "number",
  "productId": "number",
  "quantity": "number",
  "total": "number (price × quantity)",
  "status": "enum [pending, shipped, delivered, cancelled]",
  "createdAt": "ISO 8601 timestamp",
  "updatedAt": "ISO 8601 timestamp (optional)",
  "shippingDate": "ISO 8601 timestamp (optional)",
  "deliveryDate": "ISO 8601 timestamp (optional)"
}
```

**Example**:
```json
{
  "id": "ORD-1001",
  "customerId": 1,
  "productId": 5,
  "quantity": 2,
  "total": 2599.98,
  "status": "shipped",
  "createdAt": "2024-01-20T14:30:00.000Z",
  "shippingDate": "2024-01-21T09:00:00.000Z"
}
```

**Constraints**:
- `id`: Auto-generated with format "ORD-" + sequential number
- `customerId`: Required, must exist in customers collection
- `productId`: Required, must exist in products collection
- `quantity`: Required, positive integer, must not exceed product stock
- `total`: Calculated as `product.price × quantity`
- `status`: Must be one of: pending, shipped, delivered, cancelled
- `createdAt`: Auto-generated on order creation

**Status Workflow**:
```
pending → shipped → delivered
   ↓
cancelled (can be cancelled from any status)
```

**Indexes**:
- Primary: `id`
- Secondary: `customerId`, `productId`, `status`, `createdAt`

**Relationships**:
- Foreign Key: `customerId` → `customers.id`
- Foreign Key: `productId` → `products.id`

### 4. Inventory Snapshots (Optional Enhancement)

**Storage Key**: `inventory_history`

**Schema**:
```json
{
  "id": "number",
  "productId": "number",
  "previousStock": "number",
  "newStock": "number",
  "changeReason": "string [order, adjustment, return, damage]",
  "orderId": "string (optional)",
  "timestamp": "ISO 8601 timestamp",
  "changedBy": "string (optional)"
}
```

**Purpose**: Audit trail for inventory changes

## Data Relationships

### Entity Relationship Diagram

```
┌─────────────────────┐
│     CUSTOMERS       │
├─────────────────────┤
│ id (PK)            │
│ name               │
│ email              │
│ phone              │
│ address            │
│ dateJoined         │
└──────────┬──────────┘
           │ 1
           │
           │ M
           │
      ┌────┴─────────┐
      │              │
      │    ORDERS    │
      │              │
┌─────┴──────────────┴──────┐
│                            │
│  id (PK) - "ORD-XXXXX"    │
│  customerId (FK)           │
│  productId (FK)            │
│  quantity                  │
│  total                     │
│  status                    │
│  createdAt                 │
│                            │
└─────────────────────┬──────┘
                      │ M
                      │
                      │ 1
           ┌──────────┘
           │
┌──────────┴────────────┐
│      PRODUCTS         │
├──────────────────────┤
│ id (PK)             │
│ name                │
│ price               │
│ stock               │
│ category            │
│ description         │
│ createdAt           │
└─────────────────────┘
```

### Cardinality Matrix

| From | To | Type | Multiplicity |
|------|-----|------|------------|
| Customers | Orders | 1:M | One customer has many orders |
| Products | Orders | 1:M | One product in many orders |
| Orders | Customers | M:1 | Many orders belong to one customer |
| Orders | Products | M:1 | Many orders reference one product |

## Business Rules & Constraints

### Product Rules
1. Stock cannot be negative
2. Price must be positive
3. Product name must be unique
4. Stock updates automatically when order is placed
5. Cannot delete product with existing orders (soft delete option)

### Customer Rules
1. Email must be unique
2. Email must be in valid format
3. Phone must be valid format
4. Cannot delete customer with existing orders
5. Address changes should be tracked (optional)

### Order Rules
1. Cannot place order with insufficient stock
2. Stock automatically decrements on order placement
3. Order total = product.price × quantity (calculated)
4. Status flow is strictly controlled
5. Cannot modify past orders (read-only after creation)
6. Cancelled orders do NOT restore stock automatically

### Inventory Rules
1. Stock updates in real-time
2. All changes are timestamped
3. Low stock threshold: < 10 units
4. High stock threshold: > 100 units
5. Negative stock is prevented at input level

## Data Access Patterns

### Query Examples

**Get all products in category**:
```javascript
products.filter(p => p.category === 'Electronics')
```

**Get customer order history**:
```javascript
orders.filter(o => o.customerId === 1)
  .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
```

**Get revenue per customer**:
```javascript
customers.map(c => ({
  customerId: c.id,
  revenue: orders
    .filter(o => o.customerId === c.id)
    .reduce((sum, o) => sum + o.total, 0)
}))
```

**Get low stock products**:
```javascript
products.filter(p => p.stock < 10 && p.stock > 0)
```

**Get orders by status**:
```javascript
orders.filter(o => o.status === 'pending')
```

## Data Validation Rules

### Input Validation

| Field | Type | Min | Max | Pattern | Required |
|-------|------|-----|-----|---------|----------|
| Product.name | String | 1 | 255 | Alphanumeric | ✓ |
| Product.price | Number | 0.01 | 999999.99 | Decimal | ✓ |
| Product.stock | Integer | 0 | 999999 | Integer | ✓ |
| Customer.name | String | 1 | 255 | Alphanumeric | ✓ |
| Customer.email | String | 5 | 255 | Email | ✓ |
| Customer.phone | String | 7 | 20 | Phone | ✓ |
| Order.quantity | Integer | 1 | 999 | Integer | ✓ |

## Data Persistence & Recovery

### LocalStorage Limits
- Maximum per domain: ~5MB
- Current application size: ~100KB JSON data
- Can store approximately 50,000 small records

### Data Backup Strategy
1. Export data as JSON (future feature)
2. Browser native export options
3. Periodic manual backups recommended

### Data Recovery
1. LocalStorage is automatically cleared when:
   - Browser cache is cleared
   - Browsing data is deleted
   - Browser storage is full
2. Recovery options:
   - Restore from backup
   - Re-enter data manually

## Future Enhancements

### Database Evolution
1. **Backend Integration**
   - Replace LocalStorage with server database
   - Recommended: PostgreSQL, MongoDB, or Firebase

2. **Additional Collections**
   - Users (with roles and permissions)
   - Categories (separate from products)
   - Suppliers
   - Payments
   - Reviews & Ratings
   - Wishlist

3. **Analytics Collection**
   - Sales metrics
   - Customer behavior
   - Product performance
   - Revenue trends

4. **Audit Log**
   - Track all data changes
   - User activity logs
   - Change timestamps
   - Change authors

## API Endpoints (For Future Backend)

```
GET    /api/products              # List all products
POST   /api/products              # Create product
GET    /api/products/:id          # Get product
PUT    /api/products/:id          # Update product
DELETE /api/products/:id          # Delete product

GET    /api/customers             # List all customers
POST   /api/customers             # Create customer
GET    /api/customers/:id         # Get customer
PUT    /api/customers/:id         # Update customer
DELETE /api/customers/:id         # Delete customer

GET    /api/orders                # List all orders
POST   /api/orders                # Create order
GET    /api/orders/:id            # Get order
PUT    /api/orders/:id            # Update order status
DELETE /api/orders/:id            # Cancel order

GET    /api/inventory             # Get inventory status
PUT    /api/inventory/:productId  # Update stock
```

---

**Database Type**: Client-Side LocalStorage (Can be migrated to backend)  
**Current Version**: 1.0.0  
**Last Updated**: January 2024
