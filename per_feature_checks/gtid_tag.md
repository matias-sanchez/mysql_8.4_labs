### **Lab for Testing and Exploring Tagged GTIDs in MySQL 8.4**

---

#### **Purpose**

This lab demonstrates the **tagged GTID** feature introduced in MySQL 8.4. Tagged GTIDs enhance replication and transaction grouping by assigning specific tags to groups of transactions. This allows for better organization and monitoring of data and administrative transactions. The lab will cover:

1. **Environment Setup**: Deploy MySQL instances for testing tagged GTIDs using `anydbver`.
2. **Testing GTID Formats**: Compare traditional GTIDs with tagged GTIDs.
3. **Session-Level Tagged GTIDs**: Demonstrate how session-level GTID tags persist and behave.
4. **Replication with Tagged GTIDs**: Test replication and failover using tagged GTIDs.
5. **Monitoring and Validation**: Use queries and tools to monitor tagged GTID behavior.

---

### **Simulation Steps**

---

#### **1. Environment Setup**

- **Deploy MySQL Instances**:
  - Use `anydbver` to deploy **two MySQL 8.4 nodes** and configure them for replication.
  - Optionally deploy a **MySQL 8.0 node** for comparison with traditional GTIDs.

**Commands**:

1. **Deploy MySQL 8.4 Primary Node**:
   ```bash
   NAMESPACE=mysql_8_4_primary
   anydbver deploy mysql:8.4 --namespace=$NAMESPACE
   ```

2. **Deploy MySQL 8.4 Replica Node**:
   ```bash
   NAMESPACE=mysql_8_4_replica
   anydbver deploy mysql:8.4 --namespace=$NAMESPACE
   ```

3. **Deploy MySQL 8.0 Node (optional)**:
   ```bash
   NAMESPACE=mysql_8_0
   anydbver deploy mysql:8.0 --namespace=$NAMESPACE
   ```

4. **Access Instances**:
   - Primary Node:
     ```bash
     anydbver exec node0 --namespace=mysql_8_4_primary mysql
     ```
   - Replica Node:
     ```bash
     anydbver exec node0 --namespace=mysql_8_4_replica mysql
     ```
   - MySQL 8.0 Node:
     ```bash
     anydbver exec node0 --namespace=mysql_8_0 mysql
     ```

---

#### **2. Configure GTID-Based Replication**

1. **Set Up Primary Server**:
   Configure the primary MySQL 8.4 server for GTID-based replication.

   ```sql
   SET GLOBAL gtid_mode = ON;
   SET GLOBAL enforce_gtid_consistency = ON;

   -- Enable binary logging
   SET GLOBAL log_bin = 'mysql-bin';

   -- Create replication user
   CREATE USER 'replica_user'@'%' IDENTIFIED BY 'replica_pass';
   GRANT REPLICATION SLAVE ON *.* TO 'replica_user'@'%';
   FLUSH PRIVILEGES;
   ```

2. **Set Up Replica Server**:
   Configure the replica MySQL 8.4 server to replicate from the primary.

   ```sql
   SET GLOBAL gtid_mode = ON;
   SET GLOBAL enforce_gtid_consistency = ON;

   -- Enable binary logging
   SET GLOBAL log_bin = 'mysql-bin';

   -- Start replication
   CHANGE REPLICATION SOURCE TO
       SOURCE_HOST = '<primary_host>',
       SOURCE_USER = 'replica_user',
       SOURCE_PASSWORD = 'replica_pass',
       SOURCE_AUTO_POSITION = 1;
   START REPLICA;
   ```

3. **Optional: Set Up MySQL 8.0 Node**:
   Configure the MySQL 8.0 node with traditional GTIDs.

---

#### **3. Test GTID Formats**

- **Check Traditional GTID Format (UUID:NUMBER)**:
  On the MySQL 8.0 node or untagged transactions in MySQL 8.4, execute:

  ```sql
  INSERT INTO test_table (data) VALUES ('traditional_gtid');
  SHOW BINLOG EVENTS IN 'mysql-bin.000001';
  ```

- **Check Tagged GTID Format (UUID:TAG:NUMBER)**:
  On MySQL 8.4, execute:

  ```sql
  SET gtid_next = AUTOMATIC:'DATA';
  INSERT INTO test_table (data) VALUES ('tagged_gtid');
  SHOW BINLOG EVENTS IN 'mysql-bin.000001';
  ```

**Expected Output**:
- Traditional GTID: `UUID:NUMBER`
- Tagged GTID: `UUID:TAG:NUMBER`

---

#### **4. Test Session-Level Tagged GTIDs**

1. **Persist Tags in a Session**:
   ```sql
   SET gtid_next = AUTOMATIC:'SESSION_TAG';
   INSERT INTO test_table (data) VALUES ('session_tagged_gtid_1');
   INSERT INTO test_table (data) VALUES ('session_tagged_gtid_2');
   ```

2. **Switch Tags Within a Session**:
   ```sql
   SET gtid_next = AUTOMATIC:'SWITCHED_TAG';
   INSERT INTO test_table (data) VALUES ('switched_tagged_gtid');
   ```

3. **Monitor GTID Tags**:
   Query the binary log to see the applied tags:

   ```sql
   SHOW BINLOG EVENTS IN 'mysql-bin.000001';
   ```

---

#### **5. Replication with Tagged GTIDs**

1. **Check Replication Behavior**:
   - On the replica, query the relay log to confirm that tagged GTIDs are replicated.
     ```sql
     SHOW RELAYLOG EVENTS IN 'mysql-relay-bin.000001';
     ```

2. **Apply Different Tags for Different Transactions**:
   - On the primary:
     ```sql
     SET gtid_next = AUTOMATIC:'ADMIN';
     DELETE FROM test_table WHERE id = 1;

     SET gtid_next = AUTOMATIC:'DATA';
     INSERT INTO test_table (data) VALUES ('new_data');
     ```

   - On the replica, validate replication:
     ```sql
     SELECT * FROM test_table;
     SHOW RELAYLOG EVENTS IN 'mysql-relay-bin.000001';
     ```

---

#### **6. Privilege Testing**

1. **Test TRANSACTION_GTID_TAG Privilege**:
   - Revoke the privilege from a user:
     ```sql
     REVOKE TRANSACTION_GTID_TAG ON *.* FROM 'test_user'@'%';
     ```

   - Attempt to set a tagged GTID:
     ```sql
     SET gtid_next = AUTOMATIC:'DATA';
     INSERT INTO test_table (data) VALUES ('unauthorized_tagged_gtid');
     ```

   **Expected Output**:
   ```plaintext
   ERROR 1227 (42000): Access denied; you need (at least one of) the TRANSACTION_GTID_TAG privilege(s) for this operation
   ```

---

#### **7. Monitoring and Validation**

1. **Query Performance Schema**:
   - Check GTID usage in Performance Schema:
     ```sql
     SELECT * FROM performance_schema.replication_applier_status_by_worker;
     SELECT * FROM performance_schema.replication_connection_status;
     ```

2. **Use PMM (Optional)**:
   - Deploy PMM to monitor tagged GTIDs in real-time:
     ```bash
     anydbver deploy node0 pmm:docker-image=perconalab/pmm-server:dev-latest,port=12443
     anydbver deploy node1 pmm-client:docker-image=perconalab/pmm-client:dev-latest,server=node0,mysql=node2
     ```

   - Access the PMM dashboard and check replication metrics.

---

### **Summary of Observations**

| **Feature**                 | **MySQL 8.0**          | **MySQL 8.4**                  |
|-----------------------------|-----------------------|-------------------------------|
| Traditional GTIDs           | Supported            | Supported                     |
| Tagged GTIDs                | Not Supported        | Supported                     |
| Session-Level Tags          | Not Applicable       | Persistent and Switchable     |
| Replication with Tags       | Not Applicable       | Tags Replicated to Relays     |
| Privilege for Tagged GTIDs  | Not Applicable       | TRANSACTION_GTID_TAG Required |

---

### **Conclusion**

1. **Tagged GTIDs**:
   - Enable better tracking of transactional groups (e.g., data vs. admin operations).
   - Persist across sessions unless explicitly changed.

2. **Replication**:
   - Tagged GTIDs are seamlessly replicated across nodes.

3. **Privileges**:
   - Ensure proper privileges (TRANSACTION_GTID_TAG) for users to manage tagged GTIDs.

4. **Monitoring**:
   - Use tools like PMM to monitor GTID performance and replication behavior. 

This lab provides a comprehensive demonstration of tagged GTIDs in MySQL 8.4, emphasizing replication and monitoring.