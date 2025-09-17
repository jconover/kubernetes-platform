# Docker Hub Deployment Workflow

This document explains how to use Docker Hub for deploying applications to your Kubernetes cluster.

## Overview

The platform now uses Docker Hub as the container registry, which provides several benefits:
- ✅ **Professional deployment practice** - mirrors real-world production environments
- ✅ **Multi-node compatibility** - works seamlessly with kubeadm clusters
- ✅ **No image distribution needed** - Kubernetes pulls directly from registry
- ✅ **Version management** - proper image tagging and versioning
- ✅ **Public portfolio** - showcases your containerized applications

## Prerequisites

1. **Docker Hub Account**: Create account at [hub.docker.com](https://hub.docker.com)
2. **Docker Login**: Run `docker login` on your development machine
3. **Images Built**: All application images must be pushed to Docker Hub

## Quick Start

### 1. Build and Push Images

```bash
# Run the automated build and push script
./scripts/build-and-push.sh
```

This script will:
- Build all application images (Python API, React Frontend, Java Service)
- Tag them with your Docker Hub username
- Push both `1.0.0` and `latest` tags
- Display Docker Hub URLs for verification

### 2. Deploy Applications

```bash
# Deploy using the standard deployment script
./scripts/phase3/01-deploy-apps.sh
```

The deployment script automatically:
- Detects Docker Hub configuration
- Skips image loading (not needed with registry)
- Deploys with `imagePullPolicy: Always`
- Pulls images directly from Docker Hub

## Docker Hub Images

Your applications are available at:

| Application | Docker Hub URL |
|-------------|----------------|
| Python API | `jconover/python-api:1.0.0` |
| React Frontend | `jconover/react-frontend:1.0.0` |
| Java Service | `jconover/java-service:1.0.0` |

## Configuration Files Updated

The following files have been updated for Docker Hub:

### Kubernetes Manifests
- `manifests/apps/python-api/deployment.yaml`
- `manifests/apps/react-frontend/deployment.yaml`
- `manifests/apps/java-service/deployment.yaml`

### Helm Charts
- `helm-charts/microservices-platform/values.yaml`

### Deployment Scripts
- `scripts/phase3/01-deploy-apps.sh`
- `scripts/build-and-push.sh` (new)

## Manual Commands

### Build and Push Individual Images

```bash
# Python API
docker build -t jconover/python-api:1.0.0 applications/python-api/
docker push jconover/python-api:1.0.0

# React Frontend
docker build -t jconover/react-frontend:1.0.0 applications/react-frontend/
docker push jconover/react-frontend:1.0.0

# Java Service
docker build -t jconover/java-service:1.0.0 applications/java-service/
docker push jconover/java-service:1.0.0
```

### Deploy Individual Applications

```bash
# Python API
kubectl apply -f manifests/apps/python-api/
kubectl wait --for=condition=available deployment/python-api -n python-api --timeout=300s

# React Frontend
kubectl apply -f manifests/apps/react-frontend/
kubectl wait --for=condition=available deployment/react-frontend -n react-frontend --timeout=300s

# Java Service
kubectl apply -f manifests/apps/java-service/
kubectl wait --for=condition=available deployment/java-service -n java-service --timeout=300s
```

## Troubleshooting

### Image Pull Errors
If you see `ImagePullBackOff` errors:

1. **Verify images exist on Docker Hub**:
   ```bash
   # Check if images are publicly available
   docker pull jconover/python-api:1.0.0
   docker pull jconover/react-frontend:1.0.0
   docker pull jconover/java-service:1.0.0
   ```

2. **Check image names in manifests**:
   ```bash
   grep -r "image:" manifests/apps/
   ```

3. **Verify deployment status**:
   ```bash
   kubectl get pods -A | grep -E "(python-api|react-frontend|java-service)"
   kubectl describe pod <pod-name> -n <namespace>
   ```

### Update Images
To push updated versions:

1. **Rebuild and push**:
   ```bash
   ./scripts/build-and-push.sh
   ```

2. **Restart deployments**:
   ```bash
   kubectl rollout restart deployment/python-api -n python-api
   kubectl rollout restart deployment/react-frontend -n react-frontend
   kubectl rollout restart deployment/java-service -n java-service
   ```

## Benefits for KCNA Exam

Using Docker Hub demonstrates several KCNA exam concepts:

- **Container Registries**: Understanding of image storage and distribution
- **Image Pull Policies**: Knowledge of `Always`, `IfNotPresent`, `Never`
- **Production Practices**: Real-world deployment patterns
- **Security**: Proper image management and versioning
- **Scalability**: Registry-based deployment for multi-node clusters

## Portfolio Benefits

This setup showcases:
- ✅ Professional container registry usage
- ✅ Proper CI/CD practices
- ✅ Multi-architecture deployment
- ✅ Production-ready image management
- ✅ Public Docker Hub repositories for portfolio demonstration

## Next Steps

1. **Continuous Integration**: Set up GitHub Actions to automatically build and push images
2. **Image Scanning**: Add security scanning to your Docker Hub repositories
3. **Private Registry**: Consider setting up a private registry for sensitive applications
4. **Multi-stage Builds**: Optimize image sizes with advanced Dockerfile techniques