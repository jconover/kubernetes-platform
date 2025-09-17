# Java Spring Boot Microservice

A production-ready Spring Boot microservice demonstrating enterprise Java patterns and cloud-native development for the Kubernetes Platform Demo.

## Features

- **Spring Boot 3.2**: Latest Spring Boot with Java 17
- **Spring Data JPA**: Database operations with H2 in-memory database
- **RESTful APIs**: Complete CRUD operations with proper HTTP status codes
- **Actuator Endpoints**: Health checks, metrics, and application monitoring
- **Prometheus Metrics**: Custom metrics with Micrometer integration
- **Validation**: Bean validation with proper error handling
- **Auditing**: Automatic created/updated timestamps
- **Docker**: Multi-stage build with security best practices
- **Security**: Non-root container user, input validation

## API Endpoints

### Core Endpoints
- `GET /actuator/health` - Health check for Kubernetes probes
- `GET /actuator/metrics` - Application metrics
- `GET /actuator/prometheus` - Prometheus metrics endpoint
- `GET /api/v1/status` - Service status with environment info

### Item Management APIs
- `GET /api/v1/items` - Get all items (with filtering)
- `GET /api/v1/items/{id}` - Get item by ID
- `POST /api/v1/items` - Create new item
- `PUT /api/v1/items/{id}` - Update existing item
- `DELETE /api/v1/items/{id}` - Delete item
- `GET /api/v1/items/categories` - Get all categories
- `GET /api/v1/items/search?keyword=` - Search items
- `GET /api/v1/items/stats` - Get item statistics

### Query Parameters
- `status` - Filter by item status (ACTIVE, INACTIVE, PENDING, ARCHIVED)
- `category` - Filter by item category
- `page`, `size` - Pagination support
- `sortBy`, `sortDir` - Sorting options

## Data Model

### Item Entity
```java
{
  "id": Long,
  "name": String (required, max 100 chars),
  "description": String (max 500 chars),
  "category": String (required, max 50 chars),
  "status": ItemStatus (ACTIVE, INACTIVE, PENDING, ARCHIVED),
  "createdAt": LocalDateTime,
  "updatedAt": LocalDateTime
}
```

## Configuration

### Environment Variables
| Variable | Description | Default |
|----------|-------------|---------|
| `SERVER_PORT` | HTTP server port | `8080` |
| `ENVIRONMENT` | Runtime environment | `development` |
| `NODE_NAME` | Kubernetes node name | `unknown` |
| `POD_NAME` | Kubernetes pod name | `unknown` |
| `POD_IP` | Pod IP address | `unknown` |

### Database Configuration
- **Engine**: H2 In-Memory Database
- **URL**: `jdbc:h2:mem:testdb`
- **Console**: Available at `/h2-console` (development only)
- **Schema**: Auto-created on startup

## Development

### Prerequisites
- Java 17+
- Maven 3.9+

### Local Development
```bash
# Build the application
mvn clean compile

# Run tests
mvn test

# Start the application
mvn spring-boot:run

# Package for deployment
mvn clean package
```

### Docker Development
```bash
# Build the image
docker build -t java-service:latest .

# Run the container
docker run -p 8080:8080 java-service:latest

# Access the application
curl http://localhost:8080/actuator/health
```

## Production Deployment

### Docker Image
- **Multi-stage build**: Separate build and runtime stages
- **Base Image**: OpenJDK 17 JRE Slim
- **Security**: Non-root user, minimal attack surface
- **Optimization**: JVM tuning for containers
- **Health Checks**: Built-in health endpoint monitoring

### JVM Configuration
```bash
JAVA_OPTS="-Xmx512m -Xms256m -XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"
```

## Monitoring & Observability

### Actuator Endpoints
- `/actuator/health` - Application health status
- `/actuator/info` - Application information
- `/actuator/metrics` - Application metrics
- `/actuator/prometheus` - Prometheus-format metrics

### Custom Metrics
- `api_requests_total` - Total API requests by endpoint
- `api_errors_total` - Total API errors by endpoint
- `api_request_duration` - Request duration histogram

### Health Indicators
- Database connectivity
- Disk space availability
- Application status

## Security Features

- **Input Validation**: Bean validation annotations
- **SQL Injection Prevention**: JPA parameterized queries
- **Container Security**: Non-root user execution
- **Error Handling**: Sanitized error responses
- **CORS**: Cross-origin resource sharing configured

## Testing

### Unit Tests
```bash
mvn test
```

### Integration Tests
```bash
mvn verify
```

### API Testing
```bash
# Health check
curl http://localhost:8080/actuator/health

# Get all items
curl http://localhost:8080/api/v1/items

# Create item
curl -X POST http://localhost:8080/api/v1/items \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Item","description":"Test Description","category":"Test"}'
```

## Kubernetes Integration

### Readiness Probe
```yaml
readinessProbe:
  httpGet:
    path: /actuator/health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
```

### Liveness Probe
```yaml
livenessProbe:
  httpGet:
    path: /actuator/health
    port: 8080
  initialDelaySeconds: 60
  periodSeconds: 30
```

### Resource Requirements
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

## Sample Data

The application initializes with sample data including:
- Spring Boot Application
- RESTful API
- JPA Entity Manager
- Actuator Endpoints
- Prometheus Metrics
- Docker Container
- Kubernetes Deployment
- Load Balancer
- Auto Scaling
- Circuit Breaker

## Architecture Patterns

- **Layered Architecture**: Controller, Service, Repository layers
- **Dependency Injection**: Spring IoC container
- **Data Transfer Objects**: Clean API contracts
- **Exception Handling**: Global exception handling
- **Aspect-Oriented Programming**: Cross-cutting concerns
- **Configuration Management**: External configuration support

## Performance Considerations

- **Connection Pooling**: Database connection management
- **JVM Tuning**: Container-optimized JVM settings
- **Lazy Loading**: JPA lazy loading for performance
- **Caching**: Application-level caching where appropriate
- **Resource Management**: Proper resource cleanup