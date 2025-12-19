# Multi-stage Dockerfile for control-plane service
# Build: go build -o app
# Runtime: Minimal Alpine base with just the binary

# ============================================================================
# Stage 1: Builder
# ============================================================================
FROM golang:1.21-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates

WORKDIR /app

# Copy go.mod and go.sum
COPY go.mod go.sum ./

# Download dependencies (cached layer)
RUN go mod download

# Copy source code
COPY . .

# Build binary (CGO disabled for Alpine compatibility)
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s" \
    -o bin/control-plane ./cmd/control-plane

# ============================================================================
# Stage 2: Runtime
# ============================================================================
FROM alpine:3.19

# Install runtime dependencies
RUN apk add --no-cache ca-certificates tzdata curl

# Create non-root user for security
RUN addgroup -g 1000 app && adduser -u 1000 -G app -s /sbin/nologin app

WORKDIR /app

# Copy binary from builder
COPY --from=builder /app/bin/control-plane /usr/local/bin/control-plane

# Health check
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Change ownership to non-root user
RUN chown -R app:app /app

USER app

# Expose port
EXPOSE 8000

# Run service
CMD ["/usr/local/bin/control-plane"]
