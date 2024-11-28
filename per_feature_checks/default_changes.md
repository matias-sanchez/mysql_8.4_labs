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

#### **2. Test Behavior with `anydbver`**

This section explores the behavior of `innodb_buffer_pool_instances` under various configurations using the `anydbver` tool, with a clear comparison between MySQL 8.0 and MySQL 8.4.

---

### **Table of Scenarios**
| **Scenario** | **Buffer Pool Size** | **MySQL 8.0 Instances** | **MySQL 8.4 Instances** | **Explanation**                                                                 |
|--------------|-----------------------|--------------------------|--------------------------|---------------------------------------------------------------------------------|
| A            | 512 MiB              | 1                        | 1                        | Static for both versions as `innodb_buffer_pool_size ≤ 1 GiB`.                  |
| B            | 4 GiB                | 8                        | 12                       | Rounded to 4.5 GiB in MySQL 8.4 to align with chunk size * instances.           |
| C            | 2 GiB                | 8                        | 8                        | Memory alignment rules satisfied without rounding in MySQL 8.4.                |
| D            | 1.5 GiB              | 8                        | 6                        | Adjusted in MySQL 8.4 to match multiple of chunk size and dynamic instance calc.|

### **Highlights**

- **Scenario A**: Demonstrates the behavior when `innodb_buffer_pool_size` is less than 1 GiB. Both MySQL 8.0 and 8.4 default to 1 instance.
- **Scenario B**: Shows how MySQL 8.4 rounds the requested 4 GiB buffer pool size to align with memory configuration rules and chunk size alignment.
- **Scenario C**: Highlights when the requested 2 GiB buffer pool size is already a valid multiple of chunk size and instance calculations.
- **Scenario D**: Explains how MySQL 8.4 dynamically adjusts the buffer pool size and instances for a requested size of 1.5 GiB, using both Buffer Pool Hint and CPU Hint.

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

###### **Scenario B: `innodb_buffer_pool_size` = 4 GiB**

1. **Remove Existing Configuration**:
   ```bash
   anydbver exec node0 --namespace=mysql_8_0_innodb_test -- bash -c "sed -i '/innodb_buffer_pool_size/d' /etc/my.cnf"
   anydbver exec node0 --namespace=mysql_8_4_innodb_test -- bash -c "sed -i '/innodb_buffer_pool_size/d' /etc/my.cnf"
   ```

2. **Set Buffer Pool Size**:
   ```bash
   anydbver exec node0 --namespace=mysql_8_0_innodb_test -- bash -c "echo 'innodb_buffer_pool_size=4294967296' >> /etc/my.cnf"
   anydbver exec node0 --namespace=mysql_8_4_innodb_test -- bash -c "echo 'innodb_buffer_pool_size=4294967296' >> /etc/my.cnf"
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

### **Math Calculations**

#### **MySQL 8.0**
- **Static Behavior**: MySQL 8.0 always assigns **8 buffer pool instances** for any `innodb_buffer_pool_size > 1 GiB`, regardless of CPU count. 

---

#### **MySQL 8.4**
MySQL 8.4 dynamically calculates `innodb_buffer_pool_instances` based on:

```
innodb_buffer_pool_size = innodb_buffer_pool_chunk_size * innodb_buffer_pool_instances * n
```

Where:
- `innodb_buffer_pool_chunk_size` defaults to `128 MiB` (134217728 bytes).
- `n` is an integer.

The original value requested is:
```
innodb_buffer_pool_size = 4 GiB = 4294967296 bytes
```

However, since the buffer pool size must be a multiple of: `innodb_buffer_pool_chunk_size * innodb_buffer_pool_instances`

Substituting the default chunk size and calculated instances (12):
```
innodb_buffer_pool_size = 134217728 * 12
innodb_buffer_pool_size = 1610612736
```

Clearly, the requested `innodb_buffer_pool_size` of `4294967296` is not satisfied. Therefore, MySQL automatically rounds `innodb_buffer_pool_size` to the nearest valid multiple of:
```
innodb_buffer_pool_size = (innodb_buffer_pool_chunk_size * innodb_buffer_pool_instances) * n
```

After adjustment, the new `innodb_buffer_pool_size` becomes:
```
innodb_buffer_pool_size = (innodb_buffer_pool_chunk_size * innodb_buffer_pool_instances) * 3
innodb_buffer_pool_size = (134217728 * 12) = 4831838208
```

This is why MySQL automatically rounds `innodb_buffer_pool_size` up to **4831838208 bytes**.

- **Buffer Pool Hint Calculation:**
```
buffer pool hint = (innodb_buffer_pool_size / innodb_buffer_pool_chunk_size)/2
buffer pool hint = (4831838208 / 134217728)/2
buffer pool hint = 18
```

- **CPU Hint**:
```
CPU Hint = Available Logical Processors / 4
```
Substituting the available processors:
```
CPU Hint = 48 / 4 = 12 instances
```

- **Final Value**:
The final value of `innodb_buffer_pool_instances` is the **minimum** of the Buffer Pool Hint and the CPU Hint:
```
innodb_buffer_pool_instances = min(Buffer Pool Hint, CPU Hint)
innodb_buffer_pool_instances = min(18, 12) = 12 instances
```

6. **Output**:
   **MySQL 8.0**:
   ```plaintext
   +-------------------------+-----------+
   | Variable_name           | Value     |
   +-------------------------+-----------+
   | innodb_buffer_pool_size | 4294967296 |
   +-------------------------+-----------+
   
   +-----------------------------+-------+
   | Variable_name               | Value |
   +-----------------------------+-------+
   | innodb_buffer_pool_instances| 8     |
   +-----------------------------+-------+
   ```

   **MySQL 8.4**:
   ```plaintext
   +-------------------------+------------+
   | Variable_name           | Value      |
   +-------------------------+------------+
   | innodb_buffer_pool_size | 4831838208 |
   +-------------------------+------------+
   
   +-----------------------------+-------+
   | Variable_name               | Value |
   +-----------------------------+-------+
   | innodb_buffer_pool_instances| 12    |
   +-----------------------------+-------+
   ```

---

**Explanation of Adjustments**:

1. **Buffer Pool Size Rounding**:
   - MySQL 8.4 automatically adjusts `innodb_buffer_pool_size` to ensure it is a multiple of:
     ```
     innodb_buffer_pool_size = innodb_buffer_pool_chunk_size * innodb_buffer_pool_instances
     ```
   - With `innodb_buffer_pool_chunk_size = 134217728` (128 MiB) and `innodb_buffer_pool_instances = 12`, the value is:
     ```
     innodb_buffer_pool_size = 134217728 * 12 = 4831838208 bytes
     ```
   - This ensures proper alignment with chunk size and instance configuration.

2. **MySQL 8.0 Behavior**:
   - Always uses **8 buffer pool instances** when `innodb_buffer_pool_size > 1 GiB`. The CPU count is ignored, and the configuration is static.

3. **MySQL 8.4 Behavior**:
   - Dynamically adjusts `innodb_buffer_pool_instances` based on hardware resources and memory configuration:
     - **Buffer Pool Hint** ensures proper memory alignment with chunk size.
     - **CPU Hint** ensures optimal use of available processors.
     - The final value is the minimum of these two hints.

---

###### **Scenario C: `innodb_buffer_pool_size` = 2 GiB**

1. **Remove Existing Configuration**:
   ```bash
   anydbver exec node0 --namespace=mysql_8_0_innodb_test -- bash -c "sed -i '/innodb_buffer_pool_size/d' /etc/my.cnf"
   anydbver exec node0 --namespace=mysql_8_4_innodb_test -- bash -c "sed -i '/innodb_buffer_pool_size/d' /etc/my.cnf"
   ```

2. **Set Buffer Pool Size**:
   ```bash
   anydbver exec node0 --namespace=mysql_8_0_innodb_test -- bash -c "echo 'innodb_buffer_pool_size=2147483648' >> /etc/my.cnf"
   anydbver exec node0 --namespace=mysql_8_4_innodb_test -- bash -c "echo 'innodb_buffer_pool_size=2147483648' >> /etc/my.cnf"
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

---

### **Math Calculations**

#### **MySQL 8.0**
- **Static Behavior**: MySQL 8.0 always assigns **8 buffer pool instances** for any `innodb_buffer_pool_size > 1 GiB`, regardless of CPU count. 

---

#### **MySQL 8.4**
MySQL 8.4 dynamically calculates `innodb_buffer_pool_instances` based on:

   ```
   innodb_buffer_pool_size = innodb_buffer_pool_chunk_size * innodb_buffer_pool_instances * n
   ```
   Where:
     - `innodb_buffer_pool_chunk_size` defaults to `128 MiB` (134217728 bytes).
     - `n` is an integer.
   The original value requested is:
     ```
     innodb_buffer_pool_size = 2 GiB = 2147483648 bytes
     ```

   Since the buffer pool size must be a multiple of:
     ```
     innodb_buffer_pool_size = innodb_buffer_pool_chunk_size * innodb_buffer_pool_instances
     ```

   Substituting the default chunk size and calculated instances:
     ```
     innodb_buffer_pool_size = 134217728 * 8
     innodb_buffer_pool_size = 1073741824
     ```

   This satisfies the memory alignment rules. MySQL rounds the value to the nearest valid multiple, which is already **2147483648 bytes**.

   - **Buffer Pool Hint Calculation**:
   ```
   buffer_pool_hint = (innodb_buffer_pool_size / innodb_buffer_pool_chunk_size) / 2
   buffer_pool_hint = (2147483648 / 134217728) / 2
   buffer_pool_hint = 16 / 2
   buffer_pool_hint = 8 instances
   ```

---

2. **CPU Hint**:
   ```
   CPU Hint = Available Logical Processors / 4
   ```
   Substituting the available processors:
   ```
   CPU Hint = 48 / 4 = 12 instances
   ```

---

3. **Final Value**:
   The final value of `innodb_buffer_pool_instances` is the **minimum** of the Buffer Pool Hint and the CPU Hint:
   ```
   innodb_buffer_pool_instances = min(Buffer Pool Hint, CPU Hint)
   innodb_buffer_pool_instances = min(8, 12)
   innodb_buffer_pool_instances = 8 instances
   ```

---

### **Output**

#### **MySQL 8.0**:
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

#### **MySQL 8.4**:
```plaintext
+-------------------------+------------+
| Variable_name           | Value      |
+-------------------------+------------+
| innodb_buffer_pool_size | 2147483648 |
+-------------------------+------------+

+-----------------------------+-------+
| Variable_name               | Value |
+-----------------------------+-------+
| innodb_buffer_pool_instances| 8     |
+-----------------------------+-------+
```

---

### **Explanation of Adjustments**
1. **Buffer Pool Size Rounding**:
   - MySQL 8.4 automatically adjusts `innodb_buffer_pool_size` to ensure it is a multiple of:
     ```
     innodb_buffer_pool_size = innodb_buffer_pool_chunk_size * innodb_buffer_pool_instances
     ```
   - With `innodb_buffer_pool_chunk_size = 134217728` (128 MiB) and `innodb_buffer_pool_instances = 8`, the value is:
     ```
     innodb_buffer_pool_size = 134217728 * 8 = 2147483648 bytes
     ```

2. **MySQL 8.0 Behavior**:
   - Always uses **8 buffer pool instances** when `innodb_buffer_pool_size > 1 GiB`. The CPU count is ignored, and the configuration is static.

3. **MySQL 8.4 Behavior**:
   - Dynamically adjusts `innodb_buffer_pool_instances` based on hardware resources and memory configuration:
     - **Buffer Pool Hint** ensures proper memory alignment with chunk size.
     - **CPU Hint** ensures optimal use of available processors.
     - The final value is the minimum of these two hints. 

---

###### **Scenario D: `innodb_buffer_pool_size` = 1.5 GiB**

1. **Remove Existing Configuration**:
   ```bash
   anydbver exec node0 --namespace=mysql_8_0_innodb_test -- bash -c "sed -i '/innodb_buffer_pool_size/d' /etc/my.cnf"
   anydbver exec node0 --namespace=mysql_8_4_innodb_test -- bash -c "sed -i '/innodb_buffer_pool_size/d' /etc/my.cnf"
   ```

2. **Set Buffer Pool Size**:
   ```bash
   anydbver exec node0 --namespace=mysql_8_0_innodb_test -- bash -c "echo 'innodb_buffer_pool_size=1610612736' >> /etc/my.cnf"
   anydbver exec node0 --namespace=mysql_8_4_innodb_test -- bash -c "echo 'innodb_buffer_pool_size=1610612736' >> /etc/my.cnf"
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

---

### **Math Calculations**

#### **MySQL 8.0**
- **Static Behavior**: MySQL 8.0 always assigns **8 buffer pool instances** for any `innodb_buffer_pool_size > 1 GiB`, regardless of CPU count.

---

#### **MySQL 8.4**
MySQL 8.4 dynamically calculates `innodb_buffer_pool_instances` based on:

1. **Buffer Pool Hint**:
   ```
   innodb_buffer_pool_size = innodb_buffer_pool_chunk_size * innodb_buffer_pool_instances * n
   ```
   Where:
     - `innodb_buffer_pool_chunk_size` defaults to `128 MiB` (134217728 bytes).
     - `n` is an integer.
   The original value requested is:
     ```
     innodb_buffer_pool_size = 1.5 GiB = 1610612736 bytes
     ```

   Since the buffer pool size must be a multiple of:
     ```
     innodb_buffer_pool_size = innodb_buffer_pool_chunk_size * innodb_buffer_pool_instances
     ```

   Substituting the default chunk size and calculated instances:
     ```
     innodb_buffer_pool_size = 134217728 * 6
     innodb_buffer_pool_size = 1610612736
     ```

   This satisfies the memory alignment rules. MySQL does not round the value as the requested size already aligns with the rules.

   - **Buffer Pool Hint Calculation**:
   ```
   buffer_pool_hint = (innodb_buffer_pool_size / innodb_buffer_pool_chunk_size) / 2
   buffer_pool_hint = (1610612736 / 134217728) / 2
   buffer_pool_hint = 12 / 2
   buffer_pool_hint = 6 instances
   ```

---

2. **CPU Hint**:
   ```
   CPU Hint = Available Logical Processors / 4
   ```
   Substituting the available processors:
   ```
   CPU Hint = 48 / 4 = 12 instances
   ```

---

3. **Final Value**:
   The final value of `innodb_buffer_pool_instances` is the **minimum** of the Buffer Pool Hint and the CPU Hint:
   ```
   innodb_buffer_pool_instances = min(Buffer Pool Hint, CPU Hint)
   innodb_buffer_pool_instances = min(6, 12)
   innodb_buffer_pool_instances = 6 instances
   ```

---

### **Output**

#### **MySQL 8.0**:
```plaintext
+-------------------------+-----------+
| Variable_name           | Value     |
+-------------------------+-----------+
| innodb_buffer_pool_size | 1610612736 |
+-------------------------+-----------+

+-----------------------------+-------+
| Variable_name               | Value |
+-----------------------------+-------+
| innodb_buffer_pool_instances| 8     |
+-----------------------------+-------+
```

#### **MySQL 8.4**:
```plaintext
+-------------------------+------------+
| Variable_name           | Value      |
+-------------------------+------------+
| innodb_buffer_pool_size | 1610612736 |
+-------------------------+------------+

+-----------------------------+-------+
| Variable_name               | Value |
+-----------------------------+-------+
| innodb_buffer_pool_instances| 6     |
+-----------------------------+-------+
```

---

### **Explanation of Adjustments**
1. **Buffer Pool Size Rounding**:
   - The requested value of **1.5 GiB** (1610612736 bytes) is already a valid multiple of:
     ```
     innodb_buffer_pool_size = innodb_buffer_pool_chunk_size * innodb_buffer_pool_instances
     ```
   - With `innodb_buffer_pool_chunk_size = 134217728` (128 MiB) and `innodb_buffer_pool_instances = 6`, the buffer pool size remains:
     ```
     innodb_buffer_pool_size = 134217728 * 6 = 1610612736 bytes
     ```

2. **MySQL 8.0 Behavior**:
   - Always uses **8 buffer pool instances** when `innodb_buffer_pool_size > 1 GiB`. The CPU count is ignored, and the configuration is static.

3. **MySQL 8.4 Behavior**:
   - Dynamically adjusts `innodb_buffer_pool_instances` based on hardware resources and memory configuration:
     - **Buffer Pool Hint** ensures proper memory alignment with chunk size.
     - **CPU Hint** ensures optimal use of available processors.
     - The final value is the minimum of these two hints.

### **C. `innodb_page_cleaners`**

---

#### **Overview**

The `innodb_page_cleaners` parameter controls the number of threads used to flush dirty pages from the buffer pool to storage. In MySQL 8.4, this value dynamically matches `innodb_buffer_pool_instances`. Previously, in MySQL 8.0, it had a static default value of **4**.

This change ensures better alignment between buffer pool configuration and page flushing efficiency, especially under write-heavy workloads.

---

#### **Default Value Comparison**

- **MySQL 8.0**:
  ```sql
  SELECT @@innodb_page_cleaners;
  ```
  **Output**:
  ```plaintext
  +-----------------------+
  | @@innodb_page_cleaners |
  +-----------------------+
  | 4                     |
  +-----------------------+
  ```

- **MySQL 8.4**:
  ```sql
  SELECT @@innodb_page_cleaners, @@innodb_buffer_pool_instances;
  ```
  **Output**:
  ```plaintext
  +-----------------------+
  | @@innodb_page_cleaners |
  +-----------------------+
  | 6                     | -- Example: matches buffer pool instances
  +-----------------------+
  ```

  ```plaintext
  +------------------------------+
  | @@innodb_buffer_pool_instances |
  +------------------------------+
  | 6                            | -- Dynamically calculated
  +------------------------------+
  ```

---

#### **Key Insights**

1. **Dynamic Adjustment**:
   - In MySQL 8.4, `innodb_page_cleaners` matches `innodb_buffer_pool_instances` by default.
   - Increasing `innodb_buffer_pool_instances` automatically adjusts `innodb_page_cleaners`.

2. **Performance Benefits**:
   - Optimized write throughput for high-concurrency workloads.
   - Threads distribute flush tasks evenly across buffer pool instances.

3. **Static vs. Dynamic Behavior**:
   - MySQL 8.0: `innodb_page_cleaners` is fixed at **4**.
   - MySQL 8.4: Dynamically adjusts based on `innodb_buffer_pool_instances`.

---

#### **Quick Test**

1. **Modify Buffer Pool Instances** (MySQL 8.4):
   ```bash
   anydbver exec node0 --namespace=mysql_8_4_innodb_test -- bash -c "echo 'innodb_buffer_pool_instances=16' >> /etc/my.cnf"
   anydbver exec node0 --namespace=mysql_8_4_innodb_test -- systemctl restart mysqld
   ```

2. **Verify Changes**:
   ```sql
   SELECT @@innodb_buffer_pool_instances, @@innodb_page_cleaners;
   ```
   **Expected Output**:
   ```plaintext
   +------------------------------+-----------------------+
   | @@innodb_buffer_pool_instances | @@innodb_page_cleaners |
   +------------------------------+-----------------------+
   | 16                           | 16                    |
   +------------------------------+-----------------------+
   ```

---


##### **D. `innodb_log_buffer_size`**

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

