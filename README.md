# QuickFood
An end-to-end SQL project that simulates a food delivery platform to analyze customer behavior, restaurant performance, and delivery efficiency. Includes 20+ business queries and real world insights.A set of PostgreSQL queries that answer real business questions for a food delivery platform: what customers order, when they order, which restaurants earn the most, and which customers are leaving.

---

## 📌 Table of Contents

- [Project Overview](#-project-overview)
- [Database Schema](#-database-schema)
- [Business Questions Solved](#-business-questions-solved)
- [Featured Queries](#-featured-queries)
- [SQL Skills Demonstrated](#-sql-skills-demonstrated)
- [Assumptions and Limitations](#-assumptions-and-limitations)
- [How to Run](#-how-to-run)
- [Repository Structure](#-repository-structure)
- [Author](#-author)

---

## 🎯 Project Overview

**Goal:** Turn raw order, customer, restaurant and delivery data into answers a business team can act on.

**What this project covers:**

- Customer behaviour (favourite dishes, spending, churn)
- Operations (busiest time slots, undelivered orders)
- Restaurant performance (revenue ranking, popular dishes by city)
- Customer segmentation (Gold vs Silver)

**Tech:** PostgreSQL, pgAdmin

---

## 🗂️ Database Schema

The project uses four tables. Columns below are the ones used in the queries.

| Table | Key Columns |
|---|---|
| `customers` | `customer_id`, `customer_name` |
| `restaurants` | `restaurant_id`, `restaurant_name`, `"City"` |
| `orders` | `order_id`, `customer_id`, `restaurant_id`, `order_item`, `order_date`, `order_time`, `total_amount`, `order_status` |
| `deliveries` | `order_id`, `rider_id`, `delivery_status`, `delivery_time` |

```
customers ──< orders >── restaurants
                │
                └──< deliveries
```

> **Note:** `"City"` is stored with a capital C, so PostgreSQL needs it in double quotes.

---

## ❓ Business Questions Solved

| # | Question | Key Technique |
|---|---|---|
| 1 | Top 5 dishes ordered by one customer in the last year | `JOIN`, `GROUP BY`, `LIMIT` |
| 2 | Busiest 2-hour time slots | `EXTRACT`, `CASE` |
| 3 | Average order value for customers with 750+ orders | `AVG`, `HAVING` |
| 5 | Undelivered orders per restaurant and city | `WHERE`, `GROUP BY` |
| 6 | Restaurant revenue ranking within each city | Window function `RANK()` |
| 7 | Most popular dish in each city | CTE + `RANK()` |
| 8 | Customers active in 2023 but not in 2024 (churn) | `NOT EXISTS` |
| 9 | Gold / Silver customer segmentation | CTE, `CASE`, subquery |
| 10 | Customer Lifetime Value (CLV) | `SUM`, `GROUP BY` |

---

## 🔍 Featured Queries

### 1. Top 5 dishes for one customer (last 1 year)

```sql
SELECT
    c.customer_name,
    o.order_item AS dish,
    COUNT(o.order_id) AS total_orders
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
WHERE c.customer_name = 'Arjun Mehta'
  AND o.order_date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY c.customer_name, o.order_item
ORDER BY total_orders DESC
LIMIT 5;
```

### 2. Popular 2-hour time slots

```sql
SELECT
    (EXTRACT(HOUR FROM order_time)::int / 2) * 2 AS slot_start_hour,
    COUNT(order_id) AS order_count
FROM orders
GROUP BY slot_start_hour
ORDER BY order_count DESC;
```

`slot_start_hour = 18` means the 18:00 to 20:00 slot. Integer division maps each hour to its slot start.

### 6. Restaurant revenue ranking within each city

```sql
WITH ranking_table AS (
    SELECT
        r.restaurant_id,
        r.restaurant_name,
        r."City" AS city,
        SUM(o.total_amount) AS revenue,
        RANK() OVER (
            PARTITION BY r."City"
            ORDER BY SUM(o.total_amount) DESC
        ) AS city_rank
    FROM orders o
    JOIN restaurants r ON r.restaurant_id = o.restaurant_id
    WHERE o.order_date >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY r.restaurant_id, r.restaurant_name, r."City"
)
SELECT * FROM ranking_table
ORDER BY city, city_rank;
```

### 7. Most popular dish in each city

```sql
WITH dish_counts AS (
    SELECT
        r."City" AS city,
        o.order_item AS dish,
        COUNT(o.order_id) AS total_orders,
        RANK() OVER (
            PARTITION BY r."City"
            ORDER BY COUNT(o.order_id) DESC
        ) AS city_rank
    FROM orders o
    JOIN restaurants r ON r.restaurant_id = o.restaurant_id
    GROUP BY r."City", o.order_item
)
SELECT city, dish, total_orders
FROM dish_counts
WHERE city_rank = 1
ORDER BY city;
```

### 8. Customer churn (ordered in 2023, not in 2024)

```sql
SELECT DISTINCT o23.customer_id
FROM orders o23
WHERE o23.order_date >= DATE '2023-01-01'
  AND o23.order_date <  DATE '2024-01-01'
  AND NOT EXISTS (
      SELECT 1
      FROM orders o24
      WHERE o24.customer_id = o23.customer_id
        AND o24.order_date >= DATE '2024-01-01'
        AND o24.order_date <  DATE '2025-01-01'
  );
```

`NOT EXISTS` is safer than `NOT IN`. If the subquery returns even one `NULL`, `NOT IN` returns no rows at all.

### 9. Gold / Silver customer segmentation

```sql
WITH customer_spend AS (
    SELECT
        customer_id,
        SUM(total_amount) AS revenue,
        COUNT(order_id)   AS total_orders
    FROM orders
    GROUP BY customer_id
),
segmented AS (
    SELECT
        *,
        CASE
            WHEN revenue > (SELECT AVG(revenue) FROM customer_spend)
                THEN 'Gold'
            ELSE 'Silver'
        END AS customer_category
    FROM customer_spend
)
SELECT
    customer_category,
    COUNT(*)          AS customers,
    SUM(total_orders) AS total_orders,
    SUM(revenue)      AS total_revenue
FROM segmented
GROUP BY customer_category;
```

### 10. Customer Lifetime Value

```sql
SELECT
    c.customer_id,
    c.customer_name,
    SUM(o.total_amount) AS clv
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY clv DESC;
```

The full set of queries is in [`Food_Analysis_SQL.sql`](./Food_Analysis_SQL.sql).

---

## 🧠 SQL Skills Demonstrated

- **Joins:** `INNER JOIN` across customers, orders, restaurants and deliveries
- **Aggregation:** `COUNT`, `SUM`, `AVG`, `GROUP BY`, `HAVING`
- **Window functions:** `RANK() OVER (PARTITION BY ... ORDER BY ...)`
- **CTEs:** multi-step logic with `WITH`
- **Conditional logic:** `CASE WHEN` for time slots and segments
- **Date and time handling:** `EXTRACT`, `INTERVAL`, `CURRENT_DATE`
- **Subqueries:** scalar subqueries and `NOT EXISTS`
- **Data hygiene:** case-sensitive identifiers, `NULL` handling

---

## ⚠️ Assumptions and Limitations

- **Revenue includes all orders** unless a query filters `order_status`. Unfulfilled or cancelled orders should be excluded for true revenue.
- **Gold / Silver** compares each customer's total spend with the average total spend per customer. It does not compare with average single-order value, because that would label almost everyone Gold.
- **Ties** in ranking queries use `RANK()`, so tied dishes or restaurants all appear. Use `ROW_NUMBER()` for exactly one winner.
- **Time columns:** if `order_time` and `delivery_time` are `time` (not `timestamp`), deliveries that cross midnight need special handling.
- **Dish names** are counted as stored. Spelling variants such as "Paneer Tikka" and "paneer tikka" count as different dishes.
- **Relative dates** like `CURRENT_DATE - INTERVAL '1 year'` change results depending on when you run them.

---

## 🚀 How to Run

1. Install [PostgreSQL](https://www.postgresql.org/download/) and pgAdmin.
2. Create a database and load the four tables.
3. Open `Food_Analysis_SQL.sql` in the pgAdmin Query Tool.
4. Run one query at a time.

If a query returns zero rows, check the data before the query:

```sql
SELECT DISTINCT order_status FROM orders;
SELECT DISTINCT delivery_status FROM deliveries;
```

---

## 📁 Repository Structure

```
.
├── Food_Analysis_SQL.sql   # All queries, grouped by question
└── README.md
```

---

## 👤 Author

**Yash Saini**

⭐ If this helped you, consider giving the repo a star.
