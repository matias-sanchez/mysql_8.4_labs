To maintain clear identification of Dockerfiles and images for MySQL 8.0 and MySQL 8.4, follow these steps:

---

### **Step 1: Create Separate Dockerfiles**
Name the Dockerfiles clearly to differentiate between MySQL 8.0 and MySQL 8.4.

#### **Dockerfile for MySQL 8.0**
Create a file named `Dockerfile-mysql80` with the following content:

```dockerfile
# Use AlmaLinux 8 as a base image (binary-compatible with RHEL)
FROM almalinux:8

# Set environment variables
ENV container=docker

# Update system and install necessary tools
RUN yum -y update && \
    yum -y install wget sudo curl yum-utils

# Install the Percona repository
RUN yum -y install https://repo.percona.com/yum/percona-release-latest.noarch.rpm

# Enable Percona Server 8.0 repository
RUN percona-release enable-only ps-80 release

# Disable the default MySQL module
RUN yum -y module disable mysql

# Install Percona Server 8.0
RUN yum -y install percona-server-server

# Initialize MySQL data directory
RUN mysqld --initialize-insecure --user=mysql

# Expose MySQL port
EXPOSE 3306

# Start MySQL and keep the container running
CMD ["mysqld_safe"]
```

#### **Dockerfile for MySQL 8.4**
Create another file named `Dockerfile-mysql84` with the following content:

```dockerfile
# Use AlmaLinux 8 as a base image (binary-compatible with RHEL)
FROM almalinux:8

# Set environment variables
ENV container=docker

# Update system and install necessary tools
RUN yum -y update && \
    yum -y install wget sudo curl yum-utils

# Install the Percona repository
RUN yum -y install https://repo.percona.com/yum/percona-release-latest.noarch.rpm

# Enable Percona Server 8.4 and tools repositories
RUN percona-release enable-only ps-84-lts release && \
    percona-release enable tools release

# Disable the default MySQL module
RUN yum -y module disable mysql

# Install Percona Server 8.4
RUN yum -y install percona-server-server

# Initialize MySQL data directory
RUN mysqld --initialize-insecure --user=mysql

# Expose MySQL port
EXPOSE 3306

# Start MySQL and keep the container running
CMD ["mysqld_safe"]
```

---

### **Step 2: Build Docker Images**
Use the `-f` option to specify the Dockerfile during the build process.

#### **Build the Image for MySQL 8.0**
Run the following command to build the image for MySQL 8.0:

```bash
sudo docker build -f Dockerfile-mysql80 -t percona-mysql-8.0 .
```

- `-f Dockerfile-mysql80`: Specifies the Dockerfile for MySQL 8.0.
- `-t percona-mysql-8.0`: Tags the image as `percona-mysql-8.0`.

#### **Build the Image for MySQL 8.4**
Run the following command to build the image for MySQL 8.4:

```bash
sudo docker build -f Dockerfile-mysql84 -t percona-mysql-8.4 .
```

- `-f Dockerfile-mysql84`: Specifies the Dockerfile for MySQL 8.4.
- `-t percona-mysql-8.4`: Tags the image as `percona-mysql-8.4`.

---

### **Step 3: Run Containers**
Use the built images to run separate containers for MySQL 8.0 and MySQL 8.4.

#### **Run the MySQL 8.0 Container**
```bash
sudo docker run --name mypercona80 -d -p 33080:3306 percona-mysql-8.0
```

- `--name mypercona80`: Names the container `mypercona80`.
- `-p 33080:3306`: Maps port 3306 in the container to port 33080 on the host.

#### **Run the MySQL 8.4 Container**
```bash
sudo docker run --name mypercona84 -d -p 33084:3306 percona-mysql-8.4
```

- `--name mypercona84`: Names the container `mypercona84`.
- `-p 33084:3306`: Maps port 3306 in the container to port 33084 on the host.

---

### **Step 4: Verify the Running Containers**
Check if both containers are running:

```bash
sudo docker ps | grep -i mypercona
```

You should see both containers:

```bash
CONTAINER ID   IMAGE                 COMMAND                  CREATED          STATUS         PORTS                                           NAMES
f9265e4f0258   percona-mysql-8.4     "mysqld_safe"            16 seconds ago   Up 14 seconds   0.0.0.0:33084->3306/tcp, :::33084->3306/tcp    mypercona84
d2175c3d8240   percona-mysql-8.0     "mysqld_safe"            30 seconds ago   Up 29 seconds   0.0.0.0:33080->3306/tcp, :::33080->3306/tcp    mypercona80
```

---

### **Step 5: Test MySQL Instances**
#### **Connect to MySQL 8.0**
```bash
sudo docker exec -it mypercona80 mysql -u root
```

#### **Connect to MySQL 8.4**
```bash
sudo docker exec -it mypercona84 mysql -u root
```

---

### **Step 6: Manage Containers**
- **Stop Containers**:
  ```bash
  sudo docker stop mypercona80
  sudo docker stop mypercona84
  ```
- **Restart Containers**:
  ```bash
  sudo docker start mypercona80
  sudo docker start mypercona84
  ```
- **Remove Containers**:
  ```bash
  sudo docker rm mypercona80
  sudo docker rm mypercona84
  ```

### **Step 7: Recreate Containers**

To recreate the MySQL containers, follow these steps:

#### **Recreate MySQL 8.0 Container**
```bash
cd ~/lab
sudo docker stop mypercona80 && \
sudo docker rm mypercona80 && \
sudo docker run --name mypercona80 -d -p 33080:3306 percona-mysql-8.0
```

#### **Recreate MySQL 8.4 Container**
```bash
cd ~/lab
sudo docker stop mypercona84 && \
sudo docker rm mypercona84 && \
sudo docker run --name mypercona84 -d -p 33084:3306 percona-mysql-8.4
```

---

### Summary of Image Names and Dockerfiles:
- **Dockerfiles**: `Dockerfile-mysql80`, `Dockerfile-mysql84`
- **Image Names**: `percona-mysql-8.0`, `percona-mysql-8.4`
- **Container Names**: `mypercona80`, `mypercona84`
