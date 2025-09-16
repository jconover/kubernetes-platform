#!/bin/bash

# Helm Package Manager Installation Script
# This script installs Helm on the local machine for Kubernetes package management

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

print_header() {
    echo ""
    echo -e "${PURPLE}================================================================${NC}"
    echo -e "${WHITE}           Helm Package Manager Installation${NC}"
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

# Check if Helm is already installed
check_existing_helm() {
    print_section "Checking Existing Helm Installation"

    if command -v helm &> /dev/null; then
        CURRENT_VERSION=$(helm version --short 2>/dev/null | cut -d":" -f2 | tr -d " ")
        print_info "Helm is already installed: $CURRENT_VERSION"

        read -p "Do you want to reinstall/update Helm? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Using existing Helm installation"
            verify_helm_installation
            exit 0
        fi
    else
        print_info "Helm not found, proceeding with installation"
    fi
}

# Install Helm
install_helm() {
    print_section "Installing Helm"

    print_info "Downloading Helm installation script..."

    # Download and run the official Helm installation script
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3

    print_info "Running Helm installation script..."
    chmod 700 get_helm.sh
    ./get_helm.sh

    # Clean up
    rm -f get_helm.sh

    print_success "Helm installation completed"
}

# Verify Helm installation
verify_helm_installation() {
    print_section "Verifying Helm Installation"

    # Check Helm version
    if command -v helm &> /dev/null; then
        HELM_VERSION=$(helm version --short 2>/dev/null)
        print_success "Helm is installed: $HELM_VERSION"
    else
        print_error "Helm installation failed"
        exit 1
    fi

    # Check Kubernetes connectivity
    if ! kubectl cluster-info >/dev/null 2>&1; then
        print_error "Cannot connect to Kubernetes cluster"
        print_info "Helm is installed but cannot connect to cluster"
        exit 1
    fi
    print_success "Connected to Kubernetes cluster"

    # Test Helm with cluster
    print_info "Testing Helm connectivity..."
    helm list --all-namespaces >/dev/null
    print_success "Helm can communicate with the cluster"
}

# Setup common Helm repositories
setup_helm_repos() {
    print_section "Setting up Common Helm Repositories"

    print_info "Adding popular Helm repositories..."

    # Add common repositories
    helm repo add stable https://charts.helm.sh/stable || print_warning "Stable repo already exists or failed to add"
    helm repo add bitnami https://charts.bitnami.com/bitnami || print_warning "Bitnami repo already exists or failed to add"
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || print_warning "Prometheus community repo already exists or failed to add"
    helm repo add grafana https://grafana.github.io/helm-charts || print_warning "Grafana repo already exists or failed to add"
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx || print_warning "Ingress-nginx repo already exists or failed to add"
    helm repo add jetstack https://charts.jetstack.io || print_warning "Jetstack repo already exists or failed to add"

    print_info "Updating Helm repositories..."
    helm repo update

    print_success "Helm repositories configured"

    # List configured repositories
    echo ""
    print_info "Configured Helm repositories:"
    helm repo list
}

# Create Helm utility scripts
create_helm_scripts() {
    print_section "Creating Helm Utility Scripts"

    # Create Helm status script
    cat > scripts/helm-status.sh << 'EOF'
#!/bin/bash

# Helm Status Script

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${WHITE}⚓ Helm Status Report${NC}"
echo -e "${WHITE}====================${NC}"
echo ""

echo -e "${CYAN}📦 Helm Version:${NC}"
helm version --short
echo ""

echo -e "${CYAN}📊 Installed Releases:${NC}"
helm list --all-namespaces
echo ""

echo -e "${CYAN}📁 Configured Repositories:${NC}"
helm repo list
echo ""

echo -e "${CYAN}🔍 Recent Helm History:${NC}"
echo "Use 'helm history <release-name>' for specific release history"
echo ""

echo -e "${GREEN}✅ Helm is operational!${NC}"
EOF

    chmod +x scripts/helm-status.sh

    # Create Helm search script
    cat > scripts/helm-search.sh << 'EOF'
#!/bin/bash

# Helm Chart Search Script

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ $# -eq 0 ]; then
    echo -e "${WHITE}🔍 Helm Chart Search Utility${NC}"
    echo -e "${WHITE}============================${NC}"
    echo ""
    echo -e "${BLUE}Usage:${NC} $0 <search-term>"
    echo ""
    echo -e "${BLUE}Examples:${NC}"
    echo -e "  $0 nginx"
    echo -e "  $0 postgres"
    echo -e "  $0 monitoring"
    echo ""
    exit 1
fi

SEARCH_TERM="$1"

echo -e "${CYAN}🔍 Searching for charts containing: ${YELLOW}$SEARCH_TERM${NC}"
echo -e "${CYAN}$(printf '%.0s─' $(seq 1 40))${NC}"
echo ""

helm search repo "$SEARCH_TERM"
echo ""

echo -e "${BLUE}💡 To get more info about a chart:${NC}"
echo -e "  helm show chart <chart-name>"
echo -e "  helm show values <chart-name>"
EOF

    chmod +x scripts/helm-search.sh

    # Create Helm cleanup script
    cat > scripts/helm-cleanup.sh << 'EOF'
#!/bin/bash

# Helm Cleanup Script

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${WHITE}🧹 Helm Cleanup Utility${NC}"
echo -e "${WHITE}=======================${NC}"
echo ""

echo -e "${CYAN}📊 Current Helm Releases:${NC}"
helm list --all-namespaces
echo ""

echo -e "${YELLOW}⚠️  This will show failed/pending releases that can be cleaned up${NC}"
echo ""

# Show failed releases
FAILED_RELEASES=$(helm list --all-namespaces --failed -q)
if [[ -n "$FAILED_RELEASES" ]]; then
    echo -e "${RED}❌ Failed Releases:${NC}"
    helm list --all-namespaces --failed
    echo ""
    echo -e "${BLUE}To clean up failed releases:${NC}"
    echo -e "  helm delete <release-name> -n <namespace>"
else
    echo -e "${GREEN}✅ No failed releases found${NC}"
fi
echo ""

# Show pending releases
PENDING_RELEASES=$(helm list --all-namespaces --pending -q)
if [[ -n "$PENDING_RELEASES" ]]; then
    echo -e "${YELLOW}⏳ Pending Releases:${NC}"
    helm list --all-namespaces --pending
    echo ""
    echo -e "${BLUE}To clean up pending releases:${NC}"
    echo -e "  helm delete <release-name> -n <namespace>"
else
    echo -e "${GREEN}✅ No pending releases found${NC}"
fi
echo ""

echo -e "${BLUE}💡 Useful cleanup commands:${NC}"
echo -e "  helm delete <release-name> -n <namespace>  # Delete a release"
echo -e "  helm repo update                           # Update repo cache"
echo -e "  helm repo remove <repo-name>               # Remove a repository"
EOF

    chmod +x scripts/helm-cleanup.sh

    print_success "Helm utility scripts created"
    print_info "Created scripts:"
    print_info "  • ./scripts/helm-status.sh - Show Helm status"
    print_info "  • ./scripts/helm-search.sh - Search for charts"
    print_info "  • ./scripts/helm-cleanup.sh - Cleanup failed releases"
}

# Create Helm values templates
create_helm_templates() {
    print_section "Creating Helm Values Templates"

    mkdir -p helm-charts/templates

    # Create a sample values template
    cat > helm-charts/templates/common-values.yaml << EOF
# Common Helm Values Template
# Copy and modify this template for your applications

# Common labels applied to all resources
commonLabels:
  app.kubernetes.io/part-of: kubernetes-platform
  app.kubernetes.io/managed-by: helm

# Image configuration
image:
  repository: ""
  pullPolicy: IfNotPresent
  tag: "latest"

# Service configuration
service:
  type: ClusterIP
  port: 80
  targetPort: 8080

# Ingress configuration
ingress:
  enabled: false
  className: ""
  annotations: {}
  hosts:
    - host: chart-example.local
      paths:
        - path: /
          pathType: Prefix
  tls: []

# Resource limits and requests
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

# Horizontal Pod Autoscaler
autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 100
  targetCPUUtilizationPercentage: 80

# Node selection
nodeSelector: {}
tolerations: []
affinity: {}

# Pod security context
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1001

# Container security context
securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop:
    - ALL
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1001
EOF

    print_success "Helm templates created"
    print_info "Template created: helm-charts/templates/common-values.yaml"
}

# Main execution
main() {
    print_header

    print_info "This script will install Helm package manager for Kubernetes"
    echo -e "${BLUE}Helm provides:${NC}"
    echo -e "  • Package management for Kubernetes applications"
    echo -e "  • Templating and configuration management"
    echo -e "  • Release lifecycle management"
    echo -e "  • Chart repositories for pre-built applications"
    echo ""

    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Operation cancelled"
        exit 1
    fi

    check_existing_helm
    install_helm
    verify_helm_installation
    setup_helm_repos
    create_helm_scripts
    create_helm_templates

    print_section "Helm Installation Complete!"
    print_success "🎉 Helm is now installed and configured!"
    print_info "⚓ Helm version: $(helm version --short 2>/dev/null)"
    print_info "📦 Run './scripts/helm-status.sh' to check Helm status"
    print_info "🔍 Run './scripts/helm-search.sh <term>' to search for charts"
    print_info "🧹 Run './scripts/helm-cleanup.sh' to cleanup failed releases"
    print_info "📁 Helm templates available in helm-charts/templates/"
    print_info "🔄 Ready for Phase 3: Application deployment"
    echo ""
}

# Execute main function
main "$@"