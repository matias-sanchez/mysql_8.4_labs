# **Lab Guide: Authentication Plugin Behavior in MySQL 8.0 vs MySQL 8.4**

This lab focuses on analyzing the differences in authentication plugin behavior between **MySQL 8.0.39-30** and **MySQL 8.4.2-2** using MySQL SQL commands. The containers `mypercona80` and `mypercona84` represent MySQL 8.0 and MySQL 8.4 environments, respectively.

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

Run the following commands to observe the default authentication plugin configuration.

- **MySQL 8.0**:
  ```sql
  SHOW VARIABLES LIKE 'default_authentication_plugin';
  ```

- **MySQL 8.4**:
  ```sql
  SHOW VARIABLES LIKE 'default_authentication_plugin';
  ```

- In MySQL 8.0, `default_authentication_plugin` is available and defaults to `caching_sha2_password`.
- In MySQL 8.4, `default_authentication_plugin` is no longer available as it has been removed.

---

### Check Plugin Status

To determine the status of the `mysql_native_password` plugin:

- **MySQL 8.0**:
  ```sql
  SHOW PLUGINS;
  ```

  Search for the `mysql_native_password` plugin. It should display as **ACTIVE**.

- **MySQL 8.4**:
  ```sql
  SHOW PLUGINS;
  ```

  The `mysql_native_password` plugin will be listed as **DISABLED**.

---

## **3. User Creation**

### Create a User with `mysql_native_password`

Attempt to create a user with the `mysql_native_password` plugin in MySQL 8.4:

```sql
CREATE USER 'test_user'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY 'password123';
```

This will fail with an error:
```
ERROR 1524 (HY000): Plugin 'mysql_native_password' is not loaded
```

---

### Create a User with the Default Authentication Plugin

Create a user with the default authentication plugin in MySQL 8.4:

```sql
CREATE USER 'default_user'@'localhost' IDENTIFIED BY 'password123';
SELECT user, host, plugin FROM mysql.user WHERE user = 'default_user';
```

The plugin should show as `caching_sha2_password`.

---

## **4. Enable `mysql_native_password` Plugin in MySQL 8.4**

### Update Configuration

To enable `mysql_native_password`, add the following configuration to the `my.cnf` file:
```ini
mysql_native_password=ON
```

Restart the MySQL 8.4 container to apply the changes:
```bash
sudo docker restart mypercona84
```

### Verify Plugin Activation

After restarting, check the plugin status again:
```sql
SHOW PLUGINS;
```

The `mysql_native_password` plugin should now display as **ACTIVE**.

---

### Retry Creating a User with `mysql_native_password`

Once the plugin is activated, create a user with `mysql_native_password`:

```sql
CREATE USER 'test_user'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY 'password123';
SELECT user, host, plugin FROM mysql.user WHERE user = 'test_user';
```

The plugin for `test_user` should be `mysql_native_password`.

---

## **5. Verify All Users and Plugins**

To view all users and their associated plugins in each MySQL version, use:

- **MySQL 8.0**:
  ```sql
  SELECT user, host, plugin FROM mysql.user;
  ```

- **MySQL 8.4**:
  ```sql
  SELECT user, host, plugin FROM mysql.user;
  ```

This will display all users and their respective authentication plugins for both MySQL environments.

---

## **6. Summary of Observations**

| **Feature**                     | **MySQL 8.0.39-30**            | **MySQL 8.4.2-2**            |
|---------------------------------|--------------------------------|------------------------------|
| Default Authentication Plugin   | `default_authentication_plugin` exists | Removed                     |
| Default Plugin Value            | `caching_sha2_password`        | Not applicable               |
| `mysql_native_password` Status  | Active by default              | Disabled by default          |
| Plugin Activation               | Not required                  | Manual activation via config |

--- 
