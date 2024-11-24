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
    - **Reason**: This feature can cause contention under high-concurrency workloads, such as multiple joins or `LIKE` queries with wildcards. Disabling it reduces unnecessary performance overhead.
    - **Recommendation**: Benchmark the workload to determine if enabling the Adaptive Hash Index (AHI) provides a measurable benefit. Monitor contention using the `SHOW ENGINE INNODB STATUS` output.

---

### **B. `innodb_buffer_pool_instances`**

---

#### **Default Behavior Changes**

The `innodb_buffer_pool_instances` parameter in MySQL has undergone adjustments between MySQL 8.0 and MySQL 8.4 to dynamically scale based on memory size and CPU resources. The following table summarizes the exact behavior in both versions:

| **Buffer Pool Size**          | **MySQL 8.0 Default**                                                              | **MySQL 8.4 Behavior**                                                                                       |
|--------------------------------|------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------|
| ≤ 1 GiB                       | 1 Instance                                                                         | 1 Instance                                                                                                 |
| > 1 GiB                       | 8 Instances                                                                        | Dynamically calculated based on:                                                                           |
|                                |                                                                                    | - **Buffer Pool Hint**: `(innodb_buffer_pool_size / innodb_buffer_pool_chunk_size) / 2`                    |
|                                |                                                                                    | - **CPU Hint**: `Available Logical Processors / 4`                                                        |
|                                |                                                                                    | - Final value is the **minimum of the two hints**, constrained to [1, 64].                                 |

---

#### **2. Test Dynamic Behavior with `anydbver`**

This section explores the behavior of `innodb_buffer_pool_instances` under various configurations using the `anydbver` tool, with a clear comparison between MySQL 8.0 and MySQL 8.4.

---

### **Table of Scenarios**

| **Buffer Pool Size** | **CPU Count**         | **Expected Behavior**                                      |
|-----------------------|-----------------------|-----------------------------------------------------------|
| ≤ 1 GiB              | 1, 2, 4, 8, 16, 32+  | Always 1 instance (same in MySQL 8.0 and 8.4).            |
| 2 GiB                | 1, 2, 4              | Controlled by CPU Hint (1, 2, or 4 instances).            |
| 4 GiB                | 1, 2, 4              | Controlled by CPU Hint (1, 2, or 4 instances).            |
| 4 GiB                | 8, 16                | Controlled by Buffer Pool Hint (final: 4).                |
| 16 GiB               | 1, 2, 4              | Controlled by CPU Hint (1, 2, or 4 instances).            |
| 16 GiB               | 8, 16                | Controlled by Buffer Pool Hint (final: 8).                |
| 16 GiB               | 32, 64               | Controlled by Buffer Pool Hint (final: 8).                |
| 64 GiB               | 1, 2, 4              | Controlled by CPU Hint (1, 2, or 4 instances).            |
| 64 GiB               | 8, 16                | Controlled by Buffer Pool Hint (final: 16).               |
| 64 GiB               | 32, 64               | Controlled by Buffer Pool Hint (final: 16).               |
| 128 GiB              | 8, 16                | Controlled by Buffer Pool Hint (final: 32).               |
| 128 GiB              | 32, 64               | Controlled by Buffer Pool Hint (final: 32).               |
| 256 GiB              | 32, 64               | Controlled by Buffer Pool Hint (final: 64).               |

---

###### **Scenario A: `innodb_buffer_pool_size` = 512 MiB**

1. **Remove Existing Configuration**:
   ```bash
   anydbver exec node0 --namespace=mysql_8_0_innodb_test -- bash -c "sed -i '/innodb_buffer_pool_size/d' /etc/my.cnf"
   anydbver exec node0 --namespace=mysql_8_4_innodb_test -- bash -c "sed -i '/innodb_buffer_pool_size/d' /etc/my.cnf"
   ```

2. **Set Buffer Pool Size**:
   ```bash
   anydbver exec node0 --namespace=mysql_8_0_innodb_test -- bash -c "echo 'innodb_buffer_pool_size=536870912' >> /etc/my.cnf"
   anydbver exec node0 --namespace=mysql_8_4_innodb_test -- bash -c "echo 'innodb_buffer_pool_size=536870912' >> /etc/my.cnf"
   ```

3. **Restart MySQL**:
   ```bash
   anydbver exec node0 --namespace=mysql_8_0_innodb_test -- systemctl restart mysqld
   anydbver exec node0 --namespace=mysql_8_4_innodb_test -- systemctl restart mysqld
   ```

4. **Verify Changes**:
   ```sql
   anydbver exec node0 --namespace=mysql_8_0_innodb_test -- mysql -e"SHOW VARIABLES LIKE 'innodb_buffer_pool_size';"
   anydbver exec node0 --namespace=mysql_8_0_innodb_test -- mysql -e"SHOW VARIABLES LIKE 'innodb_buffer_pool_instances';"
   anydbver exec node0 --namespace=mysql_8_4_innodb_test -- mysql -e"SHOW VARIABLES LIKE 'innodb_buffer_pool_size';"
   anydbver exec node0 --namespace=mysql_8_4_innodb_test -- mysql -e"SHOW VARIABLES LIKE 'innodb_buffer_pool_instances';"
   ```

5. **Math Calculations**:
   - **MySQL 8.0**:
     - Default is 1 instance because `innodb_buffer_pool_size` ≤ 1 GiB.
   - **MySQL 8.4**:
     - Default is also 1 instance because `innodb_buffer_pool_size` ≤ 1 GiB.

6. **Output**:
   **MySQL 8.0**:
   ```plaintext
   +-------------------------+-----------+
   | Variable_name           | Value     |
   +-------------------------+-----------+
   | innodb_buffer_pool_size | 536870912 |
   +-------------------------+-----------+
   
   +-----------------------------+-------+
   | Variable_name               | Value |
   +-----------------------------+-------+
   | innodb_buffer_pool_instances| 1     |
   +-----------------------------+-------+
   ```

   **MySQL 8.4**:
   ```plaintext
   +-------------------------+-----------+
   | Variable_name           | Value     |
   +-------------------------+-----------+
   | innodb_buffer_pool_size | 536870912 |
   +-------------------------+-----------+
   
   +-----------------------------+-------+
   | Variable_name               | Value |
   +-----------------------------+-------+
   | innodb_buffer_pool_instances| 1     |
   +-----------------------------+-------+
   ```

---

### **Scenario B: `innodb_buffer_pool_size` = 2 GiB**

---

#### **Steps**

1. **Remove Existing Configuration**:
   Ensure any previous `innodb_buffer_pool_size` configurations are removed:
   ```bash
   anydbver exec node0 --namespace=mysql_8_0_innodb_test -- bash -c "sed -i '/innodb_buffer_pool_size/d' /etc/my.cnf"
   anydbver exec node0 --namespace=mysql_8_4_innodb_test -- bash -c "sed -i '/innodb_buffer_pool_size/d' /etc/my.cnf"
   ```

2. **Set Buffer Pool Size**:
   Add the buffer pool size configuration for both MySQL versions:
   ```bash
   anydbver exec node0 --namespace=mysql_8_0_innodb_test -- bash -c "echo 'innodb_buffer_pool_size=2147483648' >> /etc/my.cnf"
   anydbver exec node0 --namespace=mysql_8_4_innodb_test -- bash -c "echo 'innodb_buffer_pool_size=2147483648' >> /etc/my.cnf"
   ```

3. **Control CPU Count**:
   Simulate different CPU counts (1, 2, 4) by limiting the available CPUs to the container:

   - **For 1 CPU**:
     ```bash
     docker update --cpuset-cpus=0 mysql_8_0_innodb_test-matias-sanchez-node0
     docker update --cpuset-cpus=0 mysql_8_4_innodb_test-matias-sanchez-node0
     ```

   - **For 2 CPUs**:
     ```bash
     docker update --cpuset-cpus=0-1 mysql_8_0_innodb_test-matias-sanchez-node0
     docker update --cpuset-cpus=0-1 mysql_8_4_innodb_test-matias-sanchez-node0
     ```

   - **For 4 CPUs**:
     ```bash
     docker update --cpuset-cpus=0-3 mysql_8_0_innodb_test-matias-sanchez-node0
     docker update --cpuset-cpus=0-3 mysql_8_4_innodb_test-matias-sanchez-node0
     ```

4. **Restart MySQL**:
   Restart the MySQL server after applying changes:
   ```bash
   anydbver exec node0 --namespace=mysql_8_0_innodb_test -- systemctl restart mysqld
   anydbver exec node0 --namespace=mysql_8_4_innodb_test -- systemctl restart mysqld
   ```

5. **Verify Changes**:
   Run the following commands to validate the `innodb_buffer_pool_size` and `innodb_buffer_pool_instances` values for each configuration:
   ```bash
   anydbver exec node0 --namespace=mysql_8_0_innodb_test -- mysql -e"SHOW VARIABLES LIKE 'innodb_buffer_pool_size';"
   anydbver exec node0 --namespace=mysql_8_0_innodb_test -- mysql -e"SHOW VARIABLES LIKE 'innodb_buffer_pool_instances';"
   anydbver exec node0 --namespace=mysql_8_4_innodb_test -- mysql -e"SHOW VARIABLES LIKE 'innodb_buffer_pool_size';"
   anydbver exec node0 --namespace=mysql_8_4_innodb_test -- mysql -e"SHOW VARIABLES LIKE 'innodb_buffer_pool_instances';"
   ```

6. **Rollback CPU Count**:
   After testing, reset the container to its full CPU allocation (48 CPUs):
   ```bash
   docker update --cpuset-cpus=0-47 mysql_8_0_innodb_test-matias-sanchez-node0
   docker update --cpuset-cpus=0-47 mysql_8_4_innodb_test-matias-sanchez-node0
   ```

---

#### **Math Calculations**

- **Buffer Pool Size**: `innodb_buffer_pool_size = 2 GiB`
- **Buffer Pool Chunk Size**: Default = 128 MiB

##### **CPU Hint**:
\[ \text{CPU Hint} = \frac{\text{Logical CPUs}}{4} \]

##### **Buffer Pool Hint**:
\[ \text{Buffer Pool Hint} = \left(\frac{\text{innodb_buffer_pool_size}}{\text{innodb_buffer_pool_chunk_size}}\right) / 2 \]

---

#### **Results**

| **CPU Count** | **MySQL 8.0 Behavior**                           | **MySQL 8.4 Behavior**                                                      |
|---------------|--------------------------------------------------|-----------------------------------------------------------------------------|
| **1 CPU**     | 8 instances (default for MySQL 8.0, CPU Hint ignored) | 1 instance (**min(Buffer Pool Hint, CPU Hint) → min(8, 1)**)                |
| **2 CPUs**    | 8 instances (default for MySQL 8.0, CPU Hint ignored) | 2 instances (**min(Buffer Pool Hint, CPU Hint) → min(8, 2)**)               |
| **4 CPUs**    | 8 instances (default for MySQL 8.0, CPU Hint ignored) | 4 instances (**min(Buffer Pool Hint, CPU Hint) → min(8, 4)**)               |

---

#### **Output**

**MySQL 8.0**:
```plaintext
+-------------------------+-----------+
| Variable_name           | Value     |
+-------------------------+-----------+
| innodb_buffer_pool_size | 2147483648 |
+-------------------------+-----------+

+-----------------------------+-------+
| Variable_name               | Value |
+-----------------------------+-------+
| innodb_buffer_pool_instances| 8     |
+-----------------------------+-------+
```

**MySQL 8.4 (1 CPU)**:
```plaintext
+-------------------------+-----------+
| Variable_name           | Value     |
+-------------------------+-----------+
| innodb_buffer_pool_size | 2147483648 |
+-------------------------+-----------+

+-----------------------------+-------+
| Variable_name               | Value |
+-----------------------------+-------+
| innodb_buffer_pool_instances| 1     |
+-----------------------------+-------+
```

**MySQL 8.4 (2 CPUs)**:
```plaintext
+-------------------------+-----------+
| Variable_name           | Value     |
+-------------------------+-----------+
| innodb_buffer_pool_size | 2147483648 |
+-------------------------+-----------+

+-----------------------------+-------+
| Variable_name               | Value |
+-----------------------------+-------+
| innodb_buffer_pool_instances| 2     |
+-----------------------------+-------+
```

**MySQL 8.4 (4 CPUs)**:
```plaintext
+-------------------------+-----------+
| Variable_name           | Value     |
+-------------------------+-----------+
| innodb_buffer_pool_size | 2147483648 |
+-------------------------+-----------+

+-----------------------------+-------+
| Variable_name               | Value |
+-----------------------------+-------+
| innodb_buffer_pool_instances| 4     |
+-----------------------------+-------+
```

This scenario confirms that `innodb_buffer_pool_instances` in MySQL 8.4 is dynamically controlled by the **CPU Hint**, whereas MySQL 8.0 defaults to 8 instances for buffer pool sizes > 1 GiB, irrespective of the CPU count.

---


#### **Summary of Observations**

| **Buffer Pool Size**          | **MySQL 8.0 Default** | **MySQL 8.4 Behavior**         |
|--------------------------------|-----------------------|---------------------------------|
| 512 MiB                       | 1 Instance           | 1 Instance                    |
| 4 GiB                         | 8 Instances          | 4 Instances                   |
| 16 GiB                        | 8 Instances          | 8 Instances                   |
| 64 GiB                        | 8 Instances          | 16 Instances                  |

---

#### **Conclusion**

1. **Dynamic Scaling in MySQL 8.4**:
   - Improves memory utilization by adapting buffer pool instances based on workload size and CPU availability.
   - Reduces overhead for small workloads while maintaining scalability for larger environments.

2. **Comparison with MySQL 8.0**:
   - MySQL 8.0 defaults to static behavior (8 instances for >1 GiB), potentially leading to inefficiency.

3. **Recommendations**:
   - Use MySQL 8.4 defaults for most workloads, as they are optimized for modern systems.
   - Adjust manually only when specific workloads require customization.

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