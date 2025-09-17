import React, { useState, useEffect } from 'react';
import axios from 'axios';

const Services = () => {
  const [serviceStatus, setServiceStatus] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchServiceStatus = async () => {
      try {
        setLoading(true);
        const response = await axios.get('/api/status');
        setServiceStatus(response.data);
        setError(null);
      } catch (err) {
        setError('Failed to load service status');
      } finally {
        setLoading(false);
      }
    };

    fetchServiceStatus();
    const interval = setInterval(fetchServiceStatus, 15000);
    return () => clearInterval(interval);
  }, []);

  const services = [
    {
      name: 'Python API',
      description: 'FastAPI microservice with metrics and health checks',
      status: 'healthy',
      port: '8000',
      endpoints: ['/api/status', '/api/data', '/metrics', '/health'],
      icon: 'fab fa-python',
      color: 'primary'
    },
    {
      name: 'React Frontend',
      description: 'Modern React web application with responsive design',
      status: 'healthy',
      port: '3000',
      endpoints: ['/', '/services', '/data', '/about'],
      icon: 'fab fa-react',
      color: 'info'
    },
    {
      name: 'Java Service',
      description: 'Spring Boot service with JPA and REST APIs',
      status: 'healthy',
      port: '8080',
      endpoints: ['/actuator/health', '/api/v1/items', '/actuator/metrics'],
      icon: 'fab fa-java',
      color: 'danger'
    }
  ];

  if (loading) {
    return (
      <div className="loading-spinner">
        <div className="spinner-border text-primary" role="status">
          <span className="visually-hidden">Loading...</span>
        </div>
      </div>
    );
  }

  return (
    <div>
      <div className="row mb-4">
        <div className="col-12">
          <div className="card">
            <div className="card-body">
              <h1 className="card-title">
                <i className="fas fa-server text-success me-3"></i>
                Platform Services
              </h1>
              <p className="card-text text-muted">
                Overview of all microservices running in the Kubernetes cluster
              </p>
            </div>
          </div>
        </div>
      </div>

      {error && (
        <div className="error-message">
          <i className="fas fa-exclamation-triangle me-2"></i>
          {error}
        </div>
      )}

      <div className="row">
        {services.map((service, index) => (
          <div key={index} className="col-md-4 mb-4">
            <div className="card h-100">
              <div className="card-header d-flex align-items-center">
                <i className={`${service.icon} text-${service.color} me-2`} style={{fontSize: '1.5rem'}}></i>
                <div>
                  <h5 className="mb-0">{service.name}</h5>
                  <span className={`badge bg-${service.status === 'healthy' ? 'success' : 'danger'}`}>
                    {service.status}
                  </span>
                </div>
              </div>
              <div className="card-body">
                <p className="card-text">{service.description}</p>
                <div className="mb-3">
                  <strong>Port:</strong> {service.port}
                </div>
                <div>
                  <strong>Endpoints:</strong>
                  <ul className="list-unstyled mt-2">
                    {service.endpoints.map((endpoint, idx) => (
                      <li key={idx}>
                        <code className="text-muted">{endpoint}</code>
                      </li>
                    ))}
                  </ul>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {serviceStatus && (
        <div className="row mt-4">
          <div className="col-12">
            <div className="card">
              <div className="card-header">
                <h5 className="mb-0">
                  <i className="fas fa-info-circle me-2"></i>
                  Current Service Details
                </h5>
              </div>
              <div className="card-body">
                <div className="row">
                  <div className="col-md-6">
                    <table className="table table-sm">
                      <tbody>
                        <tr>
                          <td><strong>Service Name:</strong></td>
                          <td>{serviceStatus.service}</td>
                        </tr>
                        <tr>
                          <td><strong>Version:</strong></td>
                          <td>{serviceStatus.version}</td>
                        </tr>
                        <tr>
                          <td><strong>Environment:</strong></td>
                          <td>
                            <span className={`badge bg-${serviceStatus.environment === 'production' ? 'danger' : 'warning'}`}>
                              {serviceStatus.environment}
                            </span>
                          </td>
                        </tr>
                      </tbody>
                    </table>
                  </div>
                  <div className="col-md-6">
                    <table className="table table-sm">
                      <tbody>
                        <tr>
                          <td><strong>Node:</strong></td>
                          <td>{serviceStatus.node_name}</td>
                        </tr>
                        <tr>
                          <td><strong>Pod Name:</strong></td>
                          <td>{serviceStatus.pod_name}</td>
                        </tr>
                        <tr>
                          <td><strong>Pod IP:</strong></td>
                          <td>{serviceStatus.pod_ip}</td>
                        </tr>
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Services;