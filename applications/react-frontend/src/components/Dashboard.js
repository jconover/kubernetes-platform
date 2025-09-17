import React, { useState, useEffect } from 'react';
import axios from 'axios';

const Dashboard = ({ apiStatus }) => {
  const [systemStats, setSystemStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        setLoading(true);
        const [statusResponse, dataResponse] = await Promise.all([
          axios.get('/api/status'),
          axios.get('/api/data')
        ]);

        setSystemStats({
          ...statusResponse.data,
          dataCount: dataResponse.data.count
        });
        setError(null);
      } catch (err) {
        setError('Failed to load dashboard data');
        console.error('Dashboard error:', err);
      } finally {
        setLoading(false);
      }
    };

    fetchDashboardData();
    const interval = setInterval(fetchDashboardData, 30000); // Update every 30 seconds

    return () => clearInterval(interval);
  }, []);

  if (loading) {
    return (
      <div className="loading-spinner">
        <div className="spinner-border text-primary" role="status">
          <span className="visually-hidden">Loading...</span>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="error-message">
        <i className="fas fa-exclamation-triangle me-2"></i>
        {error}
      </div>
    );
  }

  const getStatusColor = (status) => {
    switch (status) {
      case 'healthy': return 'success';
      case 'unhealthy': return 'danger';
      default: return 'warning';
    }
  };

  return (
    <div>
      {/* Header */}
      <div className="row mb-4">
        <div className="col-12">
          <div className="card">
            <div className="card-body text-center">
              <h1 className="card-title">
                <i className="fas fa-dharmachakra text-primary me-3"></i>
                Kubernetes Platform Dashboard
              </h1>
              <p className="card-text text-muted">
                Real-time monitoring and status of the cloud-native platform
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Status Cards */}
      <div className="row mb-4">
        <div className="col-md-3">
          <div className="card metric-card">
            <div className="card-body">
              <div className={`metric-value text-${getStatusColor(apiStatus)}`}>
                <i className={`fas fa-${apiStatus === 'healthy' ? 'check-circle' : apiStatus === 'unhealthy' ? 'times-circle' : 'question-circle'}`}></i>
              </div>
              <div className="metric-label">API Status</div>
              <small className="text-muted">{apiStatus}</small>
            </div>
          </div>
        </div>

        <div className="col-md-3">
          <div className="card metric-card">
            <div className="card-body">
              <div className="metric-value text-primary">
                {systemStats?.dataCount || 0}
              </div>
              <div className="metric-label">Data Records</div>
              <small className="text-muted">Available items</small>
            </div>
          </div>
        </div>

        <div className="col-md-3">
          <div className="card metric-card">
            <div className="card-body">
              <div className="metric-value text-success">
                <i className="fas fa-server"></i>
              </div>
              <div className="metric-label">Services</div>
              <small className="text-muted">Running</small>
            </div>
          </div>
        </div>

        <div className="col-md-3">
          <div className="card metric-card">
            <div className="card-body">
              <div className="metric-value text-info">
                v1.0.0
              </div>
              <div className="metric-label">Version</div>
              <small className="text-muted">Current</small>
            </div>
          </div>
        </div>
      </div>

      {/* System Information */}
      {systemStats && (
        <div className="row mb-4">
          <div className="col-md-6">
            <div className="card">
              <div className="card-header">
                <h5 className="card-title mb-0">
                  <i className="fas fa-info-circle me-2"></i>
                  System Information
                </h5>
              </div>
              <div className="card-body">
                <table className="table table-sm">
                  <tbody>
                    <tr>
                      <td><strong>Service:</strong></td>
                      <td>{systemStats.service}</td>
                    </tr>
                    <tr>
                      <td><strong>Version:</strong></td>
                      <td>{systemStats.version}</td>
                    </tr>
                    <tr>
                      <td><strong>Environment:</strong></td>
                      <td>
                        <span className={`badge bg-${systemStats.environment === 'production' ? 'danger' : 'warning'}`}>
                          {systemStats.environment}
                        </span>
                      </td>
                    </tr>
                    <tr>
                      <td><strong>Node:</strong></td>
                      <td>{systemStats.node_name}</td>
                    </tr>
                    <tr>
                      <td><strong>Pod:</strong></td>
                      <td>{systemStats.pod_name}</td>
                    </tr>
                    <tr>
                      <td><strong>Pod IP:</strong></td>
                      <td>{systemStats.pod_ip}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <div className="col-md-6">
            <div className="card">
              <div className="card-header">
                <h5 className="card-title mb-0">
                  <i className="fas fa-chart-bar me-2"></i>
                  Quick Stats
                </h5>
              </div>
              <div className="card-body">
                <div className="mb-3">
                  <div className="d-flex justify-content-between">
                    <span>API Health</span>
                    <span className={`badge bg-${getStatusColor(apiStatus)}`}>
                      {apiStatus}
                    </span>
                  </div>
                </div>
                <div className="mb-3">
                  <div className="d-flex justify-content-between">
                    <span>Last Updated</span>
                    <small className="text-muted">
                      {new Date(systemStats.timestamp).toLocaleTimeString()}
                    </small>
                  </div>
                </div>
                <div className="mb-3">
                  <div className="d-flex justify-content-between">
                    <span>Uptime Status</span>
                    <span className="badge bg-success">Online</span>
                  </div>
                </div>
                <div className="mb-3">
                  <div className="d-flex justify-content-between">
                    <span>Data Records</span>
                    <span className="badge bg-primary">{systemStats.dataCount}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Feature Cards */}
      <div className="row">
        <div className="col-md-4 mb-3">
          <div className="card">
            <div className="card-body text-center">
              <i className="fas fa-dharmachakra text-primary mb-3" style={{fontSize: '3rem'}}></i>
              <h5 className="card-title">Kubernetes</h5>
              <p className="card-text">Container orchestration with kubeadm, featuring high availability and scalability.</p>
            </div>
          </div>
        </div>

        <div className="col-md-4 mb-3">
          <div className="card">
            <div className="card-body text-center">
              <i className="fas fa-network-wired text-success mb-3" style={{fontSize: '3rem'}}></i>
              <h5 className="card-title">Cilium CNI</h5>
              <p className="card-text">Advanced networking and security with eBPF-based network policies.</p>
            </div>
          </div>
        </div>

        <div className="col-md-4 mb-3">
          <div className="card">
            <div className="card-body text-center">
              <i className="fas fa-code-branch text-info mb-3" style={{fontSize: '3rem'}}></i>
              <h5 className="card-title">GitOps</h5>
              <p className="card-text">Declarative deployment and management with ArgoCD for continuous delivery.</p>
            </div>
          </div>
        </div>

        <div className="col-md-4 mb-3">
          <div className="card">
            <div className="card-body text-center">
              <i className="fas fa-chart-line text-warning mb-3" style={{fontSize: '3rem'}}></i>
              <h5 className="card-title">Monitoring</h5>
              <p className="card-text">Comprehensive observability with Prometheus, Grafana, and custom metrics.</p>
            </div>
          </div>
        </div>

        <div className="col-md-4 mb-3">
          <div className="card">
            <div className="card-body text-center">
              <i className="fas fa-shield-alt text-danger mb-3" style={{fontSize: '3rem'}}></i>
              <h5 className="card-title">Security</h5>
              <p className="card-text">Security-first approach with RBAC, network policies, and container security.</p>
            </div>
          </div>
        </div>

        <div className="col-md-4 mb-3">
          <div className="card">
            <div className="card-body text-center">
              <i className="fas fa-cubes text-secondary mb-3" style={{fontSize: '3rem'}}></i>
              <h5 className="card-title">Microservices</h5>
              <p className="card-text">Modern application architecture with Python, React, and Java services.</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;