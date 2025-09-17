import React from 'react';

const About = () => {
  const technologies = [
    {
      category: 'Container Orchestration',
      items: [
        { name: 'Kubernetes', version: '1.28', description: 'Container orchestration platform' },
        { name: 'kubeadm', version: '1.28', description: 'Kubernetes cluster bootstrap tool' },
        { name: 'kubectl', version: '1.28', description: 'Kubernetes command-line tool' }
      ]
    },
    {
      category: 'Networking & Security',
      items: [
        { name: 'Cilium', version: '1.14', description: 'eBPF-based CNI with advanced security' },
        { name: 'Network Policies', version: '-', description: 'Kubernetes network security policies' }
      ]
    },
    {
      category: 'GitOps & Deployment',
      items: [
        { name: 'ArgoCD', version: '2.8', description: 'GitOps continuous delivery' },
        { name: 'Helm', version: '3.x', description: 'Kubernetes package manager' }
      ]
    },
    {
      category: 'Observability',
      items: [
        { name: 'Prometheus', version: '2.x', description: 'Metrics collection and alerting' },
        { name: 'Grafana', version: '10.x', description: 'Metrics visualization and dashboards' },
        { name: 'Hubble', version: '1.14', description: 'Network observability for Cilium' }
      ]
    },
    {
      category: 'Applications',
      items: [
        { name: 'Python/FastAPI', version: '3.11', description: 'High-performance Python web framework' },
        { name: 'React', version: '18.x', description: 'Modern frontend JavaScript library' },
        { name: 'Java/Spring Boot', version: '17', description: 'Enterprise Java application framework' }
      ]
    }
  ];

  const features = [
    {
      title: 'Production Ready',
      description: 'Multi-node cluster with high availability and security best practices',
      icon: 'fas fa-shield-alt',
      color: 'success'
    },
    {
      title: 'GitOps Workflow',
      description: 'Declarative deployments with ArgoCD for consistent and reliable releases',
      icon: 'fas fa-code-branch',
      color: 'info'
    },
    {
      title: 'Full Observability',
      description: 'Comprehensive monitoring, logging, and tracing across the platform',
      icon: 'fas fa-chart-line',
      color: 'warning'
    },
    {
      title: 'Security First',
      description: 'Network policies, RBAC, and container security from the ground up',
      icon: 'fas fa-lock',
      color: 'danger'
    },
    {
      title: 'Cloud Native',
      description: 'Follows CNCF best practices and cloud-native architecture patterns',
      icon: 'fas fa-cloud',
      color: 'primary'
    },
    {
      title: 'KCNA Aligned',
      description: 'Demonstrates all concepts required for the Kubernetes Cloud Native Associate exam',
      icon: 'fas fa-graduation-cap',
      color: 'secondary'
    }
  ];

  return (
    <div>
      {/* Header */}
      <div className="row mb-4">
        <div className="col-12">
          <div className="card">
            <div className="card-body text-center">
              <h1 className="card-title">
                <i className="fas fa-info-circle text-primary me-3"></i>
                About This Platform
              </h1>
              <p className="card-text text-muted">
                A comprehensive Kubernetes platform demonstrating cloud-native technologies and DevOps practices
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Project Overview */}
      <div className="row mb-5">
        <div className="col-md-8">
          <div className="card">
            <div className="card-header">
              <h5 className="mb-0">
                <i className="fas fa-project-diagram me-2"></i>
                Project Overview
              </h5>
            </div>
            <div className="card-body">
              <p>
                This Kubernetes platform serves as a comprehensive demonstration of modern cloud-native technologies and practices. 
                Built on a 3-node cluster using Beelink SER5 mini PCs, it showcases production-ready patterns and is specifically 
                designed to align with the Kubernetes Cloud Native Associate (KCNA) exam objectives.
              </p>
              <p>
                The platform implements GitOps workflows, advanced networking with Cilium, comprehensive observability, 
                and multi-language microservices architecture. Every component follows security best practices and 
                cloud-native principles.
              </p>
            </div>
          </div>
        </div>
        <div className="col-md-4">
          <div className="card">
            <div className="card-header">
              <h5 className="mb-0">
                <i className="fas fa-server me-2"></i>
                Infrastructure
              </h5>
            </div>
            <div className="card-body">
              <div className="mb-3">
                <strong>Hardware:</strong>
                <ul className="list-unstyled mt-1">
                  <li>• 3x Beelink SER5 Mini PCs</li>
                  <li>• 1 Control Plane Node</li>
                  <li>• 2 Worker Nodes</li>
                </ul>
              </div>
              <div className="mb-3">
                <strong>Network:</strong>
                <ul className="list-unstyled mt-1">
                  <li>• Pod CIDR: 10.244.0.0/16</li>
                  <li>• Service CIDR: 10.96.0.0/12</li>
                  <li>• Cilium CNI with eBPF</li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Key Features */}
      <div className="row mb-5">
        <div className="col-12">
          <h3 className="mb-4">
            <i className="fas fa-star me-2"></i>
            Key Features
          </h3>
        </div>
        {features.map((feature, index) => (
          <div key={index} className="col-md-4 mb-3">
            <div className="card h-100">
              <div className="card-body text-center">
                <i className={`${feature.icon} text-${feature.color} mb-3`} style={{fontSize: '3rem'}}></i>
                <h5 className="card-title">{feature.title}</h5>
                <p className="card-text text-muted">{feature.description}</p>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Technology Stack */}
      <div className="row mb-5">
        <div className="col-12">
          <h3 className="mb-4">
            <i className="fas fa-layer-group me-2"></i>
            Technology Stack
          </h3>
        </div>
        {technologies.map((category, index) => (
          <div key={index} className="col-md-6 mb-4">
            <div className="card">
              <div className="card-header">
                <h5 className="mb-0">{category.category}</h5>
              </div>
              <div className="card-body">
                <div className="list-group list-group-flush">
                  {category.items.map((tech, techIndex) => (
                    <div key={techIndex} className="list-group-item d-flex justify-content-between align-items-start">
                      <div className="ms-2 me-auto">
                        <div className="fw-bold">{tech.name}</div>
                        <small className="text-muted">{tech.description}</small>
                      </div>
                      <span className="badge bg-primary rounded-pill">{tech.version}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* KCNA Alignment */}
      <div className="row mb-5">
        <div className="col-12">
          <div className="card">
            <div className="card-header">
              <h5 className="mb-0">
                <i className="fas fa-graduation-cap me-2"></i>
                KCNA Exam Alignment
              </h5>
            </div>
            <div className="card-body">
              <p className="mb-3">
                This platform demonstrates all key concepts tested in the Kubernetes Cloud Native Associate exam:
              </p>
              <div className="row">
                <div className="col-md-6">
                  <h6>Kubernetes Fundamentals</h6>
                  <ul>
                    <li>Container orchestration concepts</li>
                    <li>Kubernetes architecture and components</li>
                    <li>Pods, Deployments, and Services</li>
                    <li>ConfigMaps and Secrets</li>
                    <li>Namespaces and resource management</li>
                  </ul>
                </div>
                <div className="col-md-6">
                  <h6>Cloud Native Architecture</h6>
                  <ul>
                    <li>Microservices architecture patterns</li>
                    <li>12-factor app methodology</li>
                    <li>Container security best practices</li>
                    <li>Observability and monitoring</li>
                    <li>GitOps and CI/CD practices</li>
                  </ul>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Getting Started */}
      <div className="row">
        <div className="col-12">
          <div className="card">
            <div className="card-header">
              <h5 className="mb-0">
                <i className="fas fa-rocket me-2"></i>
                Getting Started
              </h5>
            </div>
            <div className="card-body">
              <p>
                To deploy this platform, follow the phase-based approach:
              </p>
              <div className="row">
                <div className="col-md-4">
                  <div className="card border-primary">
                    <div className="card-header bg-primary text-white">
                      <strong>Phase 1: Cluster Setup</strong>
                    </div>
                    <div className="card-body">
                      <ol className="mb-0">
                        <li>Prepare hosts</li>
                        <li>Install Kubernetes</li>
                        <li>Setup Cilium CNI</li>
                      </ol>
                    </div>
                  </div>
                </div>
                <div className="col-md-4">
                  <div className="card border-success">
                    <div className="card-header bg-success text-white">
                      <strong>Phase 2: Platform Services</strong>
                    </div>
                    <div className="card-body">
                      <ol className="mb-0">
                        <li>Install ArgoCD</li>
                        <li>Setup monitoring</li>
                        <li>Configure Helm</li>
                      </ol>
                    </div>
                  </div>
                </div>
                <div className="col-md-4">
                  <div className="card border-info">
                    <div className="card-header bg-info text-white">
                      <strong>Phase 3: Applications</strong>
                    </div>
                    <div className="card-body">
                      <ol className="mb-0">
                        <li>Deploy Python API</li>
                        <li>Deploy React Frontend</li>
                        <li>Deploy Java Service</li>
                      </ol>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default About;