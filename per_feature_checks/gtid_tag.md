### **Lab: Testing Tagged GTIDs in MySQL Replication (8.4)**

---

#### **Purpose**

This lab demonstrates the functionality and implications of **Tagged GTIDs** in MySQL 8.4 replication. Tagged GTIDs allow categorization of transactions (e.g., administrative or data operations) using the format `UUID:TAG:NUMBER`. The lab will:

1. **Configure a replication setup** with tagged GTIDs using `anydbver`.
2. **Test replication functionality** with tagged GTIDs.
3. **Validate GTID behavior** across master and replica.
4. **Demonstrate use cases** for tagged GTIDs, including tagging transactions and validating replication consistency.

---

### **Lab Steps**

#### **1. Setup**

**a. Deploy MySQL 8.4 Master and Replica**

Using `anydbver`, deploy a master-replica setup with GTID replication enabled:

- Deploy Master (`node0`) & Replica (`node1`):
  ```bash
  NAMESPACE='gtid_tag'
  anydbver deploy ps:8.4 node1 ps:8.4,master=node0 --namespace=$NAMESPACE
  ```

**b. Validate Deployment**

- Confirm both nodes are running:
  ```bash
  NAMESPACE='gtid_tag'
  anydbver list --namespace=$NAMESPACE
  ```

- Access the master (`node0`):
  ```bash
  NAMESPACE='gtid_tag'
  anydbver exec node0 --namespace=$NAMESPACE mysql
  ```

- Access the replica (`node1`):
  ```bash
  NAMESPACE='gtid_tag'
  anydbver exec node1 --namespace=$NAMESPACE mysql
  ```

**c. Configure Master for Replication**

On `node0` (master), update privileges to allow replication:
```sql
UPDATE mysql.user SET host='%' WHERE user='root';
FLUSH PRIVILEGES;
```

**d. Start Replica**

On the replica (`node1`), execute:
```sql
STOP REPLICA;
START REPLICA;
```

To verify replication status:
```sql
SHOW REPLICA STATUS\G
```

---

#### **2. Testing Tagged GTIDs**

**a. Create a User with Required Privileges**

On the master (`node0`), create a dedicated user for tagged GTID testing:
```sql
CREATE USER 'tag_user'@'%' IDENTIFIED BY 'password';
GRANT CREATE USER, GRANT OPTION, CREATE, SELECT, INSERT, UPDATE, DELETE, TRANSACTION_GTID_TAG, SYSTEM_VARIABLES_ADMIN ON *.* TO 'tag_user'@'%';
```

Use the following command to connect as `tag_user`:
```bash
anydbver exec node0 --namespace=$NAMESPACE -- mysql -utag_user -ppassword
```

**b. Create Tagged Transactions**

**Administrative Transactions**:
```sql
SET gtid_next = 'AUTOMATIC:admin_ops';
CREATE USER 'admin_user'@'%' IDENTIFIED BY 'securepassword';
GRANT SELECT ON *.* TO 'admin_user'@'%';
SET gtid_next = AUTOMATIC;
```

**Data Transactions**:
```sql
SET gtid_next = 'AUTOMATIC:data_ops';
CREATE DATABASE test_db;
USE test_db;
CREATE TABLE data_table (id INT PRIMARY KEY, data VARCHAR(100));
INSERT INTO data_table VALUES (1, 'Data Operations');
SET gtid_next = AUTOMATIC;
```

**c. Validate Tagged Transactions**

Check GTID execution logs:
```sql
SELECT * FROM mysql.gtid_executed;
```

**Expected Output**:
```plaintext
mysql> SELECT * FROM mysql.gtid_executed;
+--------------------------------------+----------------+--------------+-----------+
| source_uuid                          | interval_start | interval_end | gtid_tag  |
+--------------------------------------+----------------+--------------+-----------+
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              1 |            1 |           |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              3 |            3 |           |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              4 |            4 |           |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              1 |            2 | admin_ops |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              1 |            2 | data_ops  |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              3 |            3 | data_ops  |
+--------------------------------------+----------------+--------------+-----------+

mysql> select @@gtid_executed;
+---------------------------------------------------------------------+
| @@gtid_executed                                                     |
+---------------------------------------------------------------------+
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02:1-4:admin_ops:1-2:data_ops:1-3 |
+---------------------------------------------------------------------+
1 row in set (0.00 sec)

```

---

#### **3. Testing Tagged GTID Behavior**

**a. Verify Replication**

On the replica (`node1`), check replication status:
```sql
SHOW REPLICA STATUS\G
```

Verify that tagged transactions were replicated:
```sql
SELECT * FROM mysql.gtid_executed;
```

**Expected Output**:
```plaintext
mysql> SELECT * FROM mysql.gtid_executed;
+--------------------------------------+----------------+--------------+-----------+
| source_uuid                          | interval_start | interval_end | gtid_tag  |
+--------------------------------------+----------------+--------------+-----------+
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              1 |            1 |           |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              3 |            3 |           |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              4 |            4 |           |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              1 |            2 | admin_ops |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              1 |            2 | data_ops  |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              3 |            3 | data_ops  |
+--------------------------------------+----------------+--------------+-----------+

mysql> select @@gtid_executed;
+---------------------------------------------------------------------+
| @@gtid_executed                                                     |
+---------------------------------------------------------------------+
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02:1-4:admin_ops:1-2:data_ops:1-3 |
+---------------------------------------------------------------------+
```

---

### **4.  Testing with Custom Tagged GTIDs**

#### **4.1 Assigning and Using Custom GTIDs**

1. **Assign a Custom GTID**:
   ```sql
   SET gtid_next = '3a0f0d2e-ad73-11ef-8380-0242ac1f1d02:maintenance:30';
   CREATE TABLE custom_table (id INT PRIMARY KEY, data VARCHAR(100));
   ```
   **Output**:
   ```plaintext
   Query OK, 0 rows affected (0.76 sec)
   ```

2. **Attempt Another Transaction Without Resetting GTID**:
   ```sql
   INSERT INTO custom_table VALUES (1, 'test');
   ```
   **Error**:
   ```plaintext
   ERROR 1837 (HY000): When @@SESSION.GTID_NEXT is set to a GTID, you must explicitly set it to a different value after a COMMIT or ROLLBACK.
   ```

3. **Reset GTID for a New Transaction**:
   ```sql
   SET gtid_next = '3a0f0d2e-ad73-11ef-8380-0242ac1f1d02:maintenance:31';
   INSERT INTO custom_table VALUES (1, 'test');
   ```
   **Output**:
   ```plaintext
   Query OK, 1 row affected (1.57 sec)
   ```

4. **Validate gtid_executed**:

```plaintext
   mysql> select @@gtid_executed;
+----------------------------------------------------------------------------------------+
| @@gtid_executed                                                                        |
+----------------------------------------------------------------------------------------+
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02:1-4:admin_ops:1-2:data_ops:1-3:maintenance:30:31 |
+----------------------------------------------------------------------------------------+
1 row in set (0.00 sec)
```

#### **4.2 Key Takeaways**

- **GTID Enforcement**: Each transaction requires a unique `UUID:TAG:NUMBER` or `AUTOMATIC` reset after commit/rollback.
- **Error Resolution**: Always reset `gtid_next` to proceed with new transactions under GTID management.

---

### **5. Testing GTID Functions with Tagged GTIDs**

This section demonstrates the usage of GTID functions compatible with tagged GTIDs, including `GTID_SUBSET()`, `GTID_SUBTRACT()`, and `WAIT_FOR_EXECUTED_GTID_SET()`.

---

#### **5.1 `GTID_SUBSET()`**

**Purpose**: Checks if one GTID set is a subset of another.

**Example**:
```sql

mysql> SELECT * FROM mysql.gtid_executed;
+--------------------------------------+----------------+--------------+--------------+
| source_uuid                          | interval_start | interval_end | gtid_tag     |
+--------------------------------------+----------------+--------------+--------------+
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              1 |            1 |              |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              3 |            3 |              |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              4 |            4 |              |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              1 |            2 | admin_ops    |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              1 |            2 | data_ops     |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              3 |            3 | data_ops     |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              4 |            4 | data_ops     |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              5 |            5 | data_ops     |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              6 |            6 | data_ops     |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              7 |            7 | data_ops     |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              8 |            8 | data_ops     |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              9 |            9 | data_ops     |
+--------------------------------------+----------------+--------------+--------------+
14 rows in set (0.00 sec)

SELECT GTID_SUBSET(
  '3a0f0d2e-ad73-11ef-8380-0242ac1f1d02:data_ops:2-4',
  '3a0f0d2e-ad73-11ef-8380-0242ac1f1d02:data_ops:1-9'
) AS IsSubset;
```

**Output**:
```plaintext
+-----------+
| IsSubset  |
+-----------+
| 1         |  -- True, the first set is a subset of the second.
+-----------+
```

---

#### **5.2 `GTID_SUBTRACT()`**

**Purpose**: Returns the GTIDs in the first set that are not in the second.

**Example**:
```sql

mysql> SELECT * FROM mysql.gtid_executed where gtid_tag='data_ops';
+--------------------------------------+----------------+--------------+----------+
| source_uuid                          | interval_start | interval_end | gtid_tag |
+--------------------------------------+----------------+--------------+----------+
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              1 |            2 | data_ops |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              3 |            3 | data_ops |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              4 |            4 | data_ops |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              5 |            5 | data_ops |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              6 |            6 | data_ops |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              7 |            7 | data_ops |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              8 |            8 | data_ops |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              9 |            9 | data_ops |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |             10 |           10 | data_ops |
+--------------------------------------+----------------+--------------+----------+
9 rows in set (0.00 sec)


SELECT GTID_SUBTRACT(
  '3a0f0d2e-ad73-11ef-8380-0242ac1f1d02:data_ops:1-9',
  '3a0f0d2e-ad73-11ef-8380-0242ac1f1d02:data_ops:2-4'
) AS Difference;
```

**Output**:
```plaintext
+-----------------------------------------------------+
| Difference                                          |
+-----------------------------------------------------+
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02:data_ops:1:5-9 |
+-----------------------------------------------------+
```

---

#### **5.3 `WAIT_FOR_EXECUTED_GTID_SET()`**

**Purpose**: Blocks until the GTID set is executed on the current server or the timeout is reached.

**Example**:
```sql
SELECT WAIT_FOR_EXECUTED_GTID_SET(
  '3a0f0d2e-ad73-11ef-8380-0242ac1f1d02:data_ops:11-15',
  600
) AS WaitResult;
```


Meanwhile at the master:

```sql
mysql> SELECT * FROM mysql.gtid_executed where gtid_tag='data_ops';
+--------------------------------------+----------------+--------------+----------+
| source_uuid                          | interval_start | interval_end | gtid_tag |
+--------------------------------------+----------------+--------------+----------+
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              1 |            1 | data_ops |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              2 |            3 | data_ops |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              4 |            4 | data_ops |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              5 |            5 | data_ops |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              6 |            6 | data_ops |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              7 |            7 | data_ops |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              8 |            8 | data_ops |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |              9 |            9 | data_ops |
| 3a0f0d2e-ad73-11ef-8380-0242ac1f1d02 |             10 |           10 | data_ops |
+--------------------------------------+----------------+--------------+----------+
9 rows in set (0.00 sec)

mysql> SET gtid_next = 'AUTOMATIC:data_ops';
Query OK, 0 rows affected (0.00 sec)

mysql> INSERT INTO data_table (id, data) VALUES(31,'test');
Query OK, 1 row affected (0.03 sec)

mysql> INSERT INTO data_table (id, data) VALUES(32,'test');
Query OK, 1 row affected (0.09 sec)

mysql> INSERT INTO data_table (id, data) VALUES(33,'test');
Query OK, 1 row affected (0.27 sec)

mysql> INSERT INTO data_table (id, data) VALUES(34,'test');
Query OK, 1 row affected (0.03 sec)

mysql> INSERT INTO data_table (id, data) VALUES(35,'test');
Query OK, 1 row affected (0.05 sec)
```

**Output**:
```plaintext
+-------------+
| WaitResult  |
+-------------+
| 0           |  -- Completed successfully within the timeout.
+-------------+
```


---

#### **Conclusion**

1. Tagged GTIDs simplify transaction categorization and monitoring.
2. Unique GTID tags enhance debugging, recovery, and replication management.
3. Proper privilege configuration ensures secure and effective GTID tagging.
