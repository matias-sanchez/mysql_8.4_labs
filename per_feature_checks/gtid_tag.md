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

Check GTID execution logs on the master:
```sql
SELECT * FROM mysql.gtid_executed;
```

**Expected Output**:
```plaintext
+--------------------------------------+----------------+--------------+-----------+
| source_uuid                          | interval_start | interval_end | gtid_tag  |
+--------------------------------------+----------------+--------------+-----------+
| <UUID>                               |              1 |            1 | admin_ops |
| <UUID>                               |              2 |            2 | data_ops  |
+--------------------------------------+----------------+--------------+-----------+
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
+--------------------------------------+----------------+--------------+-----------+
| source_uuid                          | interval_start | interval_end | gtid_tag  |
+--------------------------------------+----------------+--------------+-----------+
| <UUID>                               |              1 |            1 | admin_ops |
| <UUID>                               |              2 |            2 | data_ops  |
+--------------------------------------+----------------+--------------+-----------+
```

**b. Conflict Testing**

Use the same database and tag a conflicting transaction:
```sql
SET gtid_next = 'AUTOMATIC:data_ops';
USE test_db;
CREATE TABLE conflict_table (id INT PRIMARY KEY, data VARCHAR(100));
SET gtid_next = AUTOMATIC;
```

**Expected Behavior**:
- MySQL prevents overlapping GTIDs within the same UUID.

**c. Restrict Tag Usage**

Login as `tag_user` and create a tagged transaction:
```sql
SET gtid_next = 'AUTOMATIC:custom_tag';
CREATE DATABASE user_db;
USE user_db;
CREATE TABLE user_table (id INT PRIMARY KEY, data VARCHAR(100));
```

**Expected Behavior**:
- Transaction executes successfully with the specified tag.

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
   START REPLICA UNTIL GTID_SUBSET('UUID:data_ops:1-5', @@global.gtid_executed);
   ```

---

#### **5. Monitoring with PMM**

**a. Deploy PMM Server**:
```bash
anydbver deploy pmm:latest --namespace=$NAMESPACE
```

**b. Deploy PMM Client**:
- For Master:
  ```bash
  anydbver deploy pmm-client --server=node0,mysql=node0 --namespace=$NAMESPACE
  ```
- For Replica:
  ```bash
  anydbver deploy pmm-client --server=node0,mysql=node1 --namespace=$NAMESPACE
  ```

**c. Monitor GTIDs**:
- Enable replication metrics in PMM.
- Use dashboards to observe tagged transactions and replication status.

---

#### **6. Document Observations**

**a. Transaction Logs**:
- Analyze GTID logs from both master and replica:
  ```sql
  SELECT * FROM mysql.gtid_executed;
  ```

**b. Test Output Summary**:
- Record outcomes of replication, conflict resolution, and monitoring tests.

---

#### **Conclusion**

1. Tagged GTIDs simplify transaction categorization and monitoring.
2. Unique GTID tags enhance debugging, disaster recovery, and replication management.
3. Proper privilege configuration ensures secure and effective GTID tagging.

This lab thoroughly demonstrates the use of tagged GTIDs in MySQL 8.4 replication, emphasizing their practical benefits and management techniques.