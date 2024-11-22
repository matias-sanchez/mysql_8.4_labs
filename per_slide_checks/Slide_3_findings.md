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

### Explanation of `default_authentication_plugin`
- In MySQL 8.0, `default_authentication_plugin` is available and defaults to `caching_sha2_password`.
- In MySQL 8.4, `default_authentication_plugin` is no longer available as it has been removed.

---

### **No Possibility to Enable `default_authentication_plugin` in MySQL 8.4**

Attempting to enable `default_authentication_plugin` in MySQL 8.4 using the configuration file results in an error. 

Steps to reproduce:
1. Edit the configuration file:
   ```bash
   sudo vi ~/lab/mysql84/my.cnf
   ```
2. Add the line:
   ```ini
   default_authentication_plugin=caching_sha2_password
   ```
3. Restart the container:
   ```bash
   sudo docker restart mypercona84
   ```

Error observed in the logs:
```
2024-11-22T12:18:34.866485Z 0 [ERROR] [MY-000067] [Server] unknown variable 'default_authentication_plugin=caching_sha2_password'.
2024-11-22T12:18:34.867367Z 0 [ERROR] [MY-010119] [Server] Aborting
```

This confirms that `default_authentication_plugin` is not configurable in MySQL 8.4.

---

### Check Plugin Status

To determine the status of the `mysql_native_password` plugin:

- **MySQL 8.0**:
  ```sql
  SELECT 
      * 
  FROM 
      INFORMATION_SCHEMA.PLUGINS 
  WHERE 
      PLUGIN_NAME = 'mysql_native_password';
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
  SELECT 
      * 
  FROM 
      INFORMATION_SCHEMA.PLUGINS 
  WHERE 
      PLUGIN_NAME = 'mysql_native_password';
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

#### MySQL 8.4:
Attempt to create a user with `mysql_native_password`:
```sql
CREATE USER 
    'test_user'@'localhost' 
IDENTIFIED WITH 
    'mysql_native_password' 
BY 
    'password123';
```

Error:
```sql
ERROR 1524 (HY000): Plugin 'mysql_native_password' is not loaded
```

#### MySQL 8.0:
Create a user indicating the plugin :
```sql
CREATE USER 
    'test_user'@'localhost' 
IDENTIFIED WITH 
    'mysql_native_password' 
BY 
    'password123';
```

To check the user's plugin:
```sql
SELECT 
    user, 
    host, 
    plugin 
FROM 
    mysql.user 
WHERE 
    user = 'test_user';
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
CREATE USER 
    'default_user'@'localhost' 
IDENTIFIED BY 
    'password123';
```

To check the user's plugin:
```sql
SELECT 
    user, 
    host, 
    plugin 
FROM 
    mysql.user 
WHERE 
    user = 'default_user';
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

This output is consistent in both MySQL 8.0 and 8.4.

---

## **4. Enable `mysql_native_password` Plugin in MySQL 8.4**

### Update Configuration

Edit the `my.cnf` file:
```bash
sudo vi ~/lab/mysql84/my.cnf
```

Add the line:
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
SELECT 
    * 
FROM 
    INFORMATION_SCHEMA.PLUGINS 
WHERE 
    PLUGIN_NAME = 'mysql_native_password';
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

Create a user after enabling the plugin:
```sql
CREATE USER 
    'test_user'@'localhost' 
IDENTIFIED WITH 
    'mysql_native_password' 
BY 
    'password123';

SELECT 
    user, 
    host, 
    plugin 
FROM 
    mysql.user 
WHERE 
    user = 'test_user';
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

## **

5. Summary of Observations**

| **Feature**                     | **MySQL 8.0.39-30**            | **MySQL 8.4.2-2**            |
|---------------------------------|--------------------------------|------------------------------|
| Default Authentication Plugin   | `default_authentication_plugin` exists | Removed                     |
| Default Plugin Value            | `caching_sha2_password`        | Not applicable               |
| `mysql_native_password` Status  | Active by default              | Disabled by default          |
| Plugin Activation               | Not required                  | Manual activation via config |

--- 
