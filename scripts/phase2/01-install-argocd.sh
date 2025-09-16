#!/bin/bash

# ArgoCD GitOps Installation Script
# This script installs ArgoCD for GitOps-based application deployment

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
ARGOCD_VERSION="v2.8.4"
ARGOCD_NAMESPACE="argocd"

print_header() {
    echo ""
    echo -e "${PURPLE}================================================================${NC}"
    echo -e "${WHITE}           ArgoCD GitOps Platform Installation${NC}"
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

    # Check if kubectl is available and connected
    if ! kubectl cluster-info >/dev/null 2>&1; then
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    print_success "Connected to Kubernetes cluster"

    # Check if nodes are ready
    NOT_READY=$(kubectl get nodes --no-headers | grep -v Ready | wc -l)
    if [[ $NOT_READY -gt 0 ]]; then
        print_error "$NOT_READY nodes are not ready"
        kubectl get nodes
        exit 1
    fi
    print_success "All cluster nodes are ready"

    # Check if CNI is installed (pods should be running)
    SYSTEM_PODS_NOT_READY=$(kubectl get pods -n kube-system --no-headers | grep -v Running | grep -v Completed | wc -l)
    if [[ $SYSTEM_PODS_NOT_READY -gt 0 ]]; then
        print_warning "Some system pods are not ready - ArgoCD may have issues"
        kubectl get pods -n kube-system | grep -v Running | grep -v Completed || true
    else
        print_success "All system pods are running"
    fi
}

# Create ArgoCD namespace and install
install_argocd() {
    print_section "Installing ArgoCD"

    # Create namespace
    print_info "Creating ArgoCD namespace..."
    kubectl create namespace $ARGOCD_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

    # Install ArgoCD
    print_info "Installing ArgoCD $ARGOCD_VERSION..."
    kubectl apply -n $ARGOCD_NAMESPACE -f https://raw.githubusercontent.com/argoproj/argo-cd/$ARGOCD_VERSION/manifests/install.yaml

    print_success "ArgoCD installation manifests applied"
}

# Wait for ArgoCD to be ready
wait_for_argocd() {
    print_section "Waiting for ArgoCD to be Ready"

    print_info "Waiting for ArgoCD pods to start..."

    # Wait for deployments to be available
    kubectl wait --for=condition=available deployment/argocd-server -n $ARGOCD_NAMESPACE --timeout=600s
    kubectl wait --for=condition=available deployment/argocd-repo-server -n $ARGOCD_NAMESPACE --timeout=600s
    kubectl wait --for=condition=available deployment/argocd-dex-server -n $ARGOCD_NAMESPACE --timeout=600s

    print_success "ArgoCD deployments are ready"

    # Show ArgoCD pods status
    echo ""
    print_info "ArgoCD pods status:"
    kubectl get pods -n $ARGOCD_NAMESPACE -o wide
}

# Configure ArgoCD service for external access
configure_argocd_service() {
    print_section "Configuring ArgoCD Service Access"

    # Patch ArgoCD server service to NodePort for easier access
    print_info "Configuring ArgoCD server service..."

    kubectl patch svc argocd-server -n $ARGOCD_NAMESPACE -p '{"spec":{"type":"NodePort"}}'

    # Get the NodePort
    ARGOCD_PORT=$(kubectl get svc argocd-server -n $ARGOCD_NAMESPACE -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
    MASTER_IP="192.168.68.86"

    print_success "ArgoCD server configured with NodePort: $ARGOCD_PORT"
    print_info "ArgoCD UI will be accessible at: https://$MASTER_IP:$ARGOCD_PORT"
}

# Get ArgoCD admin password
get_argocd_password() {
    print_section "Retrieving ArgoCD Admin Password"

    print_info "Getting initial admin password..."

    # Get the initial admin password
    ARGOCD_PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n $ARGOCD_NAMESPACE -o jsonpath="{.data.password}" | base64 -d)

    print_success "ArgoCD admin password retrieved"

    # Create credentials file
    cat > argocd-credentials.txt << EOF
ArgoCD Admin Credentials
========================
Username: admin
Password: $ARGOCD_PASSWORD

Access URL: https://192.168.68.86:$ARGOCD_PORT

Note: Accept the self-signed certificate warning in your browser.
EOF

    print_info "Credentials saved to argocd-credentials.txt"
}

# Install ArgoCD CLI
install_argocd_cli() {
    print_section "Installing ArgoCD CLI"

    # Check if argocd CLI already exists
    if command -v argocd &> /dev/null; then
        CURRENT_VERSION=$(argocd version --client | grep "argocd:" | awk '{print $2}')
        print_info "ArgoCD CLI already installed (version: $CURRENT_VERSION)"
        return
    fi

    print_info "Downloading and installing ArgoCD CLI..."

    # Download and install ArgoCD CLI
    curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
    rm argocd-linux-amd64

    print_success "ArgoCD CLI installed successfully"

    # Verify installation
    argocd version --client
}

# Create ArgoCD application manifests directory
setup_argocd_apps() {
    print_section "Setting up ArgoCD Applications Structure"

    # Create ArgoCD applications directory structure
    mkdir -p manifests/argocd/applications
    mkdir -p manifests/argocd/projects
    mkdir -p manifests/argocd/repositories

    # Create default AppProject
    cat > manifests/argocd/projects/default-project.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: default-project
  namespace: argocd
spec:
  description: Default project for applications
  sourceRepos:
  - '*'
  destinations:
  - namespace: '*'
    server: https://kubernetes.default.svc
  clusterResourceWhitelist:
  - group: '*'
    kind: '*'
  namespaceResourceWhitelist:
  - group: '*'
    kind: '*'
EOF

    # Create monitoring namespace application
    cat > manifests/argocd/applications/monitoring-app.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: monitoring-stack
  namespace: argocd
spec:
  project: default-project
  source:
    repoURL: https://github.com/your-username/kubernetes-platform.git
    targetRevision: HEAD
    path: manifests/monitoring
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

    # Create applications for our demo apps
    cat > manifests/argocd/applications/python-api-app.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: python-api
  namespace: argocd
spec:
  project: default-project
  source:
    repoURL: https://github.com/your-username/kubernetes-platform.git
    targetRevision: HEAD
    path: manifests/apps/python-api
  destination:
    server: https://kubernetes.default.svc
    namespace: python-api
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

    cat > manifests/argocd/applications/react-frontend-app.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: react-frontend
  namespace: argocd
spec:
  project: default-project
  source:
    repoURL: https://github.com/your-username/kubernetes-platform.git
    targetRevision: HEAD
    path: manifests/apps/react-frontend
  destination:
    server: https://kubernetes.default.svc
    namespace: react-frontend
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

    cat > manifests/argocd/applications/java-service-app.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: java-service
  namespace: argocd
spec:
  project: default-project
  source:
    repoURL: https://github.com/your-username/kubernetes-platform.git
    targetRevision: HEAD
    path: manifests/apps/java-service
  destination:
    server: https://kubernetes.default.svc
    namespace: java-service
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

    print_success "ArgoCD application manifests created"
    print_info "Application manifests created in manifests/argocd/applications/"
    print_warning "Update the repoURL in application manifests to point to your GitHub repository"
}

# Create ArgoCD access scripts
create_access_scripts() {
    print_section "Creating ArgoCD Access Scripts"

    # Create ArgoCD UI access script
    cat > scripts/argocd-ui.sh << EOF
#!/bin/bash

# ArgoCD UI Access Script

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

MASTER_IP="192.168.68.86"
ARGOCD_PORT=\$(kubectl get svc argocd-server -n argocd -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')

echo -e "\${BLUE}🚀 ArgoCD UI Access Information\${NC}"
echo -e "\${BLUE}==============================\${NC}"
echo ""
echo -e "📱 Access URL: \${GREEN}https://\$MASTER_IP:\$ARGOCD_PORT\${NC}"
echo ""
echo -e "\${YELLOW}Credentials:\${NC}"
echo -e "  Username: admin"
echo -e "  Password: \$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d)"
echo ""
echo -e "\${YELLOW}Note:\${NC} Accept the self-signed certificate warning in your browser"
echo ""
echo -e "\${BLUE}💡 Quick Actions:\${NC}"
echo -e "  • Port-forward: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo -e "  • Then access: https://localhost:8080"
EOF

    chmod +x scripts/argocd-ui.sh

    # Create ArgoCD CLI login script
    cat > scripts/argocd-login.sh << EOF
#!/bin/bash

# ArgoCD CLI Login Script

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

MASTER_IP="192.168.68.86"
ARGOCD_PORT=\$(kubectl get svc argocd-server -n argocd -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
ARGOCD_PASSWORD=\$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d)

echo -e "\${BLUE}🔐 Logging into ArgoCD CLI\${NC}"
echo -e "\${BLUE}=========================\${NC}"
echo ""

echo -e "\${YELLOW}Logging in to ArgoCD server...\${NC}"
argocd login \$MASTER_IP:\$ARGOCD_PORT --username admin --password \$ARGOCD_PASSWORD --insecure

echo ""
echo -e "\${GREEN}✅ Successfully logged in to ArgoCD!\${NC}"
echo ""
echo -e "\${BLUE}💡 Available commands:\${NC}"
echo -e "  • argocd app list"
echo -e "  • argocd app get <app-name>"
echo -e "  • argocd app sync <app-name>"
echo -e "  • argocd cluster list"
EOF

    chmod +x scripts/argocd-login.sh

    print_success "ArgoCD access scripts created"
    print_info "Use './scripts/argocd-ui.sh' to get UI access information"
    print_info "Use './scripts/argocd-login.sh' to login with ArgoCD CLI"
}

# Verify ArgoCD installation
verify_argocd() {
    print_section "Verifying ArgoCD Installation"

    print_info "Checking ArgoCD components..."

    # Check all ArgoCD pods are running
    kubectl get pods -n $ARGOCD_NAMESPACE

    # Check services
    echo ""
    print_info "ArgoCD services:"
    kubectl get svc -n $ARGOCD_NAMESPACE

    # Get NodePort info
    ARGOCD_PORT=$(kubectl get svc argocd-server -n $ARGOCD_NAMESPACE -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
    MASTER_IP="192.168.68.86"

    print_success "ArgoCD installation verified"

    echo ""
    print_info "🎉 ArgoCD is ready!"
    print_info "📱 UI Access: https://$MASTER_IP:$ARGOCD_PORT"
    print_info "🔑 Username: admin"
    print_info "🔑 Password: $(kubectl get secret argocd-initial-admin-secret -n $ARGOCD_NAMESPACE -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || echo "Run './scripts/argocd-ui.sh' to get password")"
}

# Main execution
main() {
    print_header

    print_info "This script will install ArgoCD for GitOps-based application deployment"
    echo -e "${BLUE}ArgoCD Features:${NC}"
    echo -e "  • GitOps continuous delivery"
    echo -e "  • Declarative application management"
    echo -e "  • Multi-cluster deployment support"
    echo -e "  • Web UI for application monitoring"
    echo -e "  • CLI for automation"
    echo ""

    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Operation cancelled"
        exit 1
    fi

    check_prerequisites
    install_argocd
    wait_for_argocd
    configure_argocd_service
    get_argocd_password
    install_argocd_cli
    setup_argocd_apps
    create_access_scripts
    verify_argocd

    print_section "ArgoCD Installation Complete!"
    print_success "🎉 ArgoCD is now installed and configured!"
    print_info "📋 Run './scripts/argocd-ui.sh' to get UI access information"
    print_info "🔐 Run './scripts/argocd-login.sh' to login with CLI"
    print_info "📁 Application manifests are in manifests/argocd/applications/"
    print_info "🔄 Next step: Install monitoring stack (run ./scripts/phase2/02-install-monitoring.sh)"
    echo ""
}

# Execute main function
main "$@"