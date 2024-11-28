### **Lab: Testing Automatic Histogram Updates in MySQL 8.4**

---

#### **Purpose**

This lab explores the functionality and implications of **automatic histogram updates** introduced in MySQL 8.4. Automatic histogram updates allow the database to recalculate and refine histograms automatically when `ANALYZE TABLE` is executed. This ensures optimizer statistics remain up-to-date, improving query performance.

This lab will:

1. **Set up the testing environment** using `anydbver`.
2. **Test histogram creation** with `AUTO UPDATE` and `MANUAL UPDATE` options.
3. **Validate histogram behavior** during table analysis.
4. **Demonstrate scenarios** where automatic histogram updates benefit query optimization.

---

### **Lab Steps**

#### **1. Setup**

**a. Deploy MySQL 8.4 for Testing**

Using `anydbver`, deploy a single MySQL 8.4 instance for testing:

```bash
NAMESPACE='histogram_update'
anydbver deploy ps:8.4 --namespace=$NAMESPACE
```

**b. Access the MySQL Instance**

Connect to the MySQL instance:
```bash
anydbver exec node0 --namespace=$NAMESPACE mysql
```

---

#### **2. Preparing the Database**

**a. Create a Test Database and Table**

Create a database and a table to test histograms:
```sql
CREATE DATABASE histogram_test;
USE histogram_test;

CREATE TABLE orders (
    order_id INT NOT NULL PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL
);
```

**b. Populate the Table with Sample Data**

Insert sample data to simulate a production-like workload:
```sql
INSERT INTO orders (order_id, customer_id, order_date, total_amount)
VALUES
    (1, 1001, '2023-11-01', 200.50),
    (2, 1002, '2023-11-01', 300.00),
    (3, 1001, '2023-11-02', 150.00),
    (4, 1003, '2023-11-03', 400.75),
    (5, 1002, '2023-11-04', 50.25),
    (6, 1004, '2023-11-05', 700.00),
    (7, 1003, '2023-11-06', 600.00),
    (8, 1001, '2023-11-07', 300.00),
    (9, 1002, '2023-11-08', 100.00),
    (10, 1003, '2023-11-09', 250.00);
```

---

#### **3. Creating and Managing Histograms**

**a. Create a Histogram with AUTO UPDATE**

Create a histogram for the `customer_id` column with automatic updates enabled:
```sql
ANALYZE TABLE orders UPDATE HISTOGRAM ON customer_id WITH 5 BUCKETS AUTO UPDATE;
```

Validate the histogram creation:
```sql
SELECT HISTOGRAM FROM information_schema.column_statistics WHERE schema_name = 'histogram_test';
```

**Output**:
```plaintext
{
    "buckets": [
        [
            1001,
            0.3
        ],
        [
            1002,
            0.6
        ],
        [
            1003,
            0.9
        ],
        [
            1004,
            1.0
        ]
    ],
    "data-type": "int",
    "auto-update": true,
    "null-values": 0.0,
    "collation-id": 8,
    "last-updated": "2024-11-28 11:38:45.197599",
    "sampling-rate": 1.0,
    "histogram-type": "singleton",
    "number-of-buckets-specified": 5
}
```

---

#### **4. Testing Histogram Updates**

**a. Test Automatic Histogram Updates**

Insert additional rows and run `ANALYZE TABLE` to trigger automatic updates:
```sql
INSERT INTO orders (order_id, customer_id, order_date, total_amount)
VALUES
    (11, 1005, '2023-11-10', 150.00),
    (12, 1006, '2023-11-11', 200.00);

ANALYZE TABLE orders;
```

Validate that the histogram for `customer_id` has been updated:
```sql
SELECT HISTOGRAM FROM information_schema.column_statistics WHERE schema_name = 'histogram_test';
```

**Output**:
```plaintext
{
    "buckets": [
        [
            1001,
            1001,
            0.25,
            1
        ],
        [
            1002,
            1002,
            0.5,
            1
        ],
        [
            1003,
            1003,
            0.75,
            1
        ],
        [
            1004,
            1005,
            0.9166666666666666,
            2
        ],
        [
            1006,
            1006,
            1.0,
            1
        ]
    ],
    "data-type": "int",
    "auto-update": true,
    "null-values": 0.0,
    "collation-id": 8,
    "last-updated": "2024-11-28 11:43:20.113173",
    "sampling-rate": 1.0,
    "histogram-type": "equi-height",
    "number-of-buckets-specified": 5
}
```

---

### **Conclusion**

1. **Automatic Histogram Updates** ensure optimizer statistics remain current without manual intervention.
2. **Manual Updates** provide control over histogram recalculations for performance-critical scenarios.
