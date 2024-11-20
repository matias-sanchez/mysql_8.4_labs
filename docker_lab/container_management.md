Below is the fully optimized version of your laboratory guide with modifications to include the mounted directories for MySQL configurations, logs, and data. This updated guide ensures clarity, consistency, and usability for all technical users.

---

# **Lab Guide: Setting Up MySQL 8.0 and MySQL 8.4 Containers with Mounted Directories**

This guide provides comprehensive instructions to create and manage Docker containers for **MySQL 8.0** and **MySQL 8.4**, ensuring accessible configuration, logs, and data directories mounted on the host.

---

## **1. Prepare the Workspace**

Create the necessary directory structure for mounting MySQL configurations, logs, and data:

```bash
mkdir -p ~/lab/mysql80/{config,logs,data}
mkdir -p ~/lab/mysql84/{config,logs,data}
```

---

## **2. Create Separate Dockerfiles**

### **Dockerfile for MySQL 8.0**

Use the following commands to create the Dockerfiles directly in the `~/lab` directory:

```bash
# Create and populate Dockerfile for MySQL 8.0
cat > ~/lab/Dockerfile-mysql80 <<EOF
# Use AlmaLinux 8 as a base image (binary-compatible with RHEL)
FROM almalinux:8

# Set environment variables
ENV container=docker

# Update system and install necessary tools
RUN yum -y update && \\
    yum -y install wget sudo curl yum-utils

# Install the Percona repository
RUN yum -y install https://repo.percona.com/yum/percona-release-latest.noarch.rpm

# Enable Percona Server 8.0 repository
RUN percona-release enable-only ps-80 release

# Disable the default MySQL module
RUN yum -y module disable mysql

# Install Percona Server 8.0
RUN yum -y install percona-server-server

# Expose MySQL port
EXPOSE 3306

# Start MySQL and keep the container running
CMD ["mysqld_safe"]
EOF
```

```bash
# Create and populate Dockerfile for MySQL 8.4
cat > ~/lab/Dockerfile-mysql84 <<EOF
# Use AlmaLinux 8 as a base image (binary-compatible with RHEL)
FROM almalinux:8

# Set environment variables
ENV container=docker

# Update system and install necessary tools
RUN yum -y update && \\
    yum -y install wget sudo curl yum-utils

# Install the Percona repository
RUN yum -y install https://repo.percona.com/yum/percona-release-latest.noarch.rpm

# Enable Percona Server 8.4 and tools repositories
RUN percona-release enable-only ps-84-lts release && \\
    percona-release enable tools release

# Disable the default MySQL module
RUN yum -y module disable mysql

# Install Percona Server 8.4
RUN yum -y install percona-server-server

# Expose MySQL port
EXPOSE 3306

# Start MySQL and keep the container running
CMD ["mysqld_safe"]
EOF
```

---

## **3. Build Docker Images**

### **Build Image for MySQL 8.0**
```bash
sudo docker build -f ~/lab/Dockerfile-mysql80 -t percona-mysql-8.0 .
```

### **Build Image for MySQL 8.4**
```bash
sudo docker build -f ~/lab/Dockerfile-mysql84 -t percona-mysql-8.4 .
```

---

## **4. Run Containers with Mounted Directories**

### **Run MySQL 8.0 Container**
```bash
sudo docker run --name mypercona80 \
  -d \
  -p 33080:3306 \
  -v ~/lab/mysql80/config:/etc/mysql \
  -v ~/lab/mysql80/logs:/var/log/mysql \
  -v ~/lab/mysql80/data:/var/lib/mysql \
  percona-mysql-8.0
```

### **Run MySQL 8.4 Container**
```bash
sudo docker run --name mypercona84 \
  -d \
  -p 33084:3306 \
  -v ~/lab/mysql84/config:/etc/mysql \
  -v ~/lab/mysql84/logs:/var/log/mysql \
  -v ~/lab/mysql84/data:/var/lib/mysql \
  percona-mysql-8.4
```

---

## **5. Verify Running Containers**

Check if both containers are running:
```bash
sudo docker ps | grep -i mypercona
```

**Expected Output**:
```bash
CONTAINER ID   IMAGE                 COMMAND                  CREATED          STATUS         PORTS                                           NAMES
f9265e4f0258   percona-mysql-8.4     "mysqld_safe"            16 seconds ago   Up 14 seconds   0.0.0.0:33084->3306/tcp, :::33084->3306/tcp    mypercona84
d2175c3d8240   percona-mysql-8.0     "mysqld_safe"            30 seconds ago   Up 29 seconds   0.0.0.0:33080->3306/tcp, :::33080->3306/tcp    mypercona80
```

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

---

## **7. Access Mounted Directories**

The following directories on the host now correspond to specific container directories:

| **Container**  | **Host Directory**             | **Mounted Path in Container** |
|-----------------|--------------------------------|--------------------------------|
| MySQL 8.0      | `~/lab/mysql80/config`         | `/etc/mysql`                  |
| MySQL 8.0      | `~/lab/mysql80/logs`           | `/var/log/mysql`              |
| MySQL 8.0      | `~/lab/mysql80/data`           | `/var/lib/mysql`              |
| MySQL 8.4      | `~/lab/mysql84/config`         | `/etc/mysql`                  |
| MySQL 8.4      | `~/lab/mysql84/logs`           | `/var/log/mysql`              |
| MySQL 8.4      | `~/lab/mysql84/data`           | `/var/lib/mysql`              |

You can access these directories directly on the host for editing configuration files or analyzing logs:
```bash
ls ~/lab/mysql80/logs
ls ~/lab/mysql84/config
```

---

## **8. Manage Containers**

### **Stop Containers**
```bash
sudo docker stop mypercona80
sudo docker stop mypercona84
```

### **Restart Containers**
```bash
sudo docker start mypercona80
sudo docker start mypercona84
```

### **Remove Containers**
```bash
sudo docker rm mypercona80
sudo docker rm mypercona84
```

---

## **9. Recreate Containers**

### **Recreate MySQL 8.0 Container**
```bash
cd ~/lab
sudo docker stop mypercona80 && \
sudo docker rm mypercona80 && \
sudo docker run --name mypercona80 \
  -d \
  -p 33080:3306 \
  -v ~/lab/mysql80/config:/etc/mysql \
  -v ~/lab/mysql80/logs:/var/log/mysql \
  -v ~/lab/mysql80/data:/var/lib/mysql \
  percona-mysql-8.0
```

### **Recreate MySQL 8.4 Container**
```bash
cd ~/lab
sudo docker stop mypercona84 && \
sudo docker rm mypercona84 && \
sudo docker run --name mypercona84 \
  -d \
  -p 33084:3306 \
  -v ~/lab/mysql84/config:/etc/mysql \
  -v ~/lab/mysql84/logs:/var/log/mysql \
  -v ~/lab/mysql84/data:/var/lib/mysql \
  percona-mysql-8.4
```

---

## **10. Summary**

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
  - `~/lab/mysql80/config`, `~/lab/mysql80/logs`, `~/lab/mysql80/data`
  - `~/lab/mysql84/config`, `~/lab/mysql84/logs`, `~/lab/mysql84/data`
