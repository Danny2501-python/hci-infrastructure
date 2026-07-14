#!/bin/bash
# Script to setup local directory for PostgreSQL Local PV on Kubernetes node

echo "Creating local directory for PostgreSQL..."
sudo mkdir -p /mnt/data/postgresql

echo "Setting permissions (PostgreSQL runs as UID 999)..."
sudo chown -R 999:999 /mnt/data/postgresql
sudo chmod -R 700 /mnt/data/postgresql

echo "Verifying directory..."
ls -la /mnt/data/

echo "✅ Local PV directory ready at /mnt/data/postgresql"
