#!/bin/bash

# Generate package-lock.json for React frontend

echo "Generating package-lock.json for React frontend..."

cd "$(dirname "$0")"

# Remove any existing lock file
rm -f package-lock.json

# Generate fresh package-lock.json
npm install

echo "package-lock.json generated successfully!"
echo "Now you can build the Docker image."