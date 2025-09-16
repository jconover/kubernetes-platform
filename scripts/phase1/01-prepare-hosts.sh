#!/bin/bash

# Kubernetes Cluster Host Preparation Script
# This script prepares all hosts for Kubernetes installation

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

# Hosts configuration
declare -A HOSTS=(
    ["k8s-master-01"]="192.168.68.86"
    ["k8s-worker-01"]="192.168.68.88"
    ["k8s-worker-02"]="192.168.68.83"
)

# SSH user (adjust as needed)
SSH_USER="justin"

print_header() {
    echo ""
    echo -e "${PURPLE}================================================================${NC}"
    echo -e "${WHITE}           Kubernetes Host Preparation Script${NC}"
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

# Check if we can SSH to all hosts
check_ssh_connectivity() {
    print_section "Checking SSH Connectivity"

    local local_ip
    local_ip=$(hostname -I | awk '{print $1}')
    for hostname in "${!HOSTS[@]}"; do
        ip=${HOSTS[$hostname]}
        echo -n "Checking SSH to $hostname ($ip)... "

        # Skip SSH check if this is the local host
        if [[ "$ip" == "$local_ip" ]]; then
            print_success "(local) Skipped"
            continue
        fi

        if ssh -o ConnectTimeout=5 -o BatchMode=yes "$SSH_USER@$ip" "echo 'SSH OK'" >/dev/null 2>&1; then
            print_success "Connected"
        else
            print_error "Cannot connect to $hostname ($ip)"
            echo -e "${RED}Please ensure SSH keys are configured and hosts are accessible${NC}"
            exit 1
        fi
    done
}

# Check and update hosts file on all nodes
setup_hosts_file() {
    print_section "Setting up /etc/hosts file on all nodes"

    # Create temporary hosts file
    cat > /tmp/k8s-hosts << EOF
# Kubernetes cluster hosts
192.168.68.86 k8s-master-01
192.168.68.88 k8s-worker-01
192.168.68.83 k8s-worker-02
EOF

    for hostname in "${!HOSTS[@]}"; do
        ip=${HOSTS[$hostname]}
        print_info "Updating hosts file on $hostname..."

        # Backup existing hosts file and add our entries
        ssh "$SSH_USER@$ip" "
            sudo cp /etc/hosts /etc/hosts.backup.$(date +%Y%m%d-%H%M%S)

            # Remove any existing k8s entries
            sudo sed -i '/# Kubernetes cluster hosts/,+3d' /etc/hosts

            # Add our entries
            echo '' | sudo tee -a /etc/hosts
            cat << 'HOSTS_EOF' | sudo tee -a /etc/hosts
# Kubernetes cluster hosts
192.168.68.86 k8s-master-01
192.168.68.88 k8s-worker-01
192.168.68.83 k8s-worker-02
HOSTS_EOF
        "

        print_success "Hosts file updated on $hostname"
    done

    rm -f /tmp/k8s-hosts
}

# System prerequisites check and setup
setup_prerequisites() {
    print_section "Setting up system prerequisites"

    for hostname in "${!HOSTS[@]}"; do
        ip=${HOSTS[$hostname]}
        print_info "Configuring prerequisites on $hostname..."

        ssh "$SSH_USER@$ip" "
            # Update system
            sudo apt-get update -qq

            # Install required packages
            sudo apt-get install -y -qq \
                apt-transport-https \
                ca-certificates \
                curl \
                gnupg \
                lsb-release \
                software-properties-common

            # Disable swap
            echo '📝 Disabling swap...'
            sudo swapoff -a
            sudo sed -i '/ swap / s/^/#/' /etc/fstab

            # Load required kernel modules
            echo '🔧 Loading kernel modules...'
            cat << 'MODULES_EOF' | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
overlay
MODULES_EOF

            sudo modprobe br_netfilter
            sudo modprobe overlay

            # Set kernel parameters
            echo '⚙️  Setting kernel parameters...'
            cat << 'SYSCTL_EOF' | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
SYSCTL_EOF

            sudo sysctl --system >/dev/null

            echo '✅ Prerequisites configured successfully'
        "

        print_success "Prerequisites configured on $hostname"
    done
}

# Install Docker/containerd
install_containerd() {
    print_section "Installing containerd runtime"

    for hostname in "${!HOSTS[@]}"; do
        ip=${HOSTS[$hostname]}
        print_info "Installing containerd on $hostname..."

        ssh "$SSH_USER@$ip" "
            # Add Docker repository
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

            echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

            # Install containerd
            sudo apt-get update -qq
            sudo apt-get install -y -qq containerd.io

            # Configure containerd
            sudo mkdir -p /etc/containerd
            containerd config default | sudo tee /etc/containerd/config.toml >/dev/null

            # Enable systemd cgroup driver
            sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

            # Start and enable containerd
            sudo systemctl restart containerd
            sudo systemctl enable containerd

            echo '✅ containerd installed and configured'
        "

        print_success "containerd installed on $hostname"
    done
}

# Install kubeadm, kubelet, kubectl
install_kubernetes_tools() {
    print_section "Installing Kubernetes tools (kubeadm, kubelet, kubectl)"

    for hostname in "${!HOSTS[@]}"; do
        ip=${HOSTS[$hostname]}
        print_info "Installing Kubernetes tools on $hostname..."

        ssh "$SSH_USER@$ip" "
            # Add Kubernetes repository
            curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

            echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

            # Install Kubernetes tools
            sudo apt-get update -qq
            sudo apt-get install -y -qq kubelet=1.33.* kubeadm=1.33.* kubectl=1.33.*

            # Hold packages to prevent automatic updates
            sudo apt-mark hold kubelet kubeadm kubectl

            # Enable kubelet
            sudo systemctl enable kubelet

            echo '✅ Kubernetes tools installed'
        "

        print_success "Kubernetes tools installed on $hostname"
    done
}

# Run system checks
run_system_checks() {
    print_section "Running system validation checks"

    for hostname in "${!HOSTS[@]}"; do
        ip=${HOSTS[$hostname]}
        print_info "Running checks on $hostname..."

        # Run checks and capture output
        ssh "$SSH_USER@$ip" "
            echo '🔍 System Information:'
            echo '  OS: '$(lsb_release -d | cut -f2)
            echo '  Kernel: '$(uname -r)
            echo '  Memory: '$(free -h | grep '^Mem:' | awk '{print \$2}')
            echo '  Disk: '$(df -h / | tail -1 | awk '{print \$4}' | sed 's/G/ GB/')'available'

            echo ''
            echo '✅ Prerequisite checks:'

            # Check swap
            if [[ \$(swapon --show) ]]; then
                echo '  ❌ Swap is still enabled'
            else
                echo '  ✅ Swap is disabled'
            fi

            # Check required kernel modules
            if lsmod | grep -q br_netfilter; then
                echo '  ✅ br_netfilter module loaded'
            else
                echo '  ❌ br_netfilter module not loaded'
            fi

            if lsmod | grep -q overlay; then
                echo '  ✅ overlay module loaded'
            else
                echo '  ❌ overlay module not loaded'
            fi

            # Check containerd
            if systemctl is-active --quiet containerd; then
                echo '  ✅ containerd is running'
            else
                echo '  ❌ containerd is not running'
            fi

            # Check kubelet
            if systemctl is-enabled --quiet kubelet; then
                echo '  ✅ kubelet is enabled'
            else
                echo '  ❌ kubelet is not enabled'
            fi

            echo ''
        "

        print_success "System checks completed on $hostname"
    done
}

# Main execution
main() {
    print_header

    print_info "This script will prepare all Kubernetes cluster nodes"
    print_info "Nodes: ${!HOSTS[*]}"
    echo ""

    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Operation cancelled"
        exit 1
    fi

    check_ssh_connectivity
    setup_hosts_file
    setup_prerequisites
    install_containerd
    install_kubernetes_tools
    run_system_checks

    print_section "Host Preparation Complete!"
    print_success "All hosts are now ready for Kubernetes installation"
    print_info "Next step: Run ./scripts/phase1/02-install-kubernetes.sh"
    echo ""
}

# Execute main function
main "$@"