# **Lab Guide: Authentication Plugin Behavior in MySQL 8.0 vs MySQL 8.4**

This lab demonstrates the differences in authentication plugin behavior between **MySQL 8.0.39-30** and **MySQL 8.4.2-2** using Docker containers. The focus is on observing default settings, testing user creation, and enabling legacy plugins when necessary.

---

## **1. Lab Environment Setup**

### **Prepare the Workspace**

Create directories for logs, data, and configuration:

```bash
mkdir -p ~/lab/mysql80/{logs,data}
mkdir -p ~/lab/mysql84/{logs,data}

sudo chmod -R 777 ~/lab/mysql80/{logs,data}
sudo chmod -R 777 ~/lab/mysql84/{logs,data}
```

### **Initialize Configuration and Data**

Extract the default `my.cnf` and initialize the data directories from the MySQL images:

```bash
# For MySQL 8.0
sudo docker run --rm \
  -v ~/lab/mysql80/data:/host-mysql-data \
  -v ~/lab/mysql80:/host-config \
  percona-mysql-8.0 \
  bash -c "cat /etc/my.cnf > /host-config/my.cnf && cp -R /var/lib/mysql/* /host-mysql-data"

# For MySQL 8.4
sudo docker run --rm \
  -v ~/lab/mysql84/data:/host-mysql-data \
  -v ~/lab/mysql84:/host-config \
  percona-mysql-8.4 \
  bash -c "cat /etc/my.cnf > /host-config/my.cnf && cp -R /var/lib/mysql/* /host-mysql-data"
```

---

## **2. Run Containers**

Start the MySQL containers with the mounted configuration, logs, and data directories.

### **Run MySQL 8.0 Container**

```bash
sudo docker run --name mypercona80 \
  -d \
  -p 33080:3306 \
  -v ~/lab/mysql80/my.cnf:/etc/my.cnf \
  -v ~/lab/mysql80/logs:/var/log/mysql \
  -v ~/lab/mysql80/data:/var/lib/mysql \
  percona-mysql-8.0
```

### **Run MySQL 8.4 Container**

```bash
sudo docker run --name mypercona84 \
  -d \
  -p 33084:3306 \
  -v ~/lab/mysql84/my.cnf:/etc/my.cnf \
  -v ~/lab/mysql84/logs:/var/log/mysql \
  -v ~/lab/mysql84/data:/var/lib/mysql \
  percona-mysql-8.4
```

---

## **3. Check Authentication Plugin Behavior**

### **Verify Default Authentication Plugin**

#### **MySQL 8.0**
Run the following command to check the default authentication plugin in MySQL 8.0:

```bash
sudo docker exec -it mypercona80 mysql -u root -e "SHOW VARIABLES LIKE 'default_authentication_plugin';"
```

**Expected Output**:
```sql
+-------------------------------+-----------------------+
| Variable_name                 | Value                 |
+-------------------------------+-----------------------+
| default_authentication_plugin | caching_sha2_password |
+-------------------------------+-----------------------+
```

#### **MySQL 8.4**
Run the same command for MySQL 8.4:

```bash
sudo docker exec -it mypercona84 mysql -u root -e "SHOW VARIABLES LIKE 'default_authentication_plugin';"
```

**Expected Output**:
```sql
Empty set (0.01 sec)
```

**Explanation**: The `default_authentication_plugin` system variable has been removed in MySQL 8.4.

---

## **4. Test Plugin Status**

### **Check `mysql_native_password` Plugin Status**

#### **MySQL 8.0**
```bash
sudo docker exec -it mypercona80 mysql -u root -e "SHOW PLUGINS;" | grep mysql_native_password
```

**Expected Output**:
```sql
| mysql_native_password            | ACTIVE   | AUTHENTICATION     | NULL    | GPL     |
```

#### **MySQL 8.4**
```bash
sudo docker exec -it mypercona84 mysql -u root -e "SHOW PLUGINS;" | grep mysql_native_password
```

**Expected Output**:
```sql
| mysql_native_password            | DISABLED | AUTHENTICATION     | NULL    | GPL     |
```

**Explanation**: In MySQL 8.4, the `mysql_native_password` plugin is disabled by default but remains available for activation.

---

## **5. Test User Creation**

### **Attempt to Create a User with `mysql_native_password`**

#### **MySQL 8.4**
Run the following command to create a user using the `mysql_native_password` plugin:

```bash
sudo docker exec -it mypercona84 mysql -u root -e "CREATE USER 'test_user'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY 'password123';"
```

**Expected Output**:
```sql
ERROR 1524 (HY000): Plugin 'mysql_native_password' is not loaded
```

---

### **Create a User with the Default Plugin**

#### **MySQL 8.4**
Run the following commands to create a user with the default authentication plugin and check the plugin used:

```bash
sudo docker exec -it mypercona84 mysql -u root -e "
CREATE USER 'default_user'@'localhost' IDENTIFIED BY 'password123';
SELECT user, host, plugin FROM mysql.user WHERE user = 'default_user';
"
```

**Expected Output**:
```sql
+--------------+-----------+-----------------------+
| user         | host      | plugin                |
+--------------+-----------+-----------------------+
| default_user | localhost | caching_sha2_password |
+--------------+-----------+-----------------------+
```

---

### **Enable `mysql_native_password` in MySQL 8.4**

Update the configuration file (`my.cnf`) to activate `mysql_native_password` in MySQL 8.4:

1. Edit `~/lab/mysql84/my.cnf` and add the following line:
    ```ini
    mysql_native_password=ON
    ```

2. Restart the container:
    ```bash
    sudo docker restart mypercona84
    ```

3. Verify that the plugin is active:
    ```bash
    sudo docker exec -it mypercona84 mysql -u root -e "SHOW PLUGINS;" | grep mysql_native_password
    ```

**Expected Output**:
```sql
| mysql_native_password            | ACTIVE   | AUTHENTICATION     | NULL    | GPL     |
```

4. Retry creating the user with the `mysql_native_password` plugin:
    ```bash
    sudo docker exec -it mypercona84 mysql -u root -e "CREATE USER 'test_user'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY 'password123';"
    ```

**Expected Output**:
```sql
Query OK, 0 rows affected
```

---

## **6. Verify Users and Plugins**

List all users and their authentication plugins in both MySQL 8.0 and MySQL 8.4:

### **MySQL 8.0**
```bash
sudo docker exec -it mypercona80 mysql -u root -e "SELECT user, host, plugin FROM mysql.user;"
```

### **MySQL 8.4**
```bash
sudo docker exec -it mypercona84 mysql -u root -e "SELECT user, host, plugin FROM mysql.user;"
```

Compare the outputs to observe differences in plugin usage and configuration.

---

## **7. Clean Up**

Stop and remove the containers if no longer needed:

```bash
sudo docker stop mypercona80 mypercona84
sudo docker rm mypercona80 mypercona84
```

---

## **Summary**

This lab demonstrates:
- Differences in default authentication plugin behavior between MySQL 8.0 and 8.4.
- Steps to activate `mysql_native_password` in MySQL 8.4.
- Validation of user creation and plugin usage.

