# Container Build Guide

This guide explains how to build, test, and publish container images for AIC-SOS services.

**Quick Start:**
```bash
# Build all services (linux/amd64)
make container-build

# Build single service
make container-build-control-plane

# Build for multiple architectures
make BUILD_PLATFORMS='linux/amd64,linux/arm64' container-build
```

## Overview

AIC-SOS uses Docker multi-stage builds to create minimal, secure container images. See [`.github/CONTAINER-BUILD-STRATEGY.md`](./CONTAINER-BUILD-STRATEGY.md) for the comprehensive architecture strategy.

## Services

All services follow the multi-stage build pattern:

| Service | Language | Port | Image Size | Base Image |
|---------|----------|------|------------|------------|
| `control-plane` | Go | 8000 | <100MB | alpine:3.19 |
| `connector-gateway` | Go | 8001 | <100MB | alpine:3.19 |
| `execution-plane` | Rust | 9000 | <150MB | alpine:3.19 |
| `agent` | Rust | 9001 | <150MB | alpine:3.19 |
| `indexer` | Go | 9002 | <200MB | alpine:3.19 |

## Prerequisites

### Docker Setup

1. **Enable Docker Buildx** (for multi-arch support):
   ```bash
   # Check if buildx is available
   docker buildx version
   
   # If not, create a builder instance
   docker buildx create --use --name aic-builder
   docker buildx inspect --bootstrap
   ```

2. **Verify Docker daemon** is running:
   ```bash
   docker ps
   ```

## Building Images

### Local amd64 Build (Recommended for Development)

Build all services for your current architecture:
```bash
make container-build
```

This builds:
- `ghcr.io/aic-sos/control-plane:latest`
- `ghcr.io/aic-sos/connector-gateway:latest`
- `ghcr.io/aic-sos/execution-plane:latest`
- `ghcr.io/aic-sos/agent:latest`
- `ghcr.io/aic-sos/indexer:latest`

### Build Single Service

```bash
make container-build-control-plane
make container-build-connector-gateway
make container-build-execution-plane
make container-build-agent
make container-build-indexer
```

### Build for Multiple Architectures

To build images that work on both amd64 and arm64 (e.g., for M1/M2 Macs):

```bash
# Build for both amd64 and arm64
make BUILD_PLATFORMS='linux/amd64,linux/arm64' container-build

# Build single service for multiple architectures
make BUILD_PLATFORMS='linux/amd64,linux/arm64' container-build-control-plane
```

**Note:** Multi-architecture builds require `docker buildx` and cannot use `--load` flag (images are built directly on builder, not loaded into local Docker).

### Load Images into Local Docker

To test locally, build and load the image:

```bash
# Build and load single service (amd64 only)
docker buildx build --load --platform linux/amd64 \
  -t control-plane:local \
  services/control-plane

# Then run it
docker run -p 8000:8000 control-plane:local
```

## Testing Built Images

### Verify Image Properties

```bash
# Check image size
docker images ghcr.io/aic-sos/control-plane

# Inspect image layers
docker history ghcr.io/aic-sos/control-plane:latest

# Check running container
docker run -d --name test-cp -p 8000:8000 ghcr.io/aic-sos/control-plane:latest
docker ps | grep test-cp
docker logs test-cp

# Test health check
curl http://localhost:8000/health

# Clean up
docker rm -f test-cp
```

### Health Checks

All images include health checks that can be verified:

```bash
# Health check endpoint for each service
curl http://localhost:8000/health      # control-plane
curl http://localhost:8001/health      # connector-gateway
curl http://localhost:9000/health      # execution-plane
curl http://localhost:9001/health      # agent
curl http://localhost:9002/health      # indexer
```

### Security Verification

All images follow security best practices:

```bash
# Run as non-root (should not run as root)
docker run --rm ghcr.io/aic-sos/control-plane:latest id
# Output: uid=1000(app) gid=1000(app) groups=1000(app)

# Check image for vulnerabilities (requires trivy)
trivy image ghcr.io/aic-sos/control-plane:latest
```

## Publishing to Registry

### Prerequisites

1. **GitHub Container Registry (GHCR) Auth:**
   ```bash
   # Create GitHub Personal Access Token (PAT) with `write:packages` scope
   # https://github.com/settings/tokens
   
   # Log in to GHCR
   echo $PAT | docker login ghcr.io -u USERNAME --password-stdin
   ```

### Push Images

```bash
# Push all services (amd64)
make container-push

# Push single service with manual command
docker buildx build --push --platform linux/amd64 \
  -t ghcr.io/aic-sos/control-plane:latest \
  -t ghcr.io/aic-sos/control-plane:v0.1.0 \
  services/control-plane

# Push for multiple architectures
docker buildx build --push --platform linux/amd64,linux/arm64 \
  -t ghcr.io/aic-sos/control-plane:latest \
  -t ghcr.io/aic-sos/control-plane:v0.1.0 \
  services/control-plane
```

### Verify Published Images

```bash
# List tags in GHCR
docker pull ghcr.io/aic-sos/control-plane:latest
docker inspect ghcr.io/aic-sos/control-plane:latest | grep Architecture
```

## Build Variables

Customize builds using environment variables:

```bash
# Override registry
make DOCKER_REGISTRY=myregistry.azurecr.io container-build-control-plane

# Override platform (single platform only)
make BUILD_PLATFORMS=linux/arm64 container-build-control-plane

# Combine overrides
make DOCKER_REGISTRY=myregistry DOCKER_TAGS=v1.0.0 container-build
```

## Troubleshooting

### Build Fails with "Cannot find Dockerfile"

Check Dockerfile path:
```bash
ls -la services/control-plane/Dockerfile
```

### "buildx: command not found"

Enable Docker Buildx:
```bash
docker buildx create --use --name aic-builder
docker buildx inspect --bootstrap
```

### Multi-arch build doesn't load locally

Multi-architecture builds cannot use `--load`. Either:
1. Build single architecture: `make BUILD_PLATFORMS=linux/amd64 container-build`
2. Push to registry: `docker buildx build --push ...`

### Image too large

Check layer sizes:
```bash
docker history ghcr.io/aic-sos/control-plane:latest

# Build stage may include build tools. Verify:
# - Builder stage uses proper base image
# - Final stage copies only binary
# - .dockerignore is properly configured
```

### Health check fails

Verify service is running on expected port:
```bash
docker run -d --name test -p 8000:8000 ghcr.io/aic-sos/control-plane:latest
docker logs test
docker exec test curl localhost:8000/health
```

## CI/CD Integration

Currently, container builds are **manual** (developers build locally before commits).

**Planned (Phase 1+):**
- Automated builds on git push
- Automated push to GHCR on release
- Automated image scanning (Trivy)
- Automated multi-arch builds

See [`.github/CONTAINER-BUILD-STRATEGY.md`](./CONTAINER-BUILD-STRATEGY.md) for implementation roadmap.

## References

- **Build Strategy:** [`.github/CONTAINER-BUILD-STRATEGY.md`](./CONTAINER-BUILD-STRATEGY.md)
- **Docker Buildx:** https://docs.docker.com/build/architecture/
- **Multi-arch Guide:** https://docs.docker.com/build/building/multi-platform/
- **Alpine Base Images:** https://hub.docker.com/_/alpine
- **Image Security:** https://docs.docker.com/develop/dev-best-practices/

## Next Steps

After building images locally:

1. **Test images:** Run `docker run` and verify health checks
2. **Push to registry:** Authenticate with GHCR and run `make container-push`
3. **Update deployment:** Configure Kubernetes manifests or Docker Compose to use new image tags
4. **Verify in deployment:** Check `kubectl describe pod` or `docker ps` to confirm correct images

## Questions?

Refer to the [BUILD-STRATEGY document](./CONTAINER-BUILD-STRATEGY.md) for architecture decisions, or file an issue with container build errors.
