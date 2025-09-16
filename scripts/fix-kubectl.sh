#!/bin/bash

# Quick fix script for kubectl installation issues

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

HOSTS=("192.168.68.86" "192.168.68.88" "192.168.68.83")
SSH_USER="justin"

echo -e "${YELLOW}Fixing kubectl installation on all hosts...${NC}"

for host in "${HOSTS[@]}"; do
    echo -e "${GREEN}Processing $host...${NC}"

    ssh -tt "$SSH_USER@$host" "
        echo 'Removing old package holds...'
        sudo apt-mark unhold kubelet kubeadm kubectl 2>/dev/null || true

        echo 'Removing old packages if they exist...'
        sudo apt-get remove -y kubelet kubeadm kubectl 2>/dev/null || true

        echo 'Cleaning apt cache...'
        sudo apt-get clean
        sudo apt-get update

        echo 'Adding Kubernetes 1.34 repository...'
        curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg 2>/dev/null
        echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

        echo 'Installing Kubernetes tools v1.34...'
        sudo apt-get update
        sudo apt-get install -y kubelet kubeadm kubectl

        echo 'Applying package hold...'
        sudo apt-mark hold kubelet kubeadm kubectl

        echo 'Verifying installation...'
        kubectl version --client
        which kubectl

        echo '✅ Done on this host!'
    "

    echo -e "${GREEN}✓ Completed $host${NC}"
    echo ""
done

echo -e "${GREEN}All hosts processed! kubectl should now be installed.${NC}"