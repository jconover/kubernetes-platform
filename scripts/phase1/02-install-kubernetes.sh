#!/bin/bash

# Kubernetes Cluster Installation Script using kubeadm
# This script initializes the Kubernetes cluster and joins worker nodes

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

# Cluster configuration
MASTER_HOST="k8s-master-01"
MASTER_IP="192.168.68.86"
WORKER_HOSTS=("k8s-worker-01" "k8s-worker-02")
WORKER_IPS=("192.168.68.88" "192.168.68.83")
SSH_USER="justin"
KUBE_VERSION="1.34.0"
POD_CIDR="10.244.0.0/16"
SERVICE_CIDR="10.96.0.0/12"

print_header() {
    echo ""
    echo -e "${PURPLE}================================================================${NC}"
    echo -e "${WHITE}           Kubernetes Cluster Installation${NC}"
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

# Initialize master node
init_master_node() {
    print_section "Initializing Master Node"

    print_info "Initializing Kubernetes cluster on $MASTER_HOST..."

    # Create kubeadm init configuration
    cat > /tmp/kubeadm-init.yaml << EOF
apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: ${MASTER_IP}
  bindPort: 6443
nodeRegistration:
  criSocket: unix:///var/run/containerd/containerd.sock
---
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
kubernetesVersion: v${KUBE_VERSION}
controlPlaneEndpoint: ${MASTER_IP}:6443
networking:
  podSubnet: ${POD_CIDR}
  serviceSubnet: ${SERVICE_CIDR}
apiServer:
  certSANs:
  - ${MASTER_IP}
  - ${MASTER_HOST}
  - localhost
  - 127.0.0.1
etcd:
  local:
    dataDir: /var/lib/etcd
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
EOF

    # Copy config to master and initialize
    scp /tmp/kubeadm-init.yaml "$SSH_USER@$MASTER_IP:/tmp/"

    ssh "$SSH_USER@$MASTER_IP" "
        echo '🚀 Running kubeadm init...'
        sudo kubeadm init --config=/tmp/kubeadm-init.yaml --upload-certs

        echo '📝 Setting up kubectl for user...'
        mkdir -p \$HOME/.kube
        sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config
        sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config

        echo '🔍 Getting cluster info...'
        kubectl cluster-info

        echo '✅ Master node initialized successfully!'
    "

    print_success "Master node initialized"
    rm -f /tmp/kubeadm-init.yaml
}

# Get join command for worker nodes
get_join_command() {
    print_section "Generating Worker Join Command"

    print_info "Getting join command from master node..."

    JOIN_COMMAND=$(ssh "$SSH_USER@$MASTER_IP" "sudo kubeadm token create --print-join-command")

    if [[ -n "$JOIN_COMMAND" ]]; then
        print_success "Join command generated successfully"
        print_info "Command: $JOIN_COMMAND"
    else
        print_error "Failed to generate join command"
        exit 1
    fi
}

# Join worker nodes
join_worker_nodes() {
    print_section "Joining Worker Nodes to Cluster"

    for i in "${!WORKER_HOSTS[@]}"; do
        hostname=${WORKER_HOSTS[$i]}
        ip=${WORKER_IPS[$i]}

        print_info "Joining $hostname to the cluster..."

        ssh "$SSH_USER@$ip" "
            echo '🔗 Joining cluster...'
            sudo $JOIN_COMMAND

            echo '✅ Node joined successfully!'
        "

        print_success "$hostname joined the cluster"
    done
}

# Copy kubectl config locally
setup_local_kubectl() {
    print_section "Setting up Local kubectl Configuration"

    print_info "Copying kubectl configuration locally..."

    # Create local .kube directory
    mkdir -p ~/.kube

    # Copy config from master
    scp "$SSH_USER@$MASTER_IP:~/.kube/config" ~/.kube/config

    # Update server address to use master IP
    sed -i "s/server: https:\/\/.*:6443/server: https:\/\/$MASTER_IP:6443/" ~/.kube/config

    print_success "kubectl configured locally"

    # Test connection
    echo ""
    print_info "Testing kubectl connection..."
    kubectl get nodes -o wide
}

# Verify cluster status
verify_cluster() {
    print_section "Verifying Cluster Status"

    print_info "Checking cluster components..."

    # Check nodes
    echo -e "${CYAN}📋 Cluster Nodes:${NC}"
    kubectl get nodes -o wide

    # Check system pods
    echo ""
    echo -e "${CYAN}🏗️  System Pods:${NC}"
    kubectl get pods -n kube-system

    # Check cluster info
    echo ""
    echo -e "${CYAN}ℹ️  Cluster Information:${NC}"
    kubectl cluster-info

    # Check component status
    echo ""
    echo -e "${CYAN}🏥 Component Status:${NC}"
    kubectl get componentstatuses 2>/dev/null || echo "Component status not available (normal in newer versions)"

    print_success "Cluster verification complete"
}

# Apply RBAC and initial configurations
apply_initial_configs() {
    print_section "Applying Initial Configurations"

    print_info "Creating necessary RBAC configurations..."

    # Create cluster-admin service account for ArgoCD
    kubectl apply -f - << EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: argocd-server
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: argocd-server
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: argocd-server
  namespace: kube-system
EOF

    print_success "Initial configurations applied"
}

# Create cluster info script
create_cluster_info_script() {
    print_section "Creating Cluster Info Script"

    cat > scripts/cluster-info.sh << 'EOF'
#!/bin/bash

# Kubernetes Cluster Information Script

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

echo -e "${WHITE}🏗️  Kubernetes Cluster Information${NC}"
echo -e "${WHITE}=================================${NC}"
echo ""

echo -e "${CYAN}📋 Nodes:${NC}"
kubectl get nodes -o wide
echo ""

echo -e "${CYAN}🏗️  System Pods:${NC}"
kubectl get pods -n kube-system
echo ""

echo -e "${CYAN}📊 Resource Usage:${NC}"
kubectl top nodes 2>/dev/null || echo "Metrics server not installed yet"
echo ""

echo -e "${CYAN}🔧 Cluster Info:${NC}"
kubectl cluster-info
echo ""

echo -e "${CYAN}💾 Storage Classes:${NC}"
kubectl get storageclass
echo ""

echo -e "${CYAN}🌐 Services:${NC}"
kubectl get svc --all-namespaces
echo ""

echo -e "${GREEN}✅ Cluster is ready!${NC}"
EOF

    chmod +x scripts/cluster-info.sh
    print_success "Cluster info script created"
}

# Main execution
main() {
    print_header

    print_info "This script will initialize a Kubernetes cluster using kubeadm"
    echo -e "${BLUE}Configuration:${NC}"
    echo -e "  Master: $MASTER_HOST ($MASTER_IP)"
    echo -e "  Workers: ${WORKER_HOSTS[*]}"
    echo -e "  Kubernetes Version: $KUBE_VERSION"
    echo -e "  Pod CIDR: $POD_CIDR"
    echo -e "  Service CIDR: $SERVICE_CIDR"
    echo ""

    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Operation cancelled"
        exit 1
    fi

    init_master_node
    get_join_command
    join_worker_nodes
    setup_local_kubectl
    apply_initial_configs
    verify_cluster
    create_cluster_info_script

    print_section "Kubernetes Cluster Installation Complete!"
    print_success "Cluster is now ready!"
    print_info "✨ Cluster has 1 master and ${#WORKER_HOSTS[@]} worker nodes"
    print_info "📋 Run './scripts/cluster-info.sh' to see cluster status"
    print_info "🔄 Next step: Install CNI (run ./scripts/phase1/03-install-cilium.sh)"
    print_warning "⚠️  Note: Nodes will be in 'NotReady' state until CNI is installed"
    echo ""
}

# Execute main function
main "$@"