# **Lab Guide: Setting Up MySQL 8.0 and MySQL 8.4 Containers with Mounted Directories**

This guide provides comprehensive instructions to create and manage Docker containers for **MySQL 8.0** and **MySQL 8.4**, ensuring accessible configuration, logs, and data directories mounted on the host.

---

## **1. Prepare the Workspace**

Create the necessary directory structure for mounting MySQL configurations, logs, and data:

```bash
mkdir -p ~/lab/mysql80/{logs,data}
mkdir -p ~/lab/mysql84/{logs,data}

sudo chmod -R 777 ~/lab/mysql80/{logs,data}
sudo chmod -R 777 ~/lab/mysql84/{logs,data}
```

### **Copy Default MySQL Configuration and Data**

Run temporary Docker containers to copy the default MySQL configuration and data to the host directories:

#### **MySQL 8.0**
```bash
sudo docker run --rm \
  -v ~/lab/mysql80/data:/host-mysql-data \
  -v ~/lab/mysql80:/host-config \
  percona-mysql-8.0 \
  bash -c "cat /etc/my.cnf > /host-config/my.cnf && cp -R /var/lib/mysql/* /host-mysql-data"
```

#### **MySQL 8.4**
```bash
sudo docker run --rm \
  -v ~/lab/mysql84/data:/host-mysql-data \
  -v ~/lab/mysql84:/host-config \
  percona-mysql-8.4 \
  bash -c "cat /etc/my.cnf > /host-config/my.cnf && cp -R /var/lib/mysql/* /host-mysql-data"
```

These commands copy the default configuration file (`my.cnf`) and the initial data directory (`/var/lib/mysql`) from the container to the host system.

---

## **2. Create Separate Dockerfiles**

### **Dockerfile for MySQL 8.0**
Create a Dockerfile named `Dockerfile-mysql80`:

```bash
cat > ~/lab/Dockerfile-mysql80 <<EOF
# Use AlmaLinux 8 as a base image
FROM almalinux:8

# Set environment variables
ENV container=docker

# Install necessary tools and Percona repository
RUN yum -y update && \
    yum -y install wget sudo curl yum-utils && \
    yum -y install https://repo.percona.com/yum/percona-release-latest.noarch.rpm && \
    percona-release enable-only ps-80 release && \
    yum -y module disable mysql && \
    yum -y install percona-server-server

# Initialize MySQL data directory
RUN mysqld --initialize-insecure --user=mysql

# Expose MySQL port
EXPOSE 3306

# Start MySQL with root privileges (for testing purposes only)
CMD ["mysqld_safe", "--user=root"]
EOF
```

### **Dockerfile for MySQL 8.4**
Create a Dockerfile named `Dockerfile-mysql84`:

```bash
cat > ~/lab/Dockerfile-mysql84 <<EOF
# Use AlmaLinux 8 as a base image
FROM almalinux:8

# Set environment variables
ENV container=docker

# Install necessary tools and Percona repository
RUN yum -y update && \
    yum -y install wget sudo curl yum-utils && \
    yum -y install https://repo.percona.com/yum/percona-release-latest.noarch.rpm && \
    percona-release enable-only ps-84-lts release && \
    percona-release enable tools release && \
    yum -y module disable mysql && \
    yum -y install percona-server-server

# Initialize MySQL data directory
RUN mysqld --initialize-insecure --user=mysql

# Expose MySQL port
EXPOSE 3306

# Start MySQL with root privileges (for testing purposes only)
CMD ["mysqld_safe", "--user=root"]
EOF
```

These Dockerfiles define the environment and steps required to set up MySQL 8.0 and 8.4 using AlmaLinux as the base image.

---

## **3. Build Docker Images**

### **Build the Image for MySQL 8.0**
```bash
sudo docker build -f ~/lab/Dockerfile-mysql80 -t percona-mysql-8.0 .
```

### **Build the Image for MySQL 8.4**
```bash
sudo docker build -f ~/lab/Dockerfile-mysql84 -t percona-mysql-8.4 .
```

These commands build Docker images for MySQL 8.0 and 8.4 based on their respective Dockerfiles.

---

## **4. Run Containers with Mounted Directories**

### **Run MySQL 8.0 Container**
```bash
sudo docker run --name mypercona80 \
  -d \
  -p 33080:3306 \
  -v ~/lab/mysql80/my.cnf:/etc/my.cnf \
  -v ~/lab/mysql80/logs:/var/log \
  -v ~/lab/mysql80/data:/var/lib/mysql \
  percona-mysql-8.0
sleep 2
sudo chmod +r ~/lab/mysql80/logs/mysqld.log
```

### **Run MySQL 8.4 Container**
```bash
sudo docker run --name mypercona84 \
  -d \
  -p 33084:3306 \
  -v ~/lab/mysql84/my.cnf:/etc/my.cnf \
  -v ~/lab/mysql84/logs:/var/log \
  -v ~/lab/mysql84/data:/var/lib/mysql \
  percona-mysql-8.4
sleep 2
sudo chmod +r ~/lab/mysql84/logs/mysqld.log
```

These commands start the MySQL containers with mounted directories for configurations, logs, and data.

---

## **5. Verify Running Containers**

Check if both containers are running:

```bash
sudo docker ps -a | grep -i mypercona
```

**Expected Output**:
```bash
CONTAINER ID   IMAGE                 COMMAND                  CREATED          STATUS         PORTS                                           NAMES
f9265e4f0258   percona-mysql-8.4     "mysqld_safe"            16 seconds ago   Up 14 seconds   0.0.0.0:33084->3306/tcp, :::33084->3306/tcp    mypercona84
d2175c3d8240   percona-mysql-8.0     "mysqld_safe"            30 seconds ago   Up 29 seconds   0.0.0.0:33080->3306/tcp, :::33080->3306/tcp    mypercona80
```

This command lists all Docker containers and filters for the MySQL containers by name.

---

## **6. Test MySQL Instances**

### **Connect to MySQL 8.0**
```bash
sudo docker exec -it mypercona80 mysql -u root
```

### **Connect to MySQL 8.4**
```bash
sudo docker exec -it mypercona84 mysql -u root
```

### **Connect Bash to MySQL 8.0**
```bash
sudo docker exec -it mypercona80 bash
```

### **Connect Bash to MySQL 8.4**
```bash
sudo docker exec -it mypercona84 bash
```

These commands open interactive MySQL sessions in the running containers. If you encounter issues logging in, verify the container status with `sudo docker ps` and ensure the directories are properly mounted.

---

## **7. Access Mounted Directories**

The following directories on the host now correspond to specific container directories:

| **Container**  | **Host Directory**             | **Mounted Path in Container** |
|-----------------|--------------------------------|--------------------------------|
| MySQL 8.0      | `~/lab/mysql80/my.cnf`         | `/etc/my.cnf`                 |
| MySQL 8.0      | `~/lab/mysql80/logs`           | `/var/log/mysql`              |
| MySQL 8.0      | `~/lab/mysql80/data`           | `/var/lib/mysql`              |
| MySQL 8.4      | `~/lab/mysql84/my.cnf`         | `/etc/my.cnf`                 |
| MySQL 8.4      | `~/lab/mysql84/logs`           | `/var/log/mysql`              |
| MySQL 8.4      | `~/lab/mysql84/data`           | `/var/lib/mysql`              |

You can inspect or edit these directories directly on the host system. For example:
```bash
ls ~/lab/mysql80/logs
ls ~/lab/mysql84/logs
```

---

## **8. Manage Containers**

### **Check Container Status**
To verify container status:
```bash
sudo docker ps -a | grep -i mypercona
```

### **Stop Containers**
To stop the containers:
```bash
sudo docker stop mypercona80
sudo docker stop mypercona84
```

### **Restart Containers**
To restart the containers:
```bash
sudo docker restart mypercona80
sudo docker restart mypercona84
```

### **Remove Containers**
To completely remove the containers:
```bash
sudo docker rm mypercona80
sudo docker rm mypercona84
```

These commands allow you to control the lifecycle of your containers effectively.

---

## **9. Recreate Containers**

If containers need to be recreated, follow these steps:

### **Recreate MySQL 8.0 Container**
```bash
sudo docker stop mypercona80 && \
sudo docker rm mypercona80
sudo rm -Rf ~/lab/mysql80
mkdir -p ~/lab/mysql80/{logs,data}
sudo chmod -R 777 ~/lab/mysql80/{logs,data}
sudo docker run --rm \
  -v ~/lab/mysql80/data:/host-mysql-data \
  -v ~/lab/mysql80:/host-config \
  percona-mysql-8.0 \
  bash -c "cat /etc/my.cnf > /host-config/my.cnf && cp -R /var/lib/mysql/* /host-mysql-data"
sudo docker run --name mypercona80 \
  -d \
  -p 33080:3306 \
  -v ~/lab/mysql80/my.cnf:/etc/my.cnf \
  -v ~/lab/mysql80/logs:/var/log \
  -v ~/lab/mysql80/data:/var/lib/mysql \
  percona-mysql-8.0
sleep 2
sudo chmod +r ~/lab/mysql80/logs/mysqld.log
```

### **Recreate MySQL 8.4 Container**
```bash
sudo docker stop mypercona84 && \
sudo docker rm mypercona84
sudo rm -Rf ~/lab/mysql84
mkdir -p ~/lab/mysql84/{logs,data}
sudo chmod -R 777 ~/lab/mysql84/{logs,data}
sudo docker run --rm \
  -v ~/lab/mysql84/data:/host-mysql-data \
  -v ~/lab/mysql84:/host-config \
  percona-mysql-8.4 \
  bash -c "cat /etc/my.cnf > /host-config/my.cnf && cp -R /var/lib/mysql/* /host-mysql-data"
sudo docker run --name mypercona84 \
  -d \
  -p 33084:3306 \
  -v ~/lab/mysql84/my.cnf:/etc/my.cnf \
  -v ~/lab/mysql84/logs:/var/log \
  -v ~/lab/mysql84/data:/var/lib/mysql \
  percona-mysql-8.4
sleep 2
sudo chmod +r ~/lab/mysql84/logs/mysqld.log
```

These commands ensure that the containers are cleanly recreated with the same configurations and mounted directories.

---

## **10. Troubleshooting Common Issues**

### **MySQL Fails to Start**
- **Check Logs for Mysql 8.0**:
  ```bash
  tail -100f ~/lab/mysql80/logs/mysqld.log
  ```

- **Check Logs for Mysql 8.4**:
  ```bash
  tail -100f ~/lab/mysql84/logs/mysqld.log
  ```

  Look for errors related to permissions, configurations, or missing files.

- **Verify Directory Permissions**:
  Ensure directories have the correct permissions:
  ```bash
  sudo chmod -R 777 ~/lab/mysql80/{logs,data}
  sudo chmod -R 777 ~/lab/mysql84/{logs,data}
  ```

### **Port Conflicts**
- Ensure no other service is using the ports `33080` or `33084`:
  ```bash
  sudo lsof -i -P -n | grep LISTEN
  ```

- If there’s a conflict, modify the port mappings in the `docker run` commands:
  ```bash
  -p 33090:3306  # Example alternative for MySQL 8.0
  ```

---

## **11. Summary**

### **Files**
- Dockerfiles: `Dockerfile-mysql80`, `Dockerfile-mysql84`

### **Images**
- MySQL 8.0: `percona-mysql-8.0`
- MySQL 8.4: `percona-mysql-8.4`

### **Containers**
- MySQL 8.0: `mypercona80`
- MySQL 8.4: `mypercona84`

### **Mounted Directories**
- Host directories for configuration, logs, and data:
  - `~/lab/mysql80/my.cnf`, `~/lab/mysql80/logs`, `~/lab/mysql80/data`
  - `~/lab/mysql84/my.cnf`, `~/lab/mysql84/logs`, `~/lab/mysql84/data`
