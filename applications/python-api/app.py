from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST, CollectorRegistry, REGISTRY
from fastapi.responses import Response
import uvicorn
import os
import json
import logging
import time
from datetime import datetime

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI(
    title="Kubernetes Platform API",
    description="A sample Python microservice for the Kubernetes platform demo",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, replace with specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create custom registry to avoid conflicts
custom_registry = CollectorRegistry()

# Prometheus metrics with custom registry
REQUEST_COUNT = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status'],
    registry=custom_registry
)
REQUEST_DURATION = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration in seconds',
    ['method', 'endpoint'],
    registry=custom_registry
)

# Middleware for metrics collection
@app.middleware("http")
async def collect_metrics(request, call_next):
    start_time = time.time()
    response = await call_next(request)
    duration = time.time() - start_time

    # Record metrics
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.url.path,
        status=response.status_code
    ).inc()

    REQUEST_DURATION.labels(
        method=request.method,
        endpoint=request.url.path
    ).observe(duration)

    return response

@app.get("/")
async def root():
    """Root endpoint returning service information"""
    return {
        "service": "python-api",
        "version": "1.0.0",
        "description": "Kubernetes Platform Python Microservice",
        "timestamp": datetime.utcnow().isoformat(),
        "status": "healthy"
    }

@app.get("/health")
async def health_check():
    """Health check endpoint for Kubernetes probes"""
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "service": "python-api"
    }

@app.get("/ready")
async def readiness_check():
    """Readiness check endpoint for Kubernetes probes"""
    return {
        "status": "ready",
        "timestamp": datetime.utcnow().isoformat(),
        "service": "python-api"
    }

@app.get("/api/status")
async def get_status():
    """Get detailed service status"""
    return {
        "service": "python-api",
        "version": "1.0.0",
        "environment": os.getenv("ENVIRONMENT", "development"),
        "node_name": os.getenv("NODE_NAME", "unknown"),
        "pod_name": os.getenv("POD_NAME", "unknown"),
        "pod_ip": os.getenv("POD_IP", "unknown"),
        "timestamp": datetime.utcnow().isoformat(),
        "uptime": "Service is running"
    }

@app.get("/api/data")
async def get_sample_data():
    """Get sample data for demonstration"""
    sample_data = [
        {"id": 1, "name": "Kubernetes", "type": "Container Orchestration", "status": "active"},
        {"id": 2, "name": "Cilium", "type": "CNI", "status": "active"},
        {"id": 3, "name": "ArgoCD", "type": "GitOps", "status": "active"},
        {"id": 4, "name": "Prometheus", "type": "Monitoring", "status": "active"},
        {"id": 5, "name": "Grafana", "type": "Visualization", "status": "active"}
    ]

    return {
        "data": sample_data,
        "count": len(sample_data),
        "timestamp": datetime.utcnow().isoformat()
    }

@app.post("/api/data")
async def create_data(item: dict):
    """Create new data item (demo endpoint)"""
    # In a real application, this would persist to a database
    item["id"] = int(time.time())  # Simple ID generation
    item["created_at"] = datetime.utcnow().isoformat()

    logger.info(f"Created new item: {item}")

    return {
        "message": "Item created successfully",
        "item": item,
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/api/config")
async def get_config():
    """Get service configuration (filtered for security)"""
    safe_config = {
        "service_name": os.getenv("SERVICE_NAME", "python-api"),
        "port": int(os.getenv("PORT", 8000)),
        "environment": os.getenv("ENVIRONMENT", "development"),
        "log_level": os.getenv("LOG_LEVEL", "INFO"),
        "features": {
            "metrics": True,
            "health_checks": True,
            "cors": True
        }
    }

    return safe_config

@app.get("/api/simulate-error")
async def simulate_error():
    """Simulate an error for testing purposes"""
    error_type = os.getenv("ERROR_TYPE", "500")

    if error_type == "404":
        raise HTTPException(status_code=404, detail="Resource not found")
    elif error_type == "403":
        raise HTTPException(status_code=403, detail="Access forbidden")
    else:
        raise HTTPException(status_code=500, detail="Internal server error simulation")

@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint"""
    return Response(generate_latest(custom_registry), media_type=CONTENT_TYPE_LATEST)

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    log_level = os.getenv("LOG_LEVEL", "info").lower()

    logger.info(f"Starting Python API service on port {port}")

    uvicorn.run(
        "app:app",
        host="0.0.0.0",
        port=port,
        log_level=log_level,
        reload=False
    )