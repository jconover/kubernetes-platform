#!/bin/bash

# Quick build and push for Python API only
# Use this for testing fixes

set -e

# Configuration
DOCKER_USERNAME="jconover"
VERSION="1.0.0"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info "Building and pushing Python API..."

# Build the image
if docker build -t "$DOCKER_USERNAME/python-api:$VERSION" -t "$DOCKER_USERNAME/python-api:latest" applications/python-api/; then
    print_success "Python API image built successfully"
else
    print_error "Failed to build Python API image"
    exit 1
fi

# Push the image
if docker push "$DOCKER_USERNAME/python-api:$VERSION" && docker push "$DOCKER_USERNAME/python-api:latest"; then
    print_success "Python API pushed to Docker Hub"
    print_info "Image available at: $DOCKER_USERNAME/python-api:$VERSION"
else
    print_error "Failed to push Python API image"
    exit 1
fi

print_success "Python API build and push complete!"
echo "Now restart the deployment with:"
echo "kubectl rollout restart deployment/python-api -n python-api"