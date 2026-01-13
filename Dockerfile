FROM python:3.10-slim

WORKDIR /opt/netbox

# Install system dependencies required for building Python packages (psycopg, LDAP, etc.)
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    git \
    libldap2-dev \
    libsasl2-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
# Ensure we use the binary version of psycopg for easier docker build if not already set,
# or rely on the system libs installed above.
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Working directory for the application
WORKDIR /opt/netbox/netbox

EXPOSE 8000

CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]

