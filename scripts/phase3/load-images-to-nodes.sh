#!/bin/bash

# Script to load Docker images to all cluster nodes
# This is needed for kubeadm clusters where images need to be distributed

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Image list
IMAGES=(
    "python-api:1.0.0"
    "react-frontend:1.0.0"
    "java-service:1.0.0"
)

# Get SSH user from environment or default to current user
SSH_USER=${SSH_USER:-$(whoami)}

# Get all worker nodes
print_info "Getting cluster node information..."
NODES=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}')

if [[ -z "$NODES" ]]; then
    print_error "No nodes found in cluster"
    exit 1
fi

print_info "Found nodes: $NODES"

# Function to load image to a specific node
load_image_to_node() {
    local node_ip=$1
    local image=$2

    print_info "Loading $image to node $node_ip..."

    # Save image to tar file
    local image_file="/tmp/$(echo $image | tr ':' '_').tar"
    docker save -o "$image_file" "$image"

    if [[ ! -f "$image_file" ]]; then
        print_error "Failed to save image $image"
        return 1
    fi

    # Copy image to node and load it
    if scp -o StrictHostKeyChecking=no "$image_file" "$SSH_USER@$node_ip:/tmp/" >/dev/null 2>&1; then
        if ssh -o StrictHostKeyChecking=no "$SSH_USER@$node_ip" "sudo docker load -i $image_file && rm -f $image_file" >/dev/null 2>&1; then
            print_success "Loaded $image to $node_ip"
        else
            print_error "Failed to load image on $node_ip"
            return 1
        fi
    else
        print_error "Failed to copy image to $node_ip"
        return 1
    fi

    # Clean up local tar file
    rm -f "$image_file"
}

# Main execution
print_info "Starting image distribution to cluster nodes..."
echo ""

# Check if SSH keys are set up
print_info "Testing SSH connectivity to nodes..."
for node in $NODES; do
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$SSH_USER@$node" "echo 'SSH test successful'" >/dev/null 2>&1; then
        print_success "SSH to $node working"
    else
        print_error "SSH to $node failed"
        print_info "Make sure you have SSH key access to all nodes"
        print_info "Run: ssh-copy-id $SSH_USER@$node"
        exit 1
    fi
done

# Load images to all nodes
for image in "${IMAGES[@]}"; do
    print_info "Processing image: $image"

    # Check if image exists locally
    if ! docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "^$image$"; then
        print_warning "Image $image not found locally, skipping..."
        continue
    fi

    # Load to all nodes
    for node in $NODES; do
        load_image_to_node "$node" "$image"
    done

    echo ""
done

print_success "Image distribution complete!"
print_info "All nodes now have the application images available"