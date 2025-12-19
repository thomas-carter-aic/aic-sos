# Container Build Pipeline - P1 Delivery

**Status:** PHASE-0 P1 Implementation  
**Objective:** Enable multi-arch Docker builds for all services with reproducible, optimized images

## Architecture Overview

### Services to Containerize

| Service | Language | Purpose | Image Size Target |
|---------|----------|---------|-------------------|
| **control-plane** | Go | Multi-tenant API server | <100MB |
| **connector-gateway** | Go | Third-party integrations | <100MB |
| **execution-plane** | Rust | Secure workflow execution | <150MB |
| **agent** | Rust | Distributed policy executor | <150MB |
| **indexer** | (TBD) | Event indexing/search | <200MB |

### Multi-Arch Support

- **Primary:** `linux/amd64` (x86-64, most servers)
- **Secondary:** `linux/arm64` (Apple Silicon, ARM servers)
- **Optional:** `linux/arm/v7` (embedded, RPi)

### Build Strategy

**Phase 1 (Current):**
- Multi-stage Dockerfiles (small final images)
- Pinned base images (security, reproducibility)
- Layer caching optimization
- Local builds + push to registry

**Phase 2 (Future):**
- BuildKit + caching backend
- Registry-based layer caching
- CI automated builds (GitHub Actions)
- Signed images (cosign)

## Dockerfiles

### Pattern: Multi-Stage Build

**Benefits:**
- Final image excludes build dependencies (Go compiler, Rust toolchain)
- Smaller images = faster pulls, better security
- Layer cache optimization

**Example (Go service):**
```dockerfile
# Stage 1: Build
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o app .

# Stage 2: Runtime
FROM alpine:3.19
RUN apk add --no-cache ca-certificates tzdata
COPY --from=builder /app/app /usr/local/bin/app
HEALTHCHECK CMD ["/usr/local/bin/app", "health"]
CMD ["/usr/local/bin/app"]
```

**Why this pattern:**
- Alpine base: 5MB vs 1GB for full OS
- No build tools in final image
- Only runtime dependencies included
- Small image = faster deployment, lower bandwidth

## File Manifest

Files to create:

```
services/
├── control-plane/
│   └── Dockerfile
├── connector-gateway/
│   └── Dockerfile
├── execution-plane/
│   └── Dockerfile
├── agent/
│   └── Dockerfile
└── indexer/
    └── Dockerfile

.dockerignore (root)
Makefile (updated with container targets)
.github/CONTAINER-BUILD.md (documentation)
```

## Makefile Targets

```bash
make container-build       # Build all images (amd64 + arm64)
make container-build-amd64 # Build amd64 only (faster)
make container-build-arm64 # Build arm64 only
make container-push        # Push to registry
make container-clean       # Remove local images

# Individual service builds
make container-build-control-plane
make container-build-connector-gateway
make container-build-execution-plane
make container-build-agent
make container-build-indexer
```

## Registry Configuration

**Phase 1:** Manual local builds (for dev/testing)

**Phase 2 candidates:**
- GitHub Container Registry (ghcr.io)
- Docker Hub
- Private registry (ECR, Harbor)

## Implementation Steps

1. ✅ Create this document
2. Create Dockerfiles for all 5 services
3. Create .dockerignore
4. Update Makefile with container targets
5. Create documentation (.github/CONTAINER-BUILD.md)
6. Test local builds
7. Document in START-HERE.md

## Next Steps

See implementation files below.
