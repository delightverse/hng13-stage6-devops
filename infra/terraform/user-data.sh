#!/bin/bash

set -e

echo "Starting server initialization..."

# Set hostname
hostnamectl set-hostname ${hostname}

# Update package list
apt-get update -y

# Install basic utilities
apt-get install -y \
    curl \
    wget \
    git \
    vim \
    htop \
    net-tools \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Configure timezone
timedatectl set-timezone UTC

# Enable firewall
ufw --force enable
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp

# System optimizations
cat >> /etc/security/limits.conf <<EOF
* soft nofile 65536
* hard nofile 65536
EOF

cat >> /etc/sysctl.conf <<EOF
net.core.somaxconn = 1024
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.ip_local_port_range = 1024 65535
EOF

sysctl -p

echo "Server initialization complete!"
