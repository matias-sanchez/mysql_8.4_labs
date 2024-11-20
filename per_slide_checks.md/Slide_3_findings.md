## Findings

### MySQL Version Comparison

#### MySQL 8.0.39-30

```sql
mysql> SELECT @@version;
+-----------+
| @@version |
+-----------+
| 8.0.39-30 |
+-----------+
1 row in set (0.00 sec)

mysql> SHOW VARIABLES LIKE 'default_authentication_plugin';
+-------------------------------+-----------------------+
| Variable_name                 | Value                 |
+-------------------------------+-----------------------+
| default_authentication_plugin | caching_sha2_password |
+-------------------------------+
1 row in set (0.01 sec)
```

#### MySQL 8.4.2-2

```sql
mysql> SELECT @@version;
+-----------+
| @@version |
+-----------+
| 8.4.2-2   |
+-----------+
1 row in set (0.00 sec)

mysql> SHOW VARIABLES LIKE 'default_authentication_plugin';
Empty set (0.01 sec)
```

### Plugin Status

#### MySQL 8.0.39-30

```bash
$ 

docker exec -it mypercona80 \
mysql -u root \
-e "SHOW PLUGINS;" | grep mysql_native_password
| mysql_native_password            | ACTIVE   | AUTHENTICATION     | NULL    | GPL     |
```

#### MySQL 8.4.2-2

```bash
$ sudo docker exec -it mypercona84 mysql -u root -e "SHOW PLUGINS;" | grep mysql_native_password
| mysql_native_password            | DISABLED | AUTHENTICATION     | NULL    | GPL     |
```

### Error Encountered in MySQL 8.4.2-2

When attempting to add `default_authentication_plugin` in MySQL 8.4.2-2, the following error is raised:

```
2024-11-20T00:23:34.190854Z 0 [ERROR] [MY-000067] [Server] unknown variable 'default-authentication-plugin=mysql_native_password'.
2024-11-20T00:23:34.193544Z 0 [ERROR] [MY-010119] [Server] Aborting
```

After adding the following configuration:

```ini
mysql_native_password=ON
#default-authentication-plugin=mysql_native_password
```

The plugin status changed:

```bash
$ sudo docker exec -it mypercona84 mysql -u root -e "SHOW PLUGINS;" | grep mysql_native_password
| mysql_native_password            | ACTIVE   | AUTHENTICATION     | NULL    | GPL     |
```
### Summary of Findings

In this document, we compared the MySQL versions 8.0.39-30 and 8.4.2-2, focusing on their default authentication plugins and plugin statuses. We encountered an error when attempting to configure the `default_authentication_plugin` in MySQL 8.4.2-2, which was resolved by modifying the configuration file.

### Key Differences

- **MySQL Version**: The versions compared are 8.0.39-30 and 8.4.2-2.
- **Default Authentication Plugin**:
    - MySQL 8.0.39-30 uses `caching_sha2_password`.
    - MySQL 8.4.2-2 does not have a default authentication plugin set.
- **Plugin Status**:
    - In MySQL 8.0.39-30, `mysql_native_password` is active.
    - In MySQL 8.4.2-2, `mysql_native_password` is initially disabled but can be activated by modifying the configuration.

### Resolution Steps

To resolve the error encountered in MySQL 8.4.2-2, the following steps were taken:
1. Attempted to set `default_authentication_plugin` to `mysql_native_password`, which resulted in an error.
2. Modified the configuration file to enable `mysql_native_password` directly.
3. Verified that the plugin status changed to active.

These steps ensured that the `mysql_native_password` plugin was successfully activated in MySQL 8.4.2-2, aligning its behavior with MySQL 8.0.39-30.

### Conclusion

This comparison highlights the importance of understanding version-specific configurations and the steps required to align plugin behaviors across different MySQL versions. The resolution provided a clear path to enable `mysql_native_password` in MySQL 8.4.2-2, ensuring compatibility and consistency in authentication mechanisms.
Here’s an enhanced and more professional version of your markdown findings document:

---

## **Findings: Authentication Changes in MySQL 8.0 vs 8.4**

This document summarizes the findings from a lab-based comparison between **MySQL 8.0.39-30** and **MySQL 8.4.2-2**, focusing on authentication plugin configurations and behavior.

---

### **1. MySQL Version Comparison**

#### **MySQL 8.0.39-30**
The following outputs were observed for MySQL 8.0.39-30:
```sql
mysql> SELECT @@version;
+-----------+
| @@version |
+-----------+
| 8.0.39-30 |
+-----------+
1 row in set (0.00 sec)

mysql> SHOW VARIABLES LIKE 'default_authentication_plugin';
+-------------------------------+-----------------------+
| Variable_name                 | Value                 |
+-------------------------------+-----------------------+
| default_authentication_plugin | caching_sha2_password |
+-------------------------------+
1 row in set (0.01 sec)
```

#### **MySQL 8.4.2-2**
In contrast, MySQL 8.4.2-2 produced different results:
```sql
mysql> SELECT @@version;
+-----------+
| @@version |
+-----------+
| 8.4.2-2   |
+-----------+
1 row in set (0.00 sec)

mysql> SHOW VARIABLES LIKE 'default_authentication_plugin';
Empty set (0.01 sec)
```
- **Key Observation**: The `default_authentication_plugin` system variable is **removed** in MySQL 8.4.2-2.

---

### **2. Plugin Status**

#### **MySQL 8.0.39-30**
```bash
$ docker exec -it mypercona80 mysql -u root -e "SHOW PLUGINS;" | grep mysql_native_password
| mysql_native_password            | ACTIVE   | AUTHENTICATION     | NULL    | GPL     |
```

#### **MySQL 8.4.2-2**
```bash
$ sudo docker exec -it mypercona84 mysql -u root -e "SHOW PLUGINS;" | grep mysql_native_password
| mysql_native_password            | DISABLED | AUTHENTICATION     | NULL    | GPL     |
```
- **Key Observation**: In MySQL 8.4.2-2, `mysql_native_password` is **disabled** by default but remains available for manual activation.

---

### **3. Error Encountered in MySQL 8.4.2-2**

When attempting to configure `default_authentication_plugin` in MySQL 8.4.2-2, the following error was encountered:
```
2024-11-20T00:23:34.190854Z 0 [ERROR] [MY-000067] [Server] unknown variable 'default-authentication-plugin=mysql_native_password'.
2024-11-20T00:23:34.193544Z 0 [ERROR] [MY-010119] [Server] Aborting
```

This occurred because the `default_authentication_plugin` variable has been **removed** in MySQL 8.4.

---

### **4. Resolution: Activating `mysql_native_password` in MySQL 8.4.2-2**

To activate the `mysql_native_password` plugin in MySQL 8.4.2-2, the following steps were taken:

#### **Configuration Update**
- Added the following line to the MySQL configuration file (`my.cnf` or equivalent):
    ```ini
    mysql_native_password=ON
    ```

#### **Verification**
After restarting the server, the plugin status was confirmed as active:
```bash
$ sudo docker exec -it mypercona84 mysql -u root -e "SHOW PLUGINS;" | grep mysql_native_password
| mysql_native_password            | ACTIVE   | AUTHENTICATION     | NULL    | GPL     |
```

---

### **5. Key Differences Between MySQL 8.0 and MySQL 8.4**

| **Feature**                     | **MySQL 8.0.39-30**            | **MySQL 8.4.2-2**            |
|---------------------------------|--------------------------------|------------------------------|
| Default Authentication Plugin   | `default_authentication_plugin` exists | Variable removed             |
| Default Plugin Value            | `caching_sha2_password`        | Not applicable               |
| `mysql_native_password` Status  | Active by default              | Disabled by default          |
| Plugin Activation               | Not required                  | Manual activation via config |

---

### **6. Conclusion**

- **Shift in Authentication Standards**:
    - MySQL 8.4 emphasizes secure authentication by deprecating legacy methods like `mysql_native_password`.
    - The `default_authentication_plugin` system variable has been removed, requiring explicit activation of `mysql_native_password`.

- **Implications for Support Teams**:
    - Teams must adapt to these changes by:
        - Understanding the removal of the `default_authentication_plugin`.
        - Updating configurations to explicitly enable legacy plugins where required.

- **Outcome**:
    - Successfully activated `mysql_native_password` in MySQL 8.4.2-2, aligning its behavior with MySQL 8.0.39-30.
    - Provided a clear path for managing authentication plugins in MySQL 8.4.

---

### **References**

- [MySQL 8.4 Reference Manual: Native Pluggable Authentication](https://dev.mysql.com/doc/refman/8.4/en/native-pluggable-authentication.html)
- [MySQL 8.0 Reference Manual: Default Authentication Plugin](https://dev.mysql.com/doc/refman/8.0/en/server-system-variables.html#sysvar_default_authentication_plugin)
