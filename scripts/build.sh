#!/bin/bash

# Build script for DevOps Pipeline Demo
set -e

echo "Starting build process..."

# Install dependencies
echo "Installing dependencies..."
npm install

# Run tests
echo "Running tests..."
npm test

# Build application
echo "Building application..."
npm run build

# Create build artifacts
echo "Creating build artifacts..."
mkdir -p dist
cp -r src/* dist/
cp package.json dist/
cp package-lock.json dist/

echo "Build completed successfully!"
echo "Build artifacts available in dist/ directory"
