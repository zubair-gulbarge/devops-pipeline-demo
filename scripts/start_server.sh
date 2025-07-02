#!/bin/bash

# Start server script for CodeDeploy
echo "Starting application server..."

cd /var/www/html/devops-app

# Install application dependencies
npm install --production

# Stop any existing PM2 processes
pm2 stop all || true
pm2 delete all || true

# Start the application with PM2
pm2 start src/index.js --name "devops-app" --instances 2 --exec-mode cluster

# Save PM2 configuration
pm2 save

# Setup PM2 to start on boot
pm2 startup

echo "Application server started successfully!"
echo "Application is running on PM2 with cluster mode"
