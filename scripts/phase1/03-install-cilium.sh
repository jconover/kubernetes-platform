#!/bin/bash

# Cilium CNI Installation Script
# This script installs Cilium as the CNI plugin for advanced networking and security

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
CILIUM_VERSION="1.14.4"
CLUSTER_NAME="k8s-cluster"

print_header() {
    echo ""
    echo -e "${PURPLE}================================================================${NC}"
    echo -e "${WHITE}           Cilium CNI Installation${NC}"
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

    # Check cluster nodes
    NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)
    print_info "Found $NODE_COUNT nodes in the cluster"

    # Show current node status
    echo ""
    kubectl get nodes -o wide
}

# Install Cilium CLI
install_cilium_cli() {
    print_section "Installing Cilium CLI"

    # Check if cilium CLI already exists
    if command -v cilium &> /dev/null; then
        CURRENT_VERSION=$(cilium version --client | grep "cilium-cli" | awk '{print $2}')
        print_info "Cilium CLI already installed (version: $CURRENT_VERSION)"
        return
    fi

    print_info "Downloading and installing Cilium CLI..."

    # Detect architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        *) print_error "Unsupported architecture: $ARCH"; exit 1 ;;
    esac

    # Download and install
    curl -L --remote-name-all "https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-${ARCH}.tar.gz{,.sha256sum}"
    sha256sum --check cilium-linux-${ARCH}.tar.gz.sha256sum
    sudo tar xzvfC cilium-linux-${ARCH}.tar.gz /usr/local/bin
    rm cilium-linux-${ARCH}.tar.gz{,.sha256sum}

    print_success "Cilium CLI installed successfully"

    # Verify installation
    cilium version --client
}

# Install Cilium CNI
install_cilium_cni() {
    print_section "Installing Cilium CNI"

    print_info "Installing Cilium with advanced features..."

    # Create Cilium configuration
    cilium install \
        --version=$CILIUM_VERSION \
        --set cluster.name=$CLUSTER_NAME \
        --set ipam.mode=kubernetes \
        --set kubeProxyReplacement=partial \
        --set securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
        --set securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
        --set cgroup.autoMount.enabled=false \
        --set cgroup.hostRoot=/sys/fs/cgroup \
        --set hubble.relay.enabled=true \
        --set hubble.ui.enabled=true

    print_success "Cilium installation initiated"
}

# Wait for Cilium to be ready
wait_for_cilium() {
    print_section "Waiting for Cilium to be Ready"

    print_info "Waiting for Cilium pods to start..."

    # Wait for cilium daemonset to be ready
    kubectl wait --for=condition=ready pod -l k8s-app=cilium -n kube-system --timeout=300s

    print_success "Cilium pods are running"

    # Show Cilium status
    echo ""
    print_info "Cilium pod status:"
    kubectl get pods -n kube-system -l k8s-app=cilium -o wide
}

# Verify Cilium installation
verify_cilium() {
    print_section "Verifying Cilium Installation"

    print_info "Running Cilium status check..."

    # Run cilium status
    cilium status --wait

    print_info "Running Cilium connectivity test..."

    # Deploy connectivity test
    cilium connectivity test --test-concurrency=1

    print_success "Cilium connectivity test passed"
}

# Verify cluster networking
verify_cluster_networking() {
    print_section "Verifying Cluster Networking"

    print_info "Checking node status after CNI installation..."

    # Check nodes are now ready
    kubectl get nodes -o wide

    # Wait for all nodes to be ready
    echo ""
    print_info "Waiting for all nodes to be ready..."

    kubectl wait --for=condition=Ready nodes --all --timeout=300s

    print_success "All nodes are ready"

    # Show system pods
    echo ""
    print_info "System pods status:"
    kubectl get pods -n kube-system
}

# Enable Hubble (Cilium observability)
enable_hubble() {
    print_section "Enabling Hubble Observability"

    print_info "Hubble UI and Relay are already enabled during installation"

    # Wait for Hubble components
    kubectl wait --for=condition=available deployment/hubble-ui -n kube-system --timeout=300s
    kubectl wait --for=condition=available deployment/hubble-relay -n kube-system --timeout=300s

    print_success "Hubble components are ready"

    # Show Hubble status
    echo ""
    print_info "Hubble components:"
    kubectl get pods -n kube-system -l k8s-app=hubble

    # Create port-forward script for Hubble UI
    cat > scripts/hubble-ui.sh << 'EOF'
#!/bin/bash

echo "🔍 Starting Hubble UI port-forward..."
echo "📱 Access Hubble UI at: http://localhost:12000"
echo "Press Ctrl+C to stop"
echo ""

kubectl port-forward -n kube-system svc/hubble-ui 12000:80
EOF

    chmod +x scripts/hubble-ui.sh

    print_info "Created Hubble UI access script: ./scripts/hubble-ui.sh"
}

# Apply network policies demo
create_network_policy_demo() {
    print_section "Creating Network Policy Demo"

    print_info "Creating demo namespace and network policies..."

    # Create demo namespace and applications
    kubectl apply -f - << EOF
apiVersion: v1
kind: Namespace
metadata:
  name: cilium-demo
  labels:
    name: cilium-demo
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: cilium-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: nginx:1.21
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: cilium-demo
spec:
  selector:
    app: frontend
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: cilium-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: nginx:1.21
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: backend
  namespace: cilium-demo
spec:
  selector:
    app: backend
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-policy
  namespace: cilium-demo
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector: {}
    ports:
    - protocol: TCP
      port: 80
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 80
  - to: []
    ports:
    - protocol: UDP
      port: 53
EOF

    print_success "Network policy demo created in 'cilium-demo' namespace"

    # Wait for pods to be ready
    kubectl wait --for=condition=ready pod -l app=frontend -n cilium-demo --timeout=120s
    kubectl wait --for=condition=ready pod -l app=backend -n cilium-demo --timeout=120s

    print_info "Demo pods are ready - you can test network policies with Hubble"
}

# Create validation script
create_validation_script() {
    print_section "Creating Validation Script"

    cat > scripts/validate-cilium.sh << 'EOF'
#!/bin/bash

# Cilium Validation Script

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${WHITE}🔍 Cilium Validation Report${NC}"
echo -e "${WHITE}==========================${NC}"
echo ""

echo -e "${CYAN}📊 Cilium Status:${NC}"
cilium status
echo ""

echo -e "${CYAN}🏗️  Cilium Pods:${NC}"
kubectl get pods -n kube-system -l k8s-app=cilium -o wide
echo ""

echo -e "${CYAN}📡 Hubble Components:${NC}"
kubectl get pods -n kube-system -l k8s-app=hubble -o wide
echo ""

echo -e "${CYAN}🌐 Cluster Nodes:${NC}"
kubectl get nodes -o wide
echo ""

echo -e "${CYAN}🔒 Network Policies:${NC}"
kubectl get networkpolicies --all-namespaces
echo ""

echo -e "${CYAN}📋 Demo Applications:${NC}"
kubectl get pods -n cilium-demo 2>/dev/null || echo "Demo namespace not found"
echo ""

echo -e "${GREEN}✅ Cilium validation complete!${NC}"
echo ""
echo -e "${BLUE}💡 Tips:${NC}"
echo -e "  • Run './scripts/hubble-ui.sh' to access Hubble UI"
echo -e "  • Use 'cilium connectivity test' for network testing"
echo -e "  • Check 'cilium-demo' namespace for network policy examples"
EOF

    chmod +x scripts/validate-cilium.sh
    print_success "Cilium validation script created"
}

# Main execution
main() {
    print_header

    print_info "This script will install Cilium CNI with advanced networking features"
    echo -e "${BLUE}Features to be enabled:${NC}"
    echo -e "  • Advanced CNI networking"
    echo -e "  • Network policy enforcement"
    echo -e "  • Hubble observability platform"
    echo -e "  • Service mesh capabilities"
    echo -e "  • eBPF-based security"
    echo ""

    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Operation cancelled"
        exit 1
    fi

    check_prerequisites
    install_cilium_cli
    install_cilium_cni
    wait_for_cilium
    verify_cilium
    verify_cluster_networking
    enable_hubble
    create_network_policy_demo
    create_validation_script

    print_section "Cilium CNI Installation Complete!"
    print_success "🎉 Cilium is now installed and configured!"
    print_info "🌐 Your Kubernetes cluster now has advanced networking capabilities"
    print_info "📊 Run './scripts/validate-cilium.sh' to validate the installation"
    print_info "🔍 Run './scripts/hubble-ui.sh' to access the Hubble observability UI"
    print_info "🔄 Next step: Install platform services (run ./scripts/phase2/01-install-argocd.sh)"
    echo ""
}

# Execute main function
main "$@"