#!/bin/bash

# Validate service script for CodeDeploy
echo "Validating application service..."

# Wait for the application to start
sleep 10

# Check if the application is responding
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health)

if [ $RESPONSE -eq 200 ]; then
    echo "Application is healthy and responding!"
    pm2 list
    exit 0
else
    echo "Application health check failed. HTTP status: $RESPONSE"
    pm2 logs --lines 20
    exit 1
fi
