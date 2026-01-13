# SVHA NetBox Deployment

This repository hosts the configuration and source code for the **SVHA NetBox** instance. It is a containerized deployment tailored for St Vincent's Health Australia, featuring:

*   **NetBox v3.7.8**: The core IPAM/DCIM application.
*   **Docker & Docker Compose**: For simplified orchestration and management.
*   **PostgreSQL v15 & Redis v7**: Dedicated database and caching services.
*   **Nginx Reverse Proxy**: For secure HTTPS termination (Port 443).
*   **LDAP/AD Integration**: Pre-configured support for Active Directory authentication.

---

## 🚀 Quick Start (Docker)

### Start NetBox Stack
This stack includes NetBox, PostgreSQL, Redis, and Nginx.

```bash
docker-compose -f docker-compose-netbox.yml up -d
```

*   **Access:** [https://localhost](https://localhost)
*   **Credentials:**
    *   User: `admin`
    *   Pass: `admin`

---

## 🛠️ On-Premise Deployment Guide (Ubuntu)

This guide provides step-by-step instructions for deploying this NetBox instance on a fresh **Ubuntu 22.04 LTS** server using Docker. This is the **preferred and supported** method.

### 1. System Requirements
*   **OS:** Ubuntu 22.04 LTS
*   **CPU:** 4 Cores
*   **RAM:** 8 GB
*   **Storage:** 50 GB+
*   **Network:** Static IP Address, Internet Access (to pull Docker images)

### 2. Install Dependencies
Update the system and install Docker and Git.

```bash
# Update System
sudo apt-get update && sudo apt-get upgrade -y

# Install Git and Utils
sudo apt-get install -y git curl apt-transport-https ca-certificates software-properties-common

# Add Docker's Official GPG Key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker Repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Verify Docker Installation
sudo docker run hello-world
```

### 3. Clone Repository
Clone this repository to the `/opt` directory (standard for production apps).

```bash
cd /opt
sudo git clone https://github.com/57275717/SVHA_Netbox_Public.git netbox
cd netbox
```

### 4. Configuration (First Time Only)

#### A. SSL Certificates
The repository includes self-signed certificates in `nginx-proxy/`. For production, replace these with your valid internal certificates.

1.  Place your `.crt` and `.key` files in `nginx-proxy/`.
2.  Update `nginx-proxy/nginx.conf` if filenames differ from `netbox.crt` and `netbox.key`.

#### B. Active Directory (LDAP)
Edit the LDAP configuration file to match your domain controller settings.

```bash
sudo nano NetBox_Dev/netbox/netbox/ldap_config.py
```

**Update the following variables:**
*   `AUTH_LDAP_SERVER_URI`: e.g., `ldaps://dc01.svha.org.au`
*   `AUTH_LDAP_BIND_DN`: Service Account DN (e.g., `CN=NetBox Svc,OU=Service Accounts...`)
*   `AUTH_LDAP_BIND_PASSWORD`: Service Account Password
*   `AUTH_LDAP_USER_SEARCH`: Base DN for users.
*   `AUTH_LDAP_GROUP_SEARCH`: Base DN for groups.

### 5. Start Application
Start the NetBox stack.

```bash
sudo docker compose -f docker-compose-netbox.yml up -d
```

### 6. Create Admin User
If this is a fresh install, create the initial local administrator account.

```bash
sudo docker compose -f docker-compose-netbox.yml exec netbox python manage.py createsuperuser
# Follow the prompts to set username (e.g., admin) and password.
```

### 7. Access NetBox
*   **URL:** `https://<YOUR_SERVER_IP>`
*   **Protocol:** HTTPS (Port 443)
    *   *Note: If using self-signed certs, accept the browser warning.*

---

## 📚 Manual Installation Guide (Reference Only)

**WARNING:** This section is for reference purposes only for infrastructure technicians who wish to understand the underlying components. **Do NOT run these steps if you are using the Docker deployment above.** Running both will cause port conflicts.

If you must install NetBox without Docker (Bare Metal), follow these steps on **Ubuntu 22.04**.

### 1. Install PostgreSQL & Redis
```bash
sudo apt-get update
sudo apt-get install -y postgresql postgresql-contrib redis-server
```

### 2. Configure Database
```bash
# Start PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create Database and User
sudo -u postgres psql
postgres=# CREATE DATABASE netbox;
postgres=# CREATE USER netbox WITH PASSWORD 'J5brHr7V>EbQC';
postgres=# GRANT ALL PRIVILEGES ON DATABASE netbox TO netbox;
postgres=# \q
```

### 3. Install Python Environment
```bash
sudo apt-get install -y python3 python3-pip python3-venv python3-dev build-essential libxml2-dev libxslt1-dev libffi-dev libpq-dev libssl-dev zlib1g-dev libldap2-dev libsasl2-dev
```

### 4. Install NetBox
```bash
# Create Directory
sudo mkdir -p /opt/netbox/
cd /opt/netbox/

# Copy Application Files (from this repo)
sudo cp -r /path/to/repo/NetBox_Dev/* .

# Create Virtual Environment
sudo python3 -m venv venv
source venv/bin/activate

# Install Requirements
pip install -r requirements.txt
```

### 5. Run Migrations & Server
```bash
# Run Database Migrations
cd netbox
python3 manage.py migrate

# Create Superuser
python3 manage.py createsuperuser

# Start Development Server (For testing only - use Gunicorn/Nginx for Prod)
python3 manage.py runserver 0.0.0.0:8000
```

---

## 📦 Operational Management (Docker)

### View Status
Check running containers:
```bash
sudo docker compose -f docker-compose-netbox.yml ps
```

### View Logs
Troubleshoot issues by viewing logs:
```bash
# NetBox Logs
sudo docker compose -f docker-compose-netbox.yml logs -f netbox

# Nginx Logs
sudo docker compose -f docker-compose-netbox.yml logs -f nginx
```

### Stop Application
```bash
sudo docker compose -f docker-compose-netbox.yml down
```

### Backup Database
Manually trigger a database backup:
```bash
sudo docker compose -f docker-compose-netbox.yml exec postgres pg_dump -U netbox netbox > netbox_backup_$(date +%F).sql
```

---

## 📂 Repository Structure
*   `NetBox_Dev/`: Modified NetBox v3.7.8 source code (includes LDAP config).
*   `nginx-proxy/`: Nginx web server configuration and SSL certificates.
*   `docker-compose-netbox.yml`: NetBox stack configuration.