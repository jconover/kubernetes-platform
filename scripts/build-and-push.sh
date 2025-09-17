#!/bin/bash

# Build and Push Docker Images to Docker Hub
# This script builds all application images and pushes them to Docker Hub

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

# Configuration
DOCKER_USERNAME="jconover"
VERSION="1.0.0"
LATEST_TAG="latest"

# Application directories
APPS=(
    "python-api"
    "react-frontend"
    "java-service"
)

print_header() {
    echo ""
    echo -e "${PURPLE}================================================================${NC}"
    echo -e "${WHITE}        Docker Hub Build and Push Script${NC}"
    echo -e "${PURPLE}================================================================${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${CYAN}▶ $1${NC}"
    echo -e "${CYAN}$(printf '%.0s─' $(seq 1 ${#1}))${NC}"
}

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

# Check prerequisites
check_prerequisites() {
    print_section "Checking Prerequisites"

    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi
    print_success "Docker is available"

    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker daemon is not running"
        print_info "Start Docker and try again"
        exit 1
    fi
    print_success "Docker daemon is running"

    # Check if logged into Docker Hub
    if ! docker info | grep -q "Username: $DOCKER_USERNAME"; then
        print_warning "Not logged into Docker Hub"
        print_info "Please log in with: docker login"
        read -p "Do you want to log in now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker login
        else
            print_error "Docker Hub login required"
            exit 1
        fi
    else
        print_success "Logged into Docker Hub as $DOCKER_USERNAME"
    fi
}

# Build single application
build_app() {
    local app=$1
    local app_dir="applications/$app"

    print_info "Building $app..."

    if [[ ! -f "$app_dir/Dockerfile" ]]; then
        print_error "Dockerfile not found for $app at $app_dir/Dockerfile"
        return 1
    fi

    # Build the image
    local image_name="$DOCKER_USERNAME/$app"

    if docker build -t "$image_name:$VERSION" -t "$image_name:$LATEST_TAG" "$app_dir/"; then
        print_success "$app image built successfully"
        return 0
    else
        print_error "Failed to build $app image"
        return 1
    fi
}

# Push single application
push_app() {
    local app=$1
    local image_name="$DOCKER_USERNAME/$app"

    print_info "Pushing $app to Docker Hub..."

    # Push both version and latest tags
    if docker push "$image_name:$VERSION" && docker push "$image_name:$LATEST_TAG"; then
        print_success "$app pushed successfully to Docker Hub"
        print_info "Available at: https://hub.docker.com/r/$DOCKER_USERNAME/$app"
        return 0
    else
        print_error "Failed to push $app"
        return 1
    fi
}

# Build all applications
build_all_apps() {
    print_section "Building Application Images"

    local failed_builds=()

    for app in "${APPS[@]}"; do
        if build_app "$app"; then
            print_success "$app build completed"
        else
            failed_builds+=("$app")
            print_error "$app build failed"
        fi
        echo ""
    done

    if [[ ${#failed_builds[@]} -gt 0 ]]; then
        print_error "Failed to build: ${failed_builds[*]}"
        return 1
    fi

    print_success "All applications built successfully"
}

# Push all applications
push_all_apps() {
    print_section "Pushing Images to Docker Hub"

    local failed_pushes=()

    for app in "${APPS[@]}"; do
        if push_app "$app"; then
            print_success "$app push completed"
        else
            failed_pushes+=("$app")
            print_error "$app push failed"
        fi
        echo ""
    done

    if [[ ${#failed_pushes[@]} -gt 0 ]]; then
        print_error "Failed to push: ${failed_pushes[*]}"
        return 1
    fi

    print_success "All applications pushed successfully"
}

# Show image information
show_image_info() {
    print_section "Docker Hub Images"

    print_info "Your images are now available at:"
    for app in "${APPS[@]}"; do
        echo "  📦 $DOCKER_USERNAME/$app:$VERSION"
        echo "  📦 $DOCKER_USERNAME/$app:$LATEST_TAG"
        echo "  🔗 https://hub.docker.com/r/$DOCKER_USERNAME/$app"
        echo ""
    done

    print_info "Kubernetes deployments will pull from:"
    for app in "${APPS[@]}"; do
        echo "  image: $DOCKER_USERNAME/$app:$VERSION"
    done
}

# Clean up local images (optional)
cleanup_local_images() {
    print_section "Cleanup Options"

    read -p "Do you want to remove local images to save space? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Removing local images..."
        for app in "${APPS[@]}"; do
            docker rmi "$DOCKER_USERNAME/$app:$VERSION" "$DOCKER_USERNAME/$app:$LATEST_TAG" 2>/dev/null || true
            print_info "Removed local images for $app"
        done
        print_success "Local images cleaned up"
    else
        print_info "Keeping local images"
    fi
}

# Main execution
main() {
    print_header

    print_info "This script will build and push all application images to Docker Hub"
    echo -e "${BLUE}Docker Hub username: ${WHITE}$DOCKER_USERNAME${NC}"
    echo -e "${BLUE}Version tag: ${WHITE}$VERSION${NC}"
    echo -e "${BLUE}Applications: ${WHITE}${APPS[*]}${NC}"
    echo ""

    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Operation cancelled"
        exit 1
    fi

    check_prerequisites
    build_all_apps
    push_all_apps
    show_image_info
    cleanup_local_images

    print_section "Build and Push Complete!"
    print_success "🎉 All images are now available on Docker Hub!"
    print_info "🚀 You can now deploy to Kubernetes using: ./scripts/phase3/01-deploy-apps.sh"
    echo ""
}

# Execute main function
main "$@"