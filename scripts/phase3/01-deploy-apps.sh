#!/bin/bash

# Application Deployment Script
# This script deploys all sample applications to the Kubernetes cluster

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
APPS_DIR="manifests/apps"
DOCKER_REGISTRY="jconover"  # Docker Hub username
USE_DOCKER_HUB=true  # Set to false for local images

print_header() {
    echo ""
    echo -e "${PURPLE}================================================================${NC}"
    echo -e "${WHITE}           Application Deployment Script${NC}"
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

    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed or not in PATH"
        exit 1
    fi
    print_success "kubectl is available"

    # Check if we can connect to cluster
    if ! kubectl cluster-info >/dev/null 2>&1; then
        print_error "Cannot connect to Kubernetes cluster"
        print_info "Make sure cluster is running and kubectl is configured"
        exit 1
    fi
    print_success "Connected to Kubernetes cluster"

    # Check if cluster is ready
    NOT_READY=$(kubectl get nodes --no-headers | grep -v Ready | wc -l)
    if [[ $NOT_READY -gt 0 ]]; then
        print_warning "$NOT_READY nodes are not ready"
        kubectl get nodes
        read -p "Do you want to continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_success "All cluster nodes are ready"
    fi

    # Check if Docker is available for building images
    if ! command -v docker &> /dev/null; then
        print_warning "Docker is not available - skipping image builds"
        print_info "Images must be pre-built or available in a registry"
    else
        print_success "Docker is available for image builds"
    fi
}

# Build and push Docker images to Docker Hub
build_docker_images() {
    print_section "Building and Pushing Docker Images"

    if [[ "$USE_DOCKER_HUB" == "true" ]]; then
        print_info "Using Docker Hub registry: $DOCKER_REGISTRY"

        if [[ -f "scripts/build-and-push.sh" ]]; then
            print_info "Running Docker Hub build and push script..."
            bash scripts/build-and-push.sh
            print_success "Images built and pushed to Docker Hub"
        else
            print_warning "Docker Hub script not found - falling back to local build"
            build_local_images
        fi
    else
        print_info "Building images locally..."
        build_local_images
    fi
}

# Build Docker images locally (fallback)
build_local_images() {
    if ! command -v docker &> /dev/null; then
        print_warning "Docker not available - skipping image builds"
        print_info "Make sure images are available in your registry"
        return
    fi

    # Python API
    if [[ -f "applications/python-api/Dockerfile" ]]; then
        print_info "Building Python API image..."
        docker build -t python-api:1.0.0 applications/python-api/
        print_success "Python API image built"
    fi

    # React Frontend
    if [[ -f "applications/react-frontend/Dockerfile" ]]; then
        print_info "Building React Frontend image..."
        docker build -t react-frontend:1.0.0 applications/react-frontend/
        print_success "React Frontend image built"
    fi

    # Java Service
    if [[ -f "applications/java-service/Dockerfile" ]]; then
        print_info "Building Java Service image..."
        docker build -t java-service:1.0.0 applications/java-service/
        print_success "Java Service image built"
    fi

    print_success "All images built successfully"
}

# Load images to cluster (only needed for local images)
load_images_to_cluster() {
    if [[ "$USE_DOCKER_HUB" == "true" ]]; then
        print_section "Using Docker Hub Images"
        print_info "Images will be pulled from Docker Hub registry"
        print_success "No image loading required - using registry images"
        return
    fi

    print_section "Loading Images to Cluster"

    # Check if using kind
    if kubectl config current-context | grep -q "kind"; then
        print_info "Detected kind cluster - loading images..."
        kind load docker-image python-api:1.0.0
        kind load docker-image react-frontend:1.0.0
        kind load docker-image java-service:1.0.0
        print_success "Images loaded to kind cluster"
        return
    fi

    # Check if using minikube
    if kubectl config current-context | grep -q "minikube"; then
        print_info "Detected minikube cluster - loading images..."
        minikube image load python-api:1.0.0
        minikube image load react-frontend:1.0.0
        minikube image load java-service:1.0.0
        print_success "Images loaded to minikube cluster"
        return
    fi

    # For standard kubeadm clusters, distribute images to all nodes
    print_info "Detected standard cluster - distributing images to all nodes..."
    if [[ -f "scripts/phase3/load-images-to-nodes.sh" ]]; then
        bash scripts/phase3/load-images-to-nodes.sh
        print_success "Images distributed to all cluster nodes"
    else
        print_warning "Image distribution script not found"
        print_info "Images must be accessible via registry or manually loaded on nodes"
        print_info "For kubeadm clusters, ensure images are available on all worker nodes"
    fi
}

# Deploy Python API
deploy_python_api() {
    print_section "Deploying Python API"

    print_info "Creating namespace and resources for Python API..."

    # Apply all Python API manifests
    kubectl apply -f $APPS_DIR/python-api/namespace.yaml
    kubectl apply -f $APPS_DIR/python-api/serviceaccount.yaml
    kubectl apply -f $APPS_DIR/python-api/configmap.yaml
    kubectl apply -f $APPS_DIR/python-api/deployment.yaml
    kubectl apply -f $APPS_DIR/python-api/service.yaml

    # Wait for deployment to be ready
    print_info "Waiting for Python API to be ready..."
    kubectl wait --for=condition=available deployment/python-api -n python-api --timeout=300s

    print_success "Python API deployed successfully"

    # Show status
    kubectl get pods -n python-api
}

# Deploy React Frontend
deploy_react_frontend() {
    print_section "Deploying React Frontend"

    print_info "Creating namespace and resources for React Frontend..."

    # Apply all React Frontend manifests
    kubectl apply -f $APPS_DIR/react-frontend/namespace.yaml
    kubectl apply -f $APPS_DIR/react-frontend/serviceaccount.yaml
    kubectl apply -f $APPS_DIR/react-frontend/deployment.yaml
    kubectl apply -f $APPS_DIR/react-frontend/service.yaml

    # Wait for deployment to be ready
    print_info "Waiting for React Frontend to be ready..."
    kubectl wait --for=condition=available deployment/react-frontend -n react-frontend --timeout=300s

    print_success "React Frontend deployed successfully"

    # Show status
    kubectl get pods -n react-frontend

    # Get NodePort
    FRONTEND_PORT=$(kubectl get svc react-frontend -n react-frontend -o jsonpath='{.spec.ports[0].nodePort}')
    print_info "Frontend accessible at: http://<any-node-ip>:$FRONTEND_PORT"
}

# Deploy Java Service
deploy_java_service() {
    print_section "Deploying Java Service"

    print_info "Creating namespace and resources for Java Service..."

    # Apply all Java Service manifests
    kubectl apply -f $APPS_DIR/java-service/namespace.yaml
    kubectl apply -f $APPS_DIR/java-service/serviceaccount.yaml
    kubectl apply -f $APPS_DIR/java-service/deployment.yaml
    kubectl apply -f $APPS_DIR/java-service/service.yaml

    # Wait for deployment to be ready
    print_info "Waiting for Java Service to be ready..."
    kubectl wait --for=condition=available deployment/java-service -n java-service --timeout=300s

    print_success "Java Service deployed successfully"

    # Show status
    kubectl get pods -n java-service
}

# Deploy with Helm (alternative)
deploy_with_helm() {
    print_section "Deploying Applications with Helm"

    if ! command -v helm &> /dev/null; then
        print_warning "Helm not installed - skipping Helm deployment"
        return
    fi

    print_info "Installing microservices platform with Helm..."

    # Install the Helm chart
    helm upgrade --install microservices-platform ./helm-charts/microservices-platform \
        --create-namespace \
        --namespace platform \
        --wait \
        --timeout 10m

    print_success "Applications deployed with Helm"

    # Show status
    helm list -n platform
    kubectl get pods -n platform
}

# Deploy with ArgoCD (GitOps)
deploy_with_argocd() {
    print_section "Setting up GitOps Deployment with ArgoCD"

    # Check if ArgoCD is installed
    if ! kubectl get namespace argocd >/dev/null 2>&1; then
        print_warning "ArgoCD not installed - skipping GitOps setup"
        return
    fi

    print_info "Creating ArgoCD applications..."

    # Apply ArgoCD application manifests
    if [[ -d "manifests/argocd/applications" ]]; then
        kubectl apply -f manifests/argocd/applications/
        print_success "ArgoCD applications created"

        print_info "Applications will sync from Git repository"
        print_info "Update repository URLs in manifests/argocd/applications/*.yaml to point to your Git repo"

        # List ArgoCD applications
        if command -v argocd &> /dev/null; then
            argocd app list
        fi
    else
        print_warning "ArgoCD application manifests not found"
    fi
}

# Verify deployments
verify_deployments() {
    print_section "Verifying Application Deployments"

    print_info "Checking application status..."

    # Check Python API
    echo ""
    echo -e "${CYAN}Python API:${NC}"
    kubectl get all -n python-api 2>/dev/null || echo "Not deployed"

    # Check React Frontend
    echo ""
    echo -e "${CYAN}React Frontend:${NC}"
    kubectl get all -n react-frontend 2>/dev/null || echo "Not deployed"

    # Check Java Service
    echo ""
    echo -e "${CYAN}Java Service:${NC}"
    kubectl get all -n java-service 2>/dev/null || echo "Not deployed"

    # Get service endpoints
    echo ""
    print_info "Service Endpoints:"

    # Python API endpoint
    PYTHON_API=$(kubectl get svc python-api -n python-api -o jsonpath='{.spec.clusterIP}:{.spec.ports[0].port}' 2>/dev/null)
    [[ -n "$PYTHON_API" ]] && echo "  Python API: http://$PYTHON_API"

    # React Frontend NodePort
    FRONTEND_PORT=$(kubectl get svc react-frontend -n react-frontend -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null)
    [[ -n "$FRONTEND_PORT" ]] && echo "  React Frontend: http://<node-ip>:$FRONTEND_PORT"

    # Java Service endpoint
    JAVA_SERVICE=$(kubectl get svc java-service -n java-service -o jsonpath='{.spec.clusterIP}:{.spec.ports[0].port}' 2>/dev/null)
    [[ -n "$JAVA_SERVICE" ]] && echo "  Java Service: http://$JAVA_SERVICE"
}

# Create test scripts
create_test_scripts() {
    print_section "Creating Application Test Scripts"

    # Create Python API test script
    cat > scripts/test-python-api.sh << 'EOF'
#!/bin/bash

# Python API Test Script

API_POD=$(kubectl get pod -n python-api -l app=python-api -o jsonpath='{.items[0].metadata.name}')
API_IP=$(kubectl get svc python-api -n python-api -o jsonpath='{.spec.clusterIP}')

echo "Testing Python API..."
echo "Pod: $API_POD"
echo "Service IP: $API_IP"
echo ""

# Test from inside cluster
echo "Testing health endpoint:"
kubectl exec -n python-api $API_POD -- curl -s http://localhost:8000/health | jq .

echo ""
echo "Testing API status:"
kubectl exec -n python-api $API_POD -- curl -s http://localhost:8000/api/status | jq .

echo ""
echo "Testing metrics endpoint:"
kubectl exec -n python-api $API_POD -- curl -s http://localhost:8000/metrics | head -20
EOF

    # Create React Frontend test script
    cat > scripts/test-react-frontend.sh << 'EOF'
#!/bin/bash

# React Frontend Test Script

FRONTEND_POD=$(kubectl get pod -n react-frontend -l app=react-frontend -o jsonpath='{.items[0].metadata.name}')
FRONTEND_PORT=$(kubectl get svc react-frontend -n react-frontend -o jsonpath='{.spec.ports[0].nodePort}')
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

echo "Testing React Frontend..."
echo "Pod: $FRONTEND_POD"
echo "NodePort: $FRONTEND_PORT"
echo "Access URL: http://$NODE_IP:$FRONTEND_PORT"
echo ""

# Test health endpoint
echo "Testing health endpoint:"
kubectl exec -n react-frontend $FRONTEND_POD -- curl -s http://localhost:3000/health

echo ""
echo "Open in browser: http://$NODE_IP:$FRONTEND_PORT"
EOF

    # Create Java Service test script
    cat > scripts/test-java-service.sh << 'EOF'
#!/bin/bash

# Java Service Test Script

JAVA_POD=$(kubectl get pod -n java-service -l app=java-service -o jsonpath='{.items[0].metadata.name}')
JAVA_IP=$(kubectl get svc java-service -n java-service -o jsonpath='{.spec.clusterIP}')

echo "Testing Java Service..."
echo "Pod: $JAVA_POD"
echo "Service IP: $JAVA_IP"
echo ""

# Test actuator health
echo "Testing actuator health:"
kubectl exec -n java-service $JAVA_POD -- curl -s http://localhost:8080/actuator/health | jq .

echo ""
echo "Testing API status:"
kubectl exec -n java-service $JAVA_POD -- curl -s http://localhost:8080/api/v1/status | jq .

echo ""
echo "Testing Prometheus metrics:"
kubectl exec -n java-service $JAVA_POD -- curl -s http://localhost:8080/actuator/prometheus | head -20
EOF

    chmod +x scripts/test-*.sh
    print_success "Test scripts created"
    print_info "Run './scripts/test-python-api.sh' to test Python API"
    print_info "Run './scripts/test-react-frontend.sh' to test React Frontend"
    print_info "Run './scripts/test-java-service.sh' to test Java Service"
}

# Main deployment menu
show_deployment_menu() {
    print_section "Deployment Options"

    echo "Choose deployment method:"
    echo "  1) Deploy with kubectl (manifests)"
    echo "  2) Deploy with Helm"
    echo "  3) Setup GitOps with ArgoCD"
    echo "  4) All of the above"
    echo ""
    read -p "Select option (1-4): " -n 1 -r
    echo ""

    case $REPLY in
        1)
            build_docker_images
            load_images_to_cluster
            deploy_python_api
            deploy_react_frontend
            deploy_java_service
            ;;
        2)
            deploy_with_helm
            ;;
        3)
            deploy_with_argocd
            ;;
        4)
            build_docker_images
            load_images_to_cluster
            deploy_python_api
            deploy_react_frontend
            deploy_java_service
            deploy_with_helm
            deploy_with_argocd
            ;;
        *)
            print_error "Invalid option"
            exit 1
            ;;
    esac
}

# Main execution
main() {
    print_header

    print_info "This script will deploy sample applications to your Kubernetes cluster"
    echo -e "${BLUE}Applications to deploy:${NC}"
    echo -e "  • Python API (FastAPI microservice)"
    echo -e "  • React Frontend (Web application)"
    echo -e "  • Java Service (Spring Boot)"
    echo ""

    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Operation cancelled"
        exit 1
    fi

    check_prerequisites
    show_deployment_menu
    verify_deployments
    create_test_scripts

    print_section "Application Deployment Complete!"
    print_success "🎉 All applications have been deployed!"

    if [[ "$USE_DOCKER_HUB" == "true" ]]; then
        print_info "🐳 Images pulled from Docker Hub: $DOCKER_REGISTRY/*"
        print_info "🔄 To update images, run: ./scripts/build-and-push.sh"
    fi

    print_info "📱 Frontend URL: http://<node-ip>:30080"
    print_info "🔍 Use test scripts in ./scripts/ to verify applications"
    print_info "📊 Check Grafana dashboards for application metrics"
    print_info "🔄 Use ArgoCD for GitOps-based continuous deployment"
    echo ""
}

# Execute main function
main "$@"