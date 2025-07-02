#!/bin/bash

# Stop server script for CodeDeploy
echo "Stopping application server..."

# Stop PM2 processes
pm2 stop devops-app || true
pm2 delete devops-app || true

echo "Application server stopped successfully!"
