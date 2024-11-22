# **Lab Guide: Authentication Plugin Behavior in MySQL 8.0 vs MySQL 8.4**

This lab demonstrates the differences in authentication plugin behavior between **MySQL 8.0.39-30** and **MySQL 8.4.2-2** using MySQL SQL commands. The containers `mypercona80` and `mypercona84` represent MySQL 8.0 and MySQL 8.4 environments, respectively.

---

## **1. Environment Setup**

### Connecting to MySQL

Connect to the containers as follows:
- **MySQL 8.0**: 
  ```bash
  sudo docker exec -it mypercona80 mysql -u root
  ```
- **MySQL 8.4**: 
  ```bash
  sudo docker exec -it mypercona84 mysql -u root
  ```

---

## **2. Authentication Plugin Behavior**

### Verify the Default Authentication Plugin

Run the following commands to observe the default authentication plugin configuration:

- **MySQL 8.0**:
  ```sql
  SHOW VARIABLES LIKE 'default_authentication_plugin';
  ```
  Output:
  ```sql
  +-------------------------------+-----------------------+
  | Variable_name                 | Value                 |
  +-------------------------------+-----------------------+
  | default_authentication_plugin | caching_sha2_password |
  +-------------------------------+-----------------------+
  1 row in set (0.80 sec)
  ```

- **MySQL 8.4**:
  ```sql
  SHOW VARIABLES LIKE 'default_authentication_plugin';
  ```
  Output:
  ```sql
  Empty set (0.00 sec)
  ```

Explanation:
- In MySQL 8.0, `default_authentication_plugin` is available and defaults to `caching_sha2_password`.
- In MySQL 8.4, `default_authentication_plugin` is no longer available as it has been removed.

---

### Check Plugin Status

To determine the status of the `mysql_native_password` plugin:

- **MySQL 8.0**:
  ```sql
  SELECT * FROM INFORMATION_SCHEMA.PLUGINS WHERE PLUGIN_NAME = 'mysql_native_password';
  ```
  Output:
  ```sql
  +-----------------------+----------------+---------------+----------------+---------------------+----------------+------------------------+--------------------+-----------------------------+----------------+-------------+
  | PLUGIN_NAME           | PLUGIN_VERSION | PLUGIN_STATUS | PLUGIN_TYPE    | PLUGIN_TYPE_VERSION | PLUGIN_LIBRARY | PLUGIN_LIBRARY_VERSION | PLUGIN_AUTHOR      | PLUGIN_DESCRIPTION          | PLUGIN_LICENSE | LOAD_OPTION |
  +-----------------------+----------------+---------------+----------------+---------------------+----------------+------------------------+--------------------+-----------------------------+----------------+-------------+
  | mysql_native_password | 1.1            | ACTIVE        | AUTHENTICATION | 2.1                 | NULL           | NULL                   | Oracle Corporation | Native MySQL authentication | GPL            | FORCE       |
  +-----------------------+----------------+---------------+----------------+---------------------+----------------+------------------------+--------------------+-----------------------------+----------------+-------------+
  1 row in set (0.03 sec)
  ```

- **MySQL 8.4**:
  ```sql
  SELECT * FROM INFORMATION_SCHEMA.PLUGINS WHERE PLUGIN_NAME = 'mysql_native_password';
  ```
  Output:
  ```sql
  +-----------------------+----------------+---------------+----------------+---------------------+----------------+------------------------+--------------------+-----------------------------+----------------+-------------+
  | PLUGIN_NAME           | PLUGIN_VERSION | PLUGIN_STATUS | PLUGIN_TYPE    | PLUGIN_TYPE_VERSION | PLUGIN_LIBRARY | PLUGIN_LIBRARY_VERSION | PLUGIN_AUTHOR      | PLUGIN_DESCRIPTION          | PLUGIN_LICENSE | LOAD_OPTION |
  +-----------------------+----------------+---------------+----------------+---------------------+----------------+------------------------+--------------------+-----------------------------+----------------+-------------+
  | mysql_native_password | 1.1            | DISABLED      | AUTHENTICATION | 2.1                 | NULL           | NULL                   | Oracle Corporation | Native MySQL authentication | GPL            | OFF         |
  +-----------------------+----------------+---------------+----------------+---------------------+----------------+------------------------+--------------------+-----------------------------+----------------+-------------+
  1 row in set (0.05 sec)
  ```

---

## **3. User Creation** 

### Create a User with `mysql_native_password`

Attempt to create a user with the `mysql_native_password` plugin in MySQL 8.4:
```sql
CREATE USER 'test_user'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY 'password123';
```

Error:
```sql
ERROR 1524 (HY000): Plugin 'mysql_native_password' is not loaded
```

In MySQL 8.0:
```sql
CREATE USER 'test_user'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY 'password123';
SELECT user, host, plugin FROM mysql.user WHERE user = 'test_user';
```
Output:
```sql
+-----------+-----------+-----------------------+
| user      | host      | plugin                |
+-----------+-----------+-----------------------+
| test_user | localhost | mysql_native_password |
+-----------+-----------+-----------------------+
1 row in set (0.00 sec)
```

---

### Create a User with the Default Authentication Plugin

Create a user with the default authentication plugin in MySQL 8.4:
```sql
CREATE USER 'default_user'@'localhost' IDENTIFIED BY 'password123';
```

To check the user's plugin:
```sql
SELECT user, host, plugin FROM mysql.user WHERE user = 'default_user';
```

Output:
```sql
+--------------+-----------+-----------------------+
| user         | host      | plugin                |
+--------------+-----------+-----------------------+
| default_user | localhost | caching_sha2_password |
+--------------+-----------+-----------------------+
1 row in set (0.00 sec)
```

This output is identical in both MySQL 8.0 and 8.4.

---

## **4. Enable `mysql_native_password` Plugin in MySQL 8.4**

### Update Configuration

To modify `my.cnf`, use:
```bash
sudo vi ~/lab/mysql84/my.cnf
```

Add the following line:
```ini
mysql_native_password=ON
```

Restart the MySQL 8.4 container:
```bash
sudo docker restart mypercona84
```

---

### Verify Plugin Activation

Check the plugin status after the restart:
```sql
SELECT * FROM INFORMATION_SCHEMA.PLUGINS WHERE PLUGIN_NAME = 'mysql_native_password';
```

Output:
```sql
+-----------------------+----------------+---------------+----------------+---------------------+----------------+------------------------+--------------------+-----------------------------+----------------+-------------+
| PLUGIN_NAME           | PLUGIN_VERSION | PLUGIN_STATUS | PLUGIN_TYPE    | PLUGIN_TYPE_VERSION | PLUGIN_LIBRARY | PLUGIN_LIBRARY_VERSION | PLUGIN_AUTHOR      | PLUGIN_DESCRIPTION          | PLUGIN_LICENSE | LOAD_OPTION |
+-----------------------+----------------+---------------+----------------+---------------------+----------------+------------------------+--------------------+-----------------------------+----------------+-------------+
| mysql_native_password | 1.1            | ACTIVE        | AUTHENTICATION | 2.1                 | NULL           | NULL                   | Oracle Corporation | Native MySQL authentication | GPL            | ON          |
+-----------------------+----------------+---------------+----------------+---------------------+----------------+------------------------+--------------------+-----------------------------+----------------+-------------+
1 row in set (0.00 sec)
```

---

### Retry Creating a User with `mysql_native_password`

After activating the plugin, create a user:
```sql
CREATE USER 'test_user'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY 'password123';
SELECT user, host, plugin FROM mysql.user WHERE user = 'test_user';
```

Output:
```sql
+-----------+-----------+-----------------------+
| user      | host      | plugin                |
+-----------+-----------+-----------------------+
| test_user | localhost | mysql_native_password |
+-----------+-----------+-----------------------+
1 row in set (0.00 sec)
```

---

## **5. Summary of Observations**

| **Feature**                     | **MySQL 8.0.39-30**            | **MySQL 8.4.2-2**            |
|---------------------------------|--------------------------------|------------------------------|
| Default Authentication Plugin   | `default_authentication_plugin` exists | Removed                     |
| Default Plugin Value            | `caching_sha2_password`        | Not applicable               |
| `mysql_native_password` Status  | Active by default              | Disabled by default          |
| Plugin Activation               | Not required                  | Manual activation via config |

--- 
