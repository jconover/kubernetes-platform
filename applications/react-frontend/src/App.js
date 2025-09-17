import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import axios from 'axios';

// Components
import Dashboard from './components/Dashboard';
import Services from './components/Services';
import Data from './components/Data';
import About from './components/About';

// API Configuration
const API_BASE_URL = process.env.REACT_APP_API_URL || '/api';

// Axios interceptor for error handling
axios.interceptors.response.use(
  (response) => response,
  (error) => {
    console.error('API Error:', error);
    return Promise.reject(error);
  }
);

function App() {
  const [apiStatus, setApiStatus] = useState('checking');
  const [currentTime, setCurrentTime] = useState(new Date());

  // Check API status on component mount
  useEffect(() => {
    const checkApiStatus = async () => {
      try {
        const response = await axios.get(`${API_BASE_URL}/status`);
        if (response.status === 200) {
          setApiStatus('healthy');
        }
      } catch (error) {
        setApiStatus('unhealthy');
      }
    };

    checkApiStatus();

    // Update current time every second
    const timeInterval = setInterval(() => {
      setCurrentTime(new Date());
    }, 1000);

    // Check API status every 30 seconds
    const statusInterval = setInterval(checkApiStatus, 30000);

    return () => {
      clearInterval(timeInterval);
      clearInterval(statusInterval);
    };
  }, []);

  const getStatusBadgeClass = (status) => {
    switch (status) {
      case 'healthy': return 'status-badge status-healthy';
      case 'unhealthy': return 'status-badge status-unhealthy';
      default: return 'status-badge status-unknown';
    }
  };

  return (
    <Router>
      <div className="App">
        {/* Navigation */}
        <nav className="navbar navbar-expand-lg navbar-dark bg-dark">
          <div className="container">
            <Link className="navbar-brand" to="/">
              <i className="fas fa-dharmachakra me-2"></i>
              Kubernetes Platform
            </Link>

            <button
              className="navbar-toggler"
              type="button"
              data-bs-toggle="collapse"
              data-bs-target="#navbarNav"
            >
              <span className="navbar-toggler-icon"></span>
            </button>

            <div className="collapse navbar-collapse" id="navbarNav">
              <ul className="navbar-nav me-auto">
                <li className="nav-item">
                  <Link className="nav-link" to="/">Dashboard</Link>
                </li>
                <li className="nav-item">
                  <Link className="nav-link" to="/services">Services</Link>
                </li>
                <li className="nav-item">
                  <Link className="nav-link" to="/data">Data</Link>
                </li>
                <li className="nav-item">
                  <Link className="nav-link" to="/about">About</Link>
                </li>
              </ul>

              <ul className="navbar-nav">
                <li className="nav-item">
                  <span className="navbar-text me-3">
                    API: <span className={getStatusBadgeClass(apiStatus)}>
                      {apiStatus}
                    </span>
                  </span>
                </li>
                <li className="nav-item">
                  <span className="navbar-text">
                    {currentTime.toLocaleTimeString()}
                  </span>
                </li>
              </ul>
            </div>
          </div>
        </nav>

        {/* Main Content */}
        <main className="container mt-4">
          <Routes>
            <Route path="/" element={<Dashboard apiStatus={apiStatus} />} />
            <Route path="/services" element={<Services />} />
            <Route path="/data" element={<Data />} />
            <Route path="/about" element={<About />} />
          </Routes>
        </main>

        {/* Footer */}
        <footer className="footer mt-5">
          <div className="container">
            <div className="row">
              <div className="col-md-6">
                <h5>Kubernetes Platform Demo</h5>
                <p className="text-muted">
                  A cloud-native application demonstrating modern DevOps practices
                  with Kubernetes, GitOps, and observability.
                </p>
              </div>
              <div className="col-md-6">
                <h6>Technologies Used</h6>
                <div className="row text-center">
                  <div className="col-2">
                    <i className="fab fa-react tech-icon text-info"></i>
                  </div>
                  <div className="col-2">
                    <i className="fab fa-python tech-icon text-warning"></i>
                  </div>
                  <div className="col-2">
                    <i className="fab fa-java tech-icon text-danger"></i>
                  </div>
                  <div className="col-2">
                    <i className="fab fa-docker tech-icon text-primary"></i>
                  </div>
                  <div className="col-2">
                    <i className="fas fa-dharmachakra tech-icon text-success"></i>
                  </div>
                  <div className="col-2">
                    <i className="fas fa-chart-line tech-icon text-secondary"></i>
                  </div>
                </div>
              </div>
            </div>
            <hr className="my-4" />
            <div className="row">
              <div className="col-md-12 text-center">
                <p className="text-muted mb-0">
                  &copy; 2024 Kubernetes Platform Demo. Built for learning and demonstration.
                </p>
              </div>
            </div>
          </div>
        </footer>
      </div>
    </Router>
  );
}

export default App;