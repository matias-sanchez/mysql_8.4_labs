### **Comprehensive Lab Guide: Comparing MySQL 8.0 and 8.4 Authentication Plugin Behavior**

---

#### **Purpose**
This lab demonstrates differences in authentication plugin behavior between **MySQL 8.0.34** and **MySQL 8.4**, leveraging the `anydbver` tool for controlled environment management. Key focus areas include:
1. **Default Plugin Behavior**: Comparing how `mysql_native_password` and `default_authentication_plugin` are managed.
2. **Behavior Validation**: Testing default and modified configurations.
3. **Practical Observations**: Including exact outputs from commands.
4. **Insights for Percona Support Engineers**: Helping clients transition to modern authentication standards.

---

### **Simulation Steps**

1. **Environment Setup**:
   - Deploy MySQL 8.0 and 8.4 using `anydbver`.
   - Validate the `mysql_native_password` plugin and `default_authentication_plugin` states.

2. **Behavior Testing**:
   - Reset MySQL 8.4 to its default behavior by reverting changes introduced by `anydbver`.
   - Enable `mysql_native_password` manually for comparison.

3. **Authentication Tests**:
   - Test user creation and authentication with various plugin configurations.

4. **Monitoring and Verification**:
   - Validate logs, plugin configurations, and user authentication details.

5. **Documentation of Results**:
   - Include clear outputs for all commands.

---

### **Setup Instructions**

#### **1. Deploy MySQL 8.0 and 8.4**

Use `anydbver` to deploy MySQL instances in isolated namespaces:

- **Deploy MySQL 8.0**:
  ```bash
  NAMESPACE=mysql_8_0_test
  anydbver deploy mysql:8.0.34 --namespace=$NAMESPACE
  ```

- **Deploy MySQL 8.4**:
  ```bash
  NAMESPACE=mysql_8_4_test
  anydbver deploy mysql:8.4 --namespace=$NAMESPACE
  ```

- **Access MySQL Instances**:
  - MySQL 8.0:
    ```bash
    anydbver exec node0 --namespace=mysql_8_0_test mysql
    ```
  - MySQL 8.4:
    ```bash
    anydbver exec node0 --namespace=mysql_8_4_test mysql
    ```

---

#### **2. Validate Default Plugin States**

##### **a. `default_authentication_plugin` Variable**

Run the following command in both MySQL versions to check for `default_authentication_plugin`:

```sql
SHOW VARIABLES LIKE 'default_authentication_plugin';
```

**Output in MySQL 8.0**:
```plaintext
+-------------------------------+-----------------------+
| Variable_name                 | Value                 |
+-------------------------------+-----------------------+
| default_authentication_plugin | caching_sha2_password |
+-------------------------------+-----------------------+
```

**Output in MySQL 8.4**:
```plaintext
Empty set (0.00 sec)
```

**Explanation**:
- In MySQL 8.0, the `default_authentication_plugin` variable exists and defaults to `caching_sha2_password`.
- In MySQL 8.4, this variable has been removed.

##### **b. `mysql_native_password` Plugin Status**

Check the status of the `mysql_native_password` plugin:

```sql
SHOW PLUGINS;
```

**Output in MySQL 8.0**:
```plaintext
| mysql_native_password | ACTIVE   | AUTHENTICATION | NULL | GPL |
```

**Output in MySQL 8.4**:
```plaintext
| mysql_native_password | ACTIVE   | AUTHENTICATION | NULL | GPL |
```

##### **c. Validate `my.cnf` Configuration in MySQL 8.4**

Inspect the `my.cnf` file for `mysql_native_password` settings:

```bash
anydbver exec node0 --namespace=mysql_8_4_test -- grep -i mysql_native_password /etc/my.cnf -B 1
```

**Output**:
```plaintext
# mysql native auth is disabled by default in 8.4
loose-mysql_native_password=ON
```

---

### **Behavior Testing**

#### **1. Reset MySQL 8.4 to Default State**

Reset MySQL 8.4 to its default configuration by disabling `mysql_native_password`:

1. **Stop the MySQL server**:
   ```bash
   anydbver exec node0 --namespace=mysql_8_4_test -- mysqladmin shutdown
   ```

2. **Comment out the configuration in `my.cnf`**:
   ```bash
   anydbver exec node0 --namespace=mysql_8_4_test -- bash -c "sed -i 's/^loose-mysql_native_password=ON/#loose-mysql_native_password=ON/' /etc/my.cnf"
   ```

3. **Restart the server**:
   ```bash
   anydbver exec node0 --namespace=mysql_8_4_test -- systemctl restart mysqld
   ```

4. **Verify plugin state**:
   ```sql
   SHOW PLUGINS;
   ```

**Output**:
```plaintext
| mysql_native_password | DISABLED | AUTHENTICATION | NULL | GPL |
```

---

#### **2. Re-enable `mysql_native_password` Plugin in MySQL 8.4**

Manually re-enable `mysql_native_password`:

1. **Modify `my.cnf`**:
   ```bash
   anydbver exec node0 --namespace=mysql_8_4_test -- bash -c "sed -i 's/^#loose-mysql_native_password=ON/loose-mysql_native_password=ON/' /etc/my.cnf"
   ```

2. **Restart the server**:
   ```bash
   anydbver exec node0 --namespace=mysql_8_4_test -- systemctl restart mysqld
   ```

3. **Verify plugin state**:
   ```sql
   SHOW PLUGINS;
   ```

**Output**:
```plaintext
| mysql_native_password | ACTIVE   | AUTHENTICATION | NULL | GPL |
```

---

### **Authentication Testing**

#### **1. Create Users**

Create test users in both versions:

- **MySQL 8.0**:
  ```sql
  CREATE USER 'test_user_8_0'@'%' IDENTIFIED WITH 'mysql_native_password' BY 'password';
  GRANT ALL PRIVILEGES ON *.* TO 'test_user_8_0'@'%';
  FLUSH PRIVILEGES;
  ```

- **MySQL 8.4** (default state where plugin is disabled):
  ```sql
  CREATE USER 'test_user_8_4'@'%' IDENTIFIED WITH 'mysql_native_password' BY 'password';
  ```

**Output**:
```plaintext
ERROR 1524 (HY000): Plugin 'mysql_native_password' is not loaded
```

- **MySQL 8.4** (plugin enabled):
  ```sql
  CREATE USER 'test_user_8_4'@'%' IDENTIFIED WITH 'mysql_native_password' BY 'password';
  GRANT ALL PRIVILEGES ON *.* TO 'test_user_8_4'@'%';
  FLUSH PRIVILEGES;
  ```

---

#### **2. Test Login Behavior**

- **MySQL 8.0**:
  ```bash
  mysql -u test_user_8_0 -p'password' -h <server-ip>
  ```
  **Output**:
  ```plaintext
  Welcome to the MySQL monitor...
  mysql>
  ```

- **MySQL 8.4** (default state):
  ```bash
  mysql -u test_user_8_4 -p'password' -h <server-ip>
  ```
  **Output**:
  ```plaintext
  ERROR 1045 (28000): Access denied for user 'test_user_8_4'@'%' (using password: YES)
  ```

- **MySQL 8.4** (plugin enabled):
  ```bash
  mysql -u test_user_8_4 -p'password' -h <server-ip>
  ```
  **Output**:
  ```plaintext
  Welcome to the MySQL monitor...
  mysql>
  ```

---

### **Monitoring and Validation**

#### **1. Monitor Logs**

Inspect logs for authentication attempts and plugin behavior:

- **MySQL 8.0**:
  ```bash
  anydbver exec node0 --namespace=mysql_8_0_test -- tail -f /var/log/mysqld.log
  ```

- **MySQL 8.4**:
  ```bash
  anydbver exec node0 --namespace=mysql_8_4_test -- tail -f /var/log/mysqld.log
  ```

#### **2. Inspect User Plugins**

Run the following to check plugin assignments:

```sql
SELECT 
    User, 
    Host, 
    plugin 
FROM 
    mysql.user 
WHERE 
    User LIKE 'test_user%';
```

**Output**:
```plaintext
| User           | Host    | plugin                |
|----------------|---------|-----------------------|
| test_user_8_0  | %       | mysql_native_password |
| test_user_8_4  | %       | mysql_native_password |
```

---

### **Summary of Observations**

| **Feature**                     | **MySQL 8.0**                         | **MySQL 8.4 (Default)**                | **MySQL 8.4 (Plugin Enabled)**         |
|---------------------------------|----------------------------------------|----------------------------------------|----------------------------------------|
| `default_authentication_plugin` |

 Exists, `caching_sha2_password`        | Not available                          | Not available                          |
| `mysql_native_password` Status  | Active                                | Disabled                               | Active                                 |
| User Creation                   | Supported                             | Fails due to disabled plugin           | Supported                              |
| Authentication Behavior         | Login successful                     | Login fails                            | Login successful                       |

---

### **Conclusion**

1. **Default State Differences**:
   - MySQL 8.0 defaults to `mysql_native_password` as an active plugin and supports `default_authentication_plugin`.
   - MySQL 8.4 disables `mysql_native_password` and removes `default_authentication_plugin`.

2. **anydbver Impacts**:
   - By default, `anydbver` enables `mysql_native_password` in MySQL 8.4 for backward compatibility.
