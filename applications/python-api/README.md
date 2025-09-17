# Python API Microservice

A FastAPI-based microservice demonstrating cloud-native patterns and Kubernetes integration.

## Features

- **FastAPI Framework**: Modern, fast Python web framework
- **Prometheus Metrics**: Built-in metrics collection and exposure
- **Health Checks**: Kubernetes-ready liveness and readiness probes
- **CORS Support**: Cross-origin resource sharing enabled
- **Structured Logging**: JSON-formatted logs for observability
- **Security**: Non-root container user, security headers
- **Docker**: Multi-stage build with security best practices

## API Endpoints

### Core Endpoints
- `GET /` - Root endpoint with service information
- `GET /health` - Health check for liveness probes
- `GET /ready` - Readiness check for readiness probes
- `GET /metrics` - Prometheus metrics endpoint

### API Endpoints
- `GET /api/status` - Detailed service status with environment info
- `GET /api/data` - Sample data collection
- `POST /api/data` - Create new data item
- `GET /api/config` - Service configuration (filtered)
- `GET /api/simulate-error` - Error simulation for testing

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | HTTP server port | `8000` |
| `LOG_LEVEL` | Logging level | `info` |
| `ENVIRONMENT` | Runtime environment | `development` |
| `SERVICE_NAME` | Service identifier | `python-api` |
| `NODE_NAME` | Kubernetes node name | `unknown` |
| `POD_NAME` | Kubernetes pod name | `unknown` |
| `POD_IP` | Pod IP address | `unknown` |

## Development

### Local Development
```bash
# Install dependencies
pip install -r requirements.txt

# Run the application
python app.py

# Access the API
curl http://localhost:8000/
```

### Docker Build
```bash
# Build the image
docker build -t python-api:latest .

# Run the container
docker run -p 8000:8000 python-api:latest
```

## Kubernetes Deployment

The service is designed to work seamlessly with Kubernetes:

- **Health Probes**: Implements `/health` and `/ready` endpoints
- **Metrics**: Exposes Prometheus metrics on `/metrics`
- **Security**: Runs as non-root user
- **Configuration**: Environment-based configuration
- **Logging**: Structured JSON logs

## Monitoring

The service exposes the following Prometheus metrics:

- `http_requests_total` - Total HTTP requests (counter)
- `http_request_duration_seconds` - Request duration histogram

## Security Features

- Non-root container user (`appuser`)
- Minimal base image (Python slim)
- Security headers and CORS configuration
- Input validation and sanitization
- No sensitive data in logs or responses