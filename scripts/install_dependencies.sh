#!/bin/bash

# Install dependencies script for CodeDeploy
echo "Installing system dependencies..."

# Update system packages
yum update -y

# Install Node.js and npm
curl -sL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# Install PM2 for process management
npm install -g pm2

# Create application directory if it doesn't exist
mkdir -p /var/www/html/devops-app

# Set proper ownership
chown -R ec2-user:ec2-user /var/www/html/devops-app

echo "Dependencies installed successfully!"
