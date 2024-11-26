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

- Access the master (`node0`) :
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

**d. Verify GTID Configuration**

Check if GTIDs are enabled on both master and replica:
```sql
SHOW VARIABLES LIKE 'gtid_mode';
SHOW VARIABLES LIKE 'enforce_gtid_consistency';
```

Ensure both variables are set to `ON`. If not, modify `my.cnf` using:
```bash
anydbver exec node0 --namespace=$NAMESPACE -- bash -c "echo 'gtid_mode=ON' >> /etc/my.cnf"
anydbver exec node0 --namespace=$NAMESPACE -- bash -c "echo 'enforce_gtid_consistency=ON' >> /etc/my.cnf"
anydbver exec node0 --namespace=$NAMESPACE -- systemctl restart mysqld
```

Repeat for `node1`.

---

#### **2. Testing Tagged GTIDs**

**a. Create a Tagged Transaction on the Master**

Tag administrative transactions with `admin_ops`:
```sql
SET gtid_next = 'AUTOMATIC:admin_ops';
CREATE TABLE admin_table (id INT PRIMARY KEY, data VARCHAR(100));
INSERT INTO admin_table VALUES (1, 'Admin Data');
SET gtid_next = AUTOMATIC;
```

Tag data operations with `data_ops`:
```sql
SET gtid_next = 'AUTOMATIC:data_ops';
CREATE TABLE data_table (id INT PRIMARY KEY, data VARCHAR(100));
INSERT INTO data_table VALUES (1, 'Data Operations');
SET gtid_next = AUTOMATIC;
```

**b. Validate Tagged Transactions**

Check GTID execution logs on the master:
```sql
SELECT * FROM mysql.gtid_executed;
```

Expected output:
```plaintext
+--------------------------------------+----------------+--------------+-----------+
| source_uuid                          | interval_start | interval_end | gtid_tag  |
+--------------------------------------+----------------+--------------+-----------+
| <UUID>                               |              1 |            1 | admin_ops |
| <UUID>                               |              2 |            2 | data_ops  |
+--------------------------------------+----------------+--------------+-----------+
```

**c. Verify Replication**

On the replica (`node1`):
- Confirm replication status:
  ```sql
  SHOW SLAVE STATUS\G
  ```
- Check if tagged transactions were replicated:
  ```sql
  SELECT * FROM mysql.gtid_executed;
  ```

---

#### **3. Testing Tagged GTID Behavior**

**a. Conflict Testing**

Attempt to re-use the same tag in a different transaction:
```sql
SET gtid_next = 'AUTOMATIC:data_ops';
CREATE TABLE conflict_table (id INT PRIMARY KEY, data VARCHAR(100));
SET gtid_next = AUTOMATIC;
```

Expected behavior:
- MySQL prevents overlapping GTIDs within the same UUID.

**b. Restrict Tag Usage**

Grant the `TRANSACTION_GTID_TAG` privilege to a user:
```sql
CREATE USER 'tag_user'@'%' IDENTIFIED BY 'password';
GRANT TRANSACTION_GTID_TAG ON *.* TO 'tag_user'@'%';
```

Login as `tag_user` and try creating a tagged transaction:
```sql
SET gtid_next = 'AUTOMATIC:custom_tag';
CREATE TABLE user_table (id INT PRIMARY KEY, data VARCHAR(100));
```

Expected behavior:
- Successful execution with correct tagging.

---

#### **4. Advanced Scenarios**

**a. Validate Replication Lag with GTID Tags**

Check GTID subsets on the replica:
```sql
SELECT GTID_SUBSET(
  'UUID:admin_ops:1-5',
  (SELECT @@global.gtid_executed)
) AS Admin_GTID_Executed;
```

**b. Cleanup and Test Recovery**

1. **Simulate Data Loss**: 
   Drop a table on the replica:
   ```sql
   DROP TABLE data_table;
   ```

2. **Restore via GTID Tag**:
   Use the GTID tag to identify and reapply missing transactions:
   ```sql
   START SLAVE UNTIL GTID_SUBSET('UUID:data_ops:1-5', @@global.gtid_executed);
   ```

---

#### **5. Monitoring with PMM**

Use PMM (Percona Monitoring and Management) to monitor GTID transactions:

1. Deploy PMM Server:
   ```bash
   anydbver deploy pmm:latest --namespace=$NAMESPACE
   ```

2. Deploy PMM Client on Master and Replica:
   ```bash
   anydbver deploy pmm-client --server=node0,mysql=node0 --namespace=$NAMESPACE
   anydbver deploy pmm-client --server=node0,mysql=node1 --namespace=$NAMESPACE
   ```

3. Add monitoring metrics:
   - Enable replication metrics in PMM.
   - Monitor GTID subsets via dashboards.

---

#### **6. Document Observations**

**a. Transaction Logs:**

Record and analyze GTID logs from both master and replica:
```sql
SELECT * FROM mysql.gtid_executed;
```

**b. Test Output Summary:**

Document outcomes of each test, including replication behavior, tag conflicts, and monitoring insights.

---

#### **Conclusion**

1. Tagged GTIDs simplify transaction categorization and monitoring.
2. Unique GTID tags enhance debugging, disaster recovery, and replication management.
3. Ensure correct privilege assignments and tag uniqueness to avoid conflicts.

This lab comprehensively tests and validates tagged GTIDs in MySQL 8.4 replication, offering insights into their practical implications.