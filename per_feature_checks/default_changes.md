### **Exploring InnoDB System Variable Default Changes in MySQL 8.4**

---

#### **Purpose**
This lab demonstrates changes in default values for critical InnoDB system variables between **MySQL 8.0** and **MySQL 8.4**, using the `anydbver` tool. It includes:
1. Deploying MySQL 8.0 and 8.4 for comparison.
2. Observing specific InnoDB system variable changes.
3. Testing performance-related impacts where applicable.

---

### **Simulation Steps**

---

#### **1. Environment Setup**

- **Deploy MySQL 8.0 and 8.4 Instances**

```bash
# Deploy MySQL 8.0
NAMESPACE=mysql_8_0_innodb_test
anydbver deploy mysql:8.0 --namespace=$NAMESPACE
```

```bash
# Deploy MySQL 8.4
NAMESPACE=mysql_8_4_innodb_test
anydbver deploy mysql:8.4 --namespace=$NAMESPACE
```

- **Access the MySQL Instances**
  - MySQL 8.0:
    ```bash
    anydbver exec node0 --namespace=mysql_8_0_innodb_test mysql
    ```
  - MySQL 8.4:
    ```bash
    anydbver exec node0 --namespace=mysql_8_4_innodb_test mysql
    ```

---

#### **2. Validate InnoDB Default Changes**

##### **A. `innodb_adaptive_hash_index`**

- **Check Default Value in MySQL 8.0**:
  ```sql
  SELECT @@innodb_adaptive_hash_index;
  ```
  **Output**:
  ```plaintext
  +--------------------------+
  | @@innodb_adaptive_hash_index |
  +--------------------------+
  | 1                        |
  +--------------------------+
  ```

- **Check Default Value in MySQL 8.4**:
  ```sql
  SELECT @@innodb_adaptive_hash_index;
  ```
  **Output**:
  ```plaintext
  +--------------------------+
  | @@innodb_adaptive_hash_index |
  +--------------------------+
  | 0                        |
  +--------------------------+
  ```
- **Explanation**:

    - **Default Change**: In MySQL 8.4, `innodb_adaptive_hash_index` is OFF by default (previously ON in MySQL 8.0).
    - **Reason**: This feature can cause contention under high-concurrency workloads, such as multiple joins or `LIKE` queries with wildcards. Disabling it reduces unnecessary performance overhead for most modern systems.
    - **Recommendation**: Benchmark your workload to determine if enabling the Adaptive Hash Index (AHI) provides a measurable benefit. Monitor contention using the `SHOW ENGINE INNODB STATUS` output.

---

##### **B. `innodb_buffer_pool_instances`**

- **Check Default Behavior in MySQL 8.0**:
  ```sql
  SHOW VARIABLES LIKE 'innodb_buffer_pool_instances';
  ```
  **Output**:
  ```plaintext
  +-----------------------------+-------+
  | Variable_name               | Value |
  +-----------------------------+-------+
  | innodb_buffer_pool_instances| 8     |
  +-----------------------------+-------+
  ```

- **Check Default Behavior in MySQL 8.4**:
  ```sql
  SHOW VARIABLES LIKE 'innodb_buffer_pool_instances';
  ```
  **Output**:
  ```plaintext
  +-----------------------------+-------+
  | Variable_name               | Value |
  +-----------------------------+-------+
  | innodb_buffer_pool_instances| 1     |
  +-----------------------------+-------+
  ```

- **Explanation**:
  - MySQL 8.4 adapts `innodb_buffer_pool_instances` dynamically:
    - If `innodb_buffer_pool_size` ≤ 1 GiB, it defaults to 1.
    - Larger sizes calculate based on memory and CPU.

---

##### **C. `innodb_numa_interleave`**

- **Check Default Value in MySQL 8.0**:
  ```sql
  SELECT @@innodb_numa_interleave;
  ```
  **Output**:
  ```plaintext
  +-----------------------+
  | @@innodb_numa_interleave |
  +-----------------------+
  | 0                     |
  +-----------------------+
  ```

- **Check Default Value in MySQL 8.4**:
  ```sql
  SELECT @@innodb_numa_interleave;
  ```
  **Output**:
  ```plaintext
  +-----------------------+
  | @@innodb_numa_interleave |
  +-----------------------+
  | 1                     |
  +-----------------------+
  ```

- **Explanation**:
  - NUMA interleaving is ON by default in MySQL 8.4, improving memory access on NUMA systems.

---

##### **D. `innodb_io_capacity`**

- **Check Default Value in MySQL 8.0**:
  ```sql
  SELECT @@innodb_io_capacity;
  ```
  **Output**:
  ```plaintext
  +------------------+
  | @@innodb_io_capacity |
  +------------------+
  | 200              |
  +------------------+
  ```

- **Check Default Value in MySQL 8.4**:
  ```sql
  SELECT @@innodb_io_capacity;
  ```
  **Output**:
  ```plaintext
  +------------------+
  | @@innodb_io_capacity |
  +------------------+
  | 10000            |
  +------------------+
  ```

- **Explanation**:
  - Increased IO capacity in MySQL 8.4 supports better disk utilization for modern storage.

---

##### **E. `innodb_log_buffer_size`**

- **Check Default Value in MySQL 8.0**:
  ```sql
  SELECT @@innodb_log_buffer_size;
  ```
  **Output**:
  ```plaintext
  +------------------------+
  | @@innodb_log_buffer_size |
  +------------------------+
  | 16777216 (16 MiB)      |
  +------------------------+
  ```

- **Check Default Value in MySQL 8.4**:
  ```sql
  SELECT @@innodb_log_buffer_size;
  ```
  **Output**:
  ```plaintext
  +------------------------+
  | @@innodb_log_buffer_size |
  +------------------------+
  | 67108864 (64 MiB)      |
  +------------------------+
  ```

- **Explanation**:
  - Larger log buffer size in MySQL 8.4 minimizes IO overhead for high-write workloads.

---

#### **3. Performance Testing (Optional)**

- **Test Impact of `innodb_adaptive_hash_index` on Queries**

1. **Create a Sample Table**:
   ```sql
   CREATE TABLE test_performance (
       id INT AUTO_INCREMENT PRIMARY KEY,
       data VARCHAR(255) NOT NULL
   );
   ```

2. **Insert Data**:
   ```sql
   INSERT INTO test_performance (data) SELECT REPEAT('a', 255) FROM dual CONNECT BY LEVEL <= 100000;
   ```

3. **Run Query with Index Use**:
   ```sql
   SELECT * FROM test_performance WHERE data = 'a';
   ```

4. **Compare Execution Time in MySQL 8.0 (ON) vs. MySQL 8.4 (OFF)**:
   - Note execution times and observe performance differences.

---

#### **4. Monitoring and Validation**

- **Check Logs for Changes in Defaults**
  - **MySQL 8.0**:
    ```bash
    anydbver exec node0 --namespace=mysql_8_0_innodb_test -- tail -f /var/log/mysqld.log
    ```
  - **MySQL 8.4**:
    ```bash
    anydbver exec node0 --namespace=mysql_8_4_innodb_test -- tail -f /var/log/mysqld.log
    ```

- **Validate Variable Changes with Queries**:
  ```sql
  SELECT @@innodb_adaptive_hash_index, @@innodb_buffer_pool_instances, @@innodb_numa_interleave;
  ```

---

#### **5. Summary of Observations**

| **Variable**               | **MySQL 8.0 Default**       | **MySQL 8.4 Default**       | **Impact**                                      |
|----------------------------|----------------------------|-----------------------------|------------------------------------------------|
| `innodb_adaptive_hash_index` | ON                        | OFF                         | Reduces contention for index-heavy workloads   |
| `innodb_buffer_pool_instances` | Static: 8                | Adaptive: 1 (if ≤1 GiB)     | Improves memory and CPU utilization            |
| `innodb_numa_interleave`    | OFF                       | ON                          | Enhanced memory access for NUMA architectures |
| `innodb_io_capacity`        | 200                       | 10000                       | Supports faster IO on modern disks            |
| `innodb_log_buffer_size`    | 16 MiB                    | 64 MiB                      | Reduces write IO overhead                     |

---

### **Conclusion**

1. Default value changes in MySQL 8.4 enhance scalability and performance for modern systems.
2. Support Engineers should leverage these defaults to optimize configurations based on workload and hardware.

This simulation provides practical insights into the changes and prepares teams for real-world troubleshooting.