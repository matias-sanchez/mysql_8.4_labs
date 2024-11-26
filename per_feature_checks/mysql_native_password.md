### **Comparing MySQL 8.0 and 8.4 Authentication Plugin Behavior**

---

#### **Purpose**
This lab demonstrates differences in authentication plugin behavior between **MySQL 8.0** and **MySQL 8.4**, leveraging the `anydbver` tool for controlled environment management. Key focus areas include:
1. **Default Plugin Behavior**: Comparing how `mysql_native_password` and `default_authentication_plugin` are managed.
2. **Behavior Validation**: Testing default and modified configurations.
3. **Practical Observations**: Including exact outputs from commands.

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
  anydbver deploy mysql:8.0 --namespace=$NAMESPACE
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

---

##### **a. `default_authentication_plugin` Variable**

To verify the presence and value of the `default_authentication_plugin` variable, run the following command in both MySQL versions:

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
- In MySQL 8.4, the `default_authentication_plugin` variable has been removed, reflecting changes in authentication plugin management.

---

**Attempt to Enable `default_authentication_plugin` in MySQL 8.4**

If you attempt to reintroduce `default_authentication_plugin` in MySQL 8.4 it raises an error.

 **Steps to Reproduce the Error**

1. Modify the configuration file (`my.cnf`) to include the variable:
   ```ini
   anydbver exec node0 --namespace=mysql_8_4_test -- bash -c "echo 'default_authentication_plugin=caching_sha2_password' >> /etc/my.cnf"
   ```

2. Restart the MySQL server:
   ```bash
   anydbver exec node0 --namespace=mysql_8_4_test -- systemctl restart mysqld
   ```

3. Inspect the error log:
   ```bash
   anydbver exec node0 --namespace=mysql_8_4_test -- tail -n 10 /var/log/mysqld.log
   ```

**Error Observed in MySQL 8.4**:
```plaintext
2024-11-22T12:18:34.866485Z 0 [ERROR] [MY-000067] [Server] unknown variable 'default_authentication_plugin=caching_sha2_password'.
2024-11-22T12:18:34.867367Z 0 [ERROR] [MY-010119] [Server] Aborting
```

**Notes**
- MySQL 8.4 no longer supports the `default_authentication_plugin` variable.
- Any attempt to set this variable results in an "unknown variable" error, as shown in the logs. This confirms that the behavior of default authentication management has fundamentally changed in MySQL 8.4.

---

##### **b. `mysql_native_password` Plugin Status**

Check the status of the `mysql_native_password` plugin in both MySQL versions. Note that in MySQL 8.4, the tool `anydbver` modifies the default configuration by enabling `mysql_native_password`. This is not the default behavior for MySQL 8.4 and must be accounted for in testing.

Run the following command in both MySQL 8.0 and 8.4:

```sql
SHOW PLUGINS;
```

**Output in MySQL 8.0**:
```plaintext
| mysql_native_password | ACTIVE   | AUTHENTICATION | NULL | GPL |
```

**Output in MySQL 8.4** (with `anydbver` modification):
```plaintext
| mysql_native_password | ACTIVE   | AUTHENTICATION | NULL | GPL |
```

**Explanation**:
- In MySQL 8.0, `mysql_native_password` is active by default.
- In MySQL 8.4, **the default behavior disables `mysql_native_password`**. However, when using `anydbver`, the tool includes a configuration in `my.cnf` that enables this plugin by default. This must be manually reverted to test MySQL 8.4's actual default state.

Validate the `anydbver`-added configuration:

```bash
anydbver exec node0 --namespace=mysql_8_4_test -- grep -i mysql_native_password /etc/my.cnf -B 1
```

**Output**:
```plaintext
# mysql native auth is disabled by default in 8.4
loose-mysql_native_password=ON
``` 

**Notet**:
The presence of `loose-mysql_native_password=ON` in `my.cnf` enables the plugin when using `anydbver`, but this is not representative of MySQL 8.4's default behavior. For accurate testing, this configuration must be commented out or removed.

---

### **Behavior Testing**

#### **1. Reset MySQL 8.4 to Default State**

Reset MySQL 8.4 to its default configuration by disabling `mysql_native_password`:

1. **Comment out the configuration in `my.cnf`**:
   ```bash
   anydbver exec node0 --namespace=mysql_8_4_test -- bash -c "sed -i 's/^loose-mysql_native_password=ON/#loose-mysql_native_password=ON/' /etc/my.cnf"
   ```

2. **Restart the server**:
   ```bash
   anydbver exec node0 --namespace=mysql_8_4_test -- systemctl restart mysqld
   ```

3. **Verify plugin state**:
   ```sql
   anydbver exec node0 --namespace=mysql_8_4_test -- mysql -e"SHOW PLUGINS;" | grep -i mysql_native_password
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
   anydbver exec node0 --namespace=mysql_8_4_test -- mysql -e"SHOW PLUGINS;" | grep -i mysql_native_password
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
  ```

---

#### **2. Test Login Behavior**

- **MySQL 8.0**:
  ```bash
  anydbver exec node0 --namespace=mysql_8_0_test -- mysql -u test_user_8_0 -p'password' -h 127.0.0.1
  ```
  **Output**:
  ```plaintext
  Welcome to the MySQL monitor.  Commands end with ; or \g.
  Your MySQL connection id is 16
  Server version: 8.0.39 MySQL Community Server - GPL
  mysql>
  ```

- **MySQL 8.4** (default state):
  ```bash
  anydbver exec node0 --namespace=mysql_8_4_test -- mysql -u test_user_8_4 -p'password' -h 127.0.0.1
  ```
  **Output**:
  ```plaintext
  ERROR 1045 (28000): Access denied for user 'test_user_8_4'@'%' (using password: YES)
  ```

- **MySQL 8.4** (plugin enabled):
  ```bash
  anydbver exec node0 --namespace=mysql_8_4_test -- mysql -u test_user_8_4 -p'password' -h 127.0.0.1
  ```
  **Output**:
  ```plaintext
  Welcome to the MySQL monitor.  Commands end with ; or \g.
  Your MySQL connection id is 10
  Server version: 8.4.3 MySQL Community Server - GPL
  mysql>
  ```

**Additional Note**: If the `mysql_native_password` plugin is disabled after creating the user, attempting to log in results in the following error:

```bash
anydbver exec node0 --namespace=mysql_8_4_test -- mysql -u test_user_8_4 -p'password' -h 127.0.0.1
```
**Output**:
```plaintext
mysql: [Warning] Using a password on the command line interface can be insecure.
ERROR 1524 (HY000): Plugin 'mysql_native_password' is not loaded
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
```

---

### **Summary of Observations**

| **Feature**                     | **MySQL 8.0**                         | **MySQL 8.4 (Default)**                | **MySQL 8.4 (Plugin Enabled)**         |
|---------------------------------|----------------------------------------|----------------------------------------|----------------------------------------|
| `default_authentication_plugin` | Exists, `caching_sha2_password`        | Not available                          | Not available                          |
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





Action required
We need additional information to approve this account. Provide the information in Verification Center.
*Once you submit the information, allow up to 3 business days for review.
Account type
Personal
Bank country
United States of America
Bank name
Thread Bank
Account holder name
Romeo November Software Solutions LLC
Account number
200000993139
Routing
064209588