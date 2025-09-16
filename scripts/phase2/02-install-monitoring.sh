#!/bin/bash

# Monitoring Stack Installation Script (Prometheus + Grafana)
# This script installs a complete observability stack using Helm

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
MONITORING_NAMESPACE="monitoring"
PROMETHEUS_CHART_VERSION="25.8.0"
GRAFANA_CHART_VERSION="7.0.19"

print_header() {
    echo ""
    echo -e "${PURPLE}================================================================${NC}"
    echo -e "${WHITE}           Monitoring Stack Installation${NC}"
    echo -e "${WHITE}           (Prometheus + Grafana + AlertManager)${NC}"
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

    # Check if Helm is installed
    if ! command -v helm &> /dev/null; then
        print_error "Helm is not installed"
        print_info "Please install Helm first or run ./scripts/phase2/03-install-helm.sh"
        exit 1
    fi
    print_success "Helm is available"

    # Check cluster resources
    NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)
    print_info "Cluster has $NODE_COUNT nodes"

    if [[ $NODE_COUNT -lt 3 ]]; then
        print_warning "Monitoring stack works best with 3+ nodes"
    fi
}

# Create monitoring namespace
create_namespace() {
    print_section "Creating Monitoring Namespace"

    # Create namespace with labels
    kubectl apply -f - << EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $MONITORING_NAMESPACE
  labels:
    name: $MONITORING_NAMESPACE
    app.kubernetes.io/name: monitoring
    app.kubernetes.io/component: observability
EOF

    print_success "Monitoring namespace created"
}

# Add Helm repositories
add_helm_repos() {
    print_section "Adding Helm Repositories"

    print_info "Adding Prometheus community Helm repository..."
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

    print_info "Adding Grafana Helm repository..."
    helm repo add grafana https://grafana.github.io/helm-charts

    print_info "Updating Helm repositories..."
    helm repo update

    print_success "Helm repositories added and updated"
}

# Install Prometheus Stack (includes Prometheus, AlertManager, and Grafana)
install_prometheus_stack() {
    print_section "Installing Prometheus Stack"

    print_info "Creating Prometheus stack values configuration..."

    # Create values file for kube-prometheus-stack
    cat > /tmp/prometheus-values.yaml << EOF
prometheus:
  prometheusSpec:
    retention: "30d"
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 10Gi
    additionalScrapeConfigs: |
      - job_name: 'kubernetes-pods'
        kubernetes_sd_configs:
          - role: pod
        relabel_configs:
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
            action: keep
            regex: true
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
            action: replace
            target_label: __metrics_path__
            regex: (.+)
          - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
            action: replace
            regex: ([^:]+)(?::\d+)?;(\d+)
            replacement: $1:$2
            target_label: __address__

alertmanager:
  alertmanagerSpec:
    storage:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 2Gi

grafana:
  adminPassword: "admin123"
  service:
    type: NodePort
    nodePort: 30300
  persistence:
    enabled: true
    size: 1Gi
  dashboardProviders:
    dashboardproviders.yaml:
      apiVersion: 1
      providers:
      - name: 'default'
        orgId: 1
        folder: ''
        type: file
        disableDeletion: false
        editable: true
        options:
          path: /var/lib/grafana/dashboards/default
  dashboards:
    default:
      kubernetes-cluster-monitoring:
        gnetId: 7249
        revision: 1
        datasource: Prometheus
      kubernetes-pod-monitoring:
        gnetId: 6417
        revision: 1
        datasource: Prometheus
      node-exporter:
        gnetId: 1860
        revision: 31
        datasource: Prometheus
      cilium-metrics:
        gnetId: 16611
        revision: 1
        datasource: Prometheus

nodeExporter:
  enabled: true

kubeStateMetrics:
  enabled: true

defaultRules:
  rules:
    alertmanager: true
    etcd: true
    configReloaders: true
    general: true
    k8s: true
    kubeApiserverAvailability: true
    kubeApiserverBurnrate: true
    kubeApiserverHistogram: true
    kubeApiserverSlos: true
    kubelet: true
    kubeProxy: true
    kubePrometheusGeneral: true
    kubePrometheusNodeRecording: true
    kubernetesApps: true
    kubernetesResources: true
    kubernetesStorage: true
    kubernetesSystem: true
    network: true
    node: true
    nodeExporterAlerting: true
    nodeExporterRecording: true
    prometheus: true
    prometheusOperator: true
EOF

    print_info "Installing kube-prometheus-stack..."
    helm install prometheus-stack prometheus-community/kube-prometheus-stack \
        --namespace $MONITORING_NAMESPACE \
        --values /tmp/prometheus-values.yaml \
        --wait \
        --timeout=600s

    print_success "Prometheus stack installed successfully"
    rm -f /tmp/prometheus-values.yaml
}

# Wait for all components to be ready
wait_for_monitoring_stack() {
    print_section "Waiting for Monitoring Stack to be Ready"

    print_info "Waiting for Prometheus components..."

    # Wait for Prometheus StatefulSet
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n $MONITORING_NAMESPACE --timeout=300s

    # Wait for Grafana deployment
    kubectl wait --for=condition=available deployment -l app.kubernetes.io/name=grafana -n $MONITORING_NAMESPACE --timeout=300s

    # Wait for AlertManager StatefulSet
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=alertmanager -n $MONITORING_NAMESPACE --timeout=300s

    print_success "All monitoring components are ready"

    # Show running pods
    echo ""
    print_info "Monitoring stack pods:"
    kubectl get pods -n $MONITORING_NAMESPACE -o wide
}

# Configure service access
configure_service_access() {
    print_section "Configuring Service Access"

    # Patch Prometheus service to NodePort
    print_info "Configuring Prometheus access..."
    kubectl patch svc prometheus-stack-kube-prom-prometheus -n $MONITORING_NAMESPACE -p '{"spec":{"type":"NodePort","ports":[{"name":"http-web","nodePort":30900,"port":9090,"protocol":"TCP","targetPort":9090}]}}'

    # Patch AlertManager service to NodePort
    print_info "Configuring AlertManager access..."
    kubectl patch svc prometheus-stack-kube-prom-alertmanager -n $MONITORING_NAMESPACE -p '{"spec":{"type":"NodePort","ports":[{"name":"http-web","nodePort":30903,"port":9093,"protocol":"TCP","targetPort":9093}]}}'

    # Grafana should already be configured as NodePort from values

    print_success "Service access configured"

    # Get service information
    MASTER_IP="192.168.68.86"
    echo ""
    print_info "Service Access Information:"
    echo -e "  🎯 Prometheus: http://$MASTER_IP:30900"
    echo -e "  📊 Grafana: http://$MASTER_IP:30300 (admin/admin123)"
    echo -e "  🔔 AlertManager: http://$MASTER_IP:30903"
}

# Create monitoring manifests for GitOps
create_monitoring_manifests() {
    print_section "Creating Monitoring Manifests for GitOps"

    # Create monitoring directory structure
    mkdir -p manifests/monitoring/prometheus
    mkdir -p manifests/monitoring/grafana
    mkdir -p manifests/monitoring/alertmanager

    # Create ServiceMonitor for custom application monitoring
    cat > manifests/monitoring/servicemonitor-custom-apps.yaml << EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: custom-apps
  namespace: monitoring
  labels:
    app: custom-apps
spec:
  selector:
    matchLabels:
      prometheus.io/scrape: "true"
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
  namespaceSelector:
    matchNames:
    - python-api
    - react-frontend
    - java-service
    - default
EOF

    # Create additional AlertManager configuration
    cat > manifests/monitoring/alertmanager/custom-alerts.yaml << EOF
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: custom-application-alerts
  namespace: monitoring
  labels:
    app: custom-alerts
    prometheus: kube-prometheus
    role: alert-rules
spec:
  groups:
  - name: custom.applications
    rules:
    - alert: HighMemoryUsage
      expr: (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) < 0.1
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High memory usage detected"
        description: "Node {{ \$labels.instance }} has less than 10% memory available"

    - alert: HighCPUUsage
      expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High CPU usage detected"
        description: "Node {{ \$labels.instance }} has high CPU usage: {{ \$value }}%"

    - alert: PodCrashLooping
      expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Pod {{ \$labels.pod }} is crash looping"
        description: "Pod {{ \$labels.pod }} in namespace {{ \$labels.namespace }} is restarting frequently"
EOF

    # Create Grafana dashboard ConfigMap for custom applications
    cat > manifests/monitoring/grafana/custom-dashboard.yaml << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-apps-dashboard
  namespace: monitoring
  labels:
    grafana_dashboard: "1"
data:
  custom-apps.json: |
    {
      "dashboard": {
        "id": null,
        "title": "Custom Applications Dashboard",
        "tags": ["kubernetes", "applications"],
        "style": "dark",
        "timezone": "browser",
        "panels": [
          {
            "id": 1,
            "title": "Application Response Time",
            "type": "graph",
            "targets": [
              {
                "expr": "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service))",
                "legendFormat": "95th percentile - {{ service }}"
              }
            ],
            "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
          },
          {
            "id": 2,
            "title": "Application Request Rate",
            "type": "graph",
            "targets": [
              {
                "expr": "sum(rate(http_requests_total[5m])) by (service)",
                "legendFormat": "{{ service }}"
              }
            ],
            "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
          }
        ],
        "time": {"from": "now-1h", "to": "now"},
        "refresh": "30s"
      }
    }
EOF

    print_success "Monitoring manifests created"
    print_info "Manifests created in manifests/monitoring/"
}

# Create monitoring access scripts
create_access_scripts() {
    print_section "Creating Monitoring Access Scripts"

    # Create Grafana access script
    cat > scripts/grafana-ui.sh << 'EOF'
#!/bin/bash

# Grafana UI Access Script

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

MASTER_IP="192.168.68.86"
GRAFANA_PORT="30300"

echo -e "${BLUE}📊 Grafana Dashboard Access${NC}"
echo -e "${BLUE}============================${NC}"
echo ""
echo -e "🌐 URL: ${GREEN}http://$MASTER_IP:$GRAFANA_PORT${NC}"
echo ""
echo -e "${YELLOW}Credentials:${NC}"
echo -e "  Username: admin"
echo -e "  Password: admin123"
echo ""
echo -e "${BLUE}💡 Default Dashboards:${NC}"
echo -e "  • Kubernetes Cluster Monitoring"
echo -e "  • Node Exporter"
echo -e "  • Kubernetes Pod Monitoring"
echo -e "  • Cilium Metrics"
echo ""
echo -e "${YELLOW}Pro tip:${NC} Change the admin password after first login!"
EOF

    chmod +x scripts/grafana-ui.sh

    # Create Prometheus access script
    cat > scripts/prometheus-ui.sh << 'EOF'
#!/bin/bash

# Prometheus UI Access Script

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

MASTER_IP="192.168.68.86"
PROMETHEUS_PORT="30900"
ALERTMANAGER_PORT="30903"

echo -e "${BLUE}🎯 Prometheus & AlertManager Access${NC}"
echo -e "${BLUE}===================================${NC}"
echo ""
echo -e "🎯 Prometheus: ${GREEN}http://$MASTER_IP:$PROMETHEUS_PORT${NC}"
echo -e "🔔 AlertManager: ${GREEN}http://$MASTER_IP:$ALERTMANAGER_PORT${NC}"
echo ""
echo -e "${BLUE}💡 Useful Prometheus Queries:${NC}"
echo -e "  • up - Shows all targets status"
echo -e "  • node_memory_MemAvailable_bytes - Available memory"
echo -e "  • rate(container_cpu_usage_seconds_total[5m]) - CPU usage rate"
echo -e "  • kube_pod_status_phase - Pod status"
echo ""
EOF

    chmod +x scripts/prometheus-ui.sh

    # Create monitoring status script
    cat > scripts/monitoring-status.sh << 'EOF'
#!/bin/bash

# Monitoring Stack Status Script

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${WHITE}📊 Monitoring Stack Status${NC}"
echo -e "${WHITE}==========================${NC}"
echo ""

echo -e "${CYAN}🏗️  Monitoring Pods:${NC}"
kubectl get pods -n monitoring -o wide
echo ""

echo -e "${CYAN}🌐 Monitoring Services:${NC}"
kubectl get svc -n monitoring
echo ""

echo -e "${CYAN}📈 ServiceMonitors:${NC}"
kubectl get servicemonitor -n monitoring
echo ""

echo -e "${CYAN}🔔 PrometheusRules:${NC}"
kubectl get prometheusrule -n monitoring
echo ""

MASTER_IP="192.168.68.86"
echo -e "${YELLOW}🔗 Access URLs:${NC}"
echo -e "  📊 Grafana: http://$MASTER_IP:30300 (admin/admin123)"
echo -e "  🎯 Prometheus: http://$MASTER_IP:30900"
echo -e "  🔔 AlertManager: http://$MASTER_IP:30903"
echo ""

echo -e "${GREEN}✅ Monitoring stack is operational!${NC}"
EOF

    chmod +x scripts/monitoring-status.sh

    print_success "Monitoring access scripts created"
}

# Verify monitoring stack
verify_monitoring_stack() {
    print_section "Verifying Monitoring Stack"

    print_info "Checking monitoring components..."

    # Check pods
    kubectl get pods -n $MONITORING_NAMESPACE

    # Check services
    echo ""
    print_info "Monitoring services:"
    kubectl get svc -n $MONITORING_NAMESPACE

    # Check ServiceMonitors
    echo ""
    print_info "ServiceMonitors (for scraping metrics):"
    kubectl get servicemonitor -n $MONITORING_NAMESPACE

    print_success "Monitoring stack verification complete"

    MASTER_IP="192.168.68.86"
    echo ""
    print_info "🎉 Monitoring stack is ready!"
    print_info "📊 Grafana: http://$MASTER_IP:30300 (admin/admin123)"
    print_info "🎯 Prometheus: http://$MASTER_IP:30900"
    print_info "🔔 AlertManager: http://$MASTER_IP:30903"
}

# Main execution
main() {
    print_header

    print_info "This script will install a complete monitoring stack"
    echo -e "${BLUE}Components to be installed:${NC}"
    echo -e "  • Prometheus (metrics collection)"
    echo -e "  • Grafana (dashboards and visualization)"
    echo -e "  • AlertManager (alerting)"
    echo -e "  • Node Exporter (node metrics)"
    echo -e "  • kube-state-metrics (Kubernetes metrics)"
    echo -e "  • Pre-configured dashboards"
    echo ""

    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Operation cancelled"
        exit 1
    fi

    check_prerequisites
    create_namespace
    add_helm_repos
    install_prometheus_stack
    wait_for_monitoring_stack
    configure_service_access
    create_monitoring_manifests
    create_access_scripts
    verify_monitoring_stack

    print_section "Monitoring Stack Installation Complete!"
    print_success "🎉 Complete observability stack is now running!"
    print_info "📋 Run './scripts/monitoring-status.sh' to check status"
    print_info "📊 Run './scripts/grafana-ui.sh' to get Grafana access info"
    print_info "🎯 Run './scripts/prometheus-ui.sh' to get Prometheus access info"
    print_info "🔄 Next step: Install Helm (run ./scripts/phase2/03-install-helm.sh) if not already installed"
    echo ""
}

# Execute main function
main "$@"