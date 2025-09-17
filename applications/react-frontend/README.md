# React Frontend Application

A modern React-based web application for the Kubernetes Platform Demo, showcasing cloud-native frontend development patterns.

## Features

- **Modern React**: Built with React 18 and functional components
- **Responsive Design**: Bootstrap 5 for mobile-first responsive UI
- **API Integration**: Axios for HTTP client with error handling
- **Real-time Updates**: Automatic data refresh and live status monitoring
- **Multi-route SPA**: React Router for client-side navigation
- **Production Ready**: Nginx-based serving with security headers
- **Health Checks**: Built-in health endpoints for Kubernetes probes

## Application Structure

```
src/
├── components/          # React components
│   ├── Dashboard.js     # Main dashboard with metrics
│   ├── Services.js      # Service status and information
│   ├── Data.js          # Data management interface
│   └── About.js         # Platform information
├── App.js              # Main application component
├── index.js            # Application entry point
└── index.css           # Global styles
```

## Pages

### Dashboard
- Real-time system metrics and status
- API health monitoring
- Platform feature overview
- Quick statistics and system information

### Services
- Overview of all microservices
- Service health status
- Endpoint information
- Current service details

### Data
- Interactive data management
- CRUD operations via API
- Real-time data statistics
- Form validation and error handling

### About
- Technology stack information
- KCNA exam alignment details
- Platform architecture overview
- Getting started guide

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `REACT_APP_API_URL` | Backend API base URL | `/api` |
| `NODE_ENV` | Runtime environment | `development` |

## Development

### Prerequisites
- Node.js 18+
- npm or yarn

### Local Development
```bash
# Install dependencies
npm install

# Start development server
npm start

# Run tests
npm test

# Build for production
npm run build
```

### Docker Development
```bash
# Build the image
docker build -t react-frontend:latest .

# Run the container
docker run -p 3000:3000 react-frontend:latest
```

## Production Deployment

The application uses a multi-stage Docker build:

1. **Build Stage**: Node.js Alpine image for building the React app
2. **Production Stage**: Nginx Alpine image for serving static files

### Nginx Configuration
- Gzip compression enabled
- Security headers configured
- Client-side routing support
- API proxy configuration
- Static asset caching
- Health check endpoint

## API Integration

The frontend integrates with the Python API backend:

- **Base URL**: Configurable via `REACT_APP_API_URL`
- **Error Handling**: Global axios interceptors
- **Auto-refresh**: Periodic data updates
- **Loading States**: User feedback during API calls

### API Endpoints Used
- `GET /api/status` - Service status and information
- `GET /api/data` - Retrieve data items
- `POST /api/data` - Create new data items
- `GET /health` - Health check for the backend

## Security Features

- **CSP Headers**: Content Security Policy configured
- **XSS Protection**: X-XSS-Protection header
- **Frame Options**: X-Frame-Options to prevent clickjacking
- **Content Type**: X-Content-Type-Options nosniff
- **Non-root User**: Container runs as non-root user
- **Input Validation**: Form validation and sanitization

## Performance Optimizations

- **Code Splitting**: Automatic React code splitting
- **Asset Optimization**: Webpack optimizations
- **Gzip Compression**: Nginx gzip for smaller payload
- **Caching**: Static asset caching headers
- **Lazy Loading**: Components loaded on demand

## Kubernetes Integration

- **Health Probes**: `/health` endpoint for liveness/readiness
- **Graceful Shutdown**: Proper signal handling
- **Resource Limits**: CPU and memory constraints
- **Security Context**: Non-root user and security policies
- **ConfigMaps**: Environment-based configuration

## Browser Support

- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)

## Dependencies

### Runtime Dependencies
- React 18.x - UI library
- React Router DOM - Client-side routing
- Axios - HTTP client
- Bootstrap 5 - CSS framework

### Development Dependencies
- React Scripts - Build tooling
- Testing Library - Testing utilities
- Web Vitals - Performance monitoring

## Monitoring

The application includes:
- Real-time API status monitoring
- Error boundary for graceful error handling
- Performance monitoring with Web Vitals
- Nginx access and error logs