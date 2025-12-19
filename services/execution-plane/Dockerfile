# Multi-stage Dockerfile for execution-plane service
# Build: cargo build --release
# Runtime: Minimal Alpine base with just the binary

# ============================================================================
# Stage 1: Builder
# ============================================================================
FROM rust:1.75-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    musl-dev \
    pkg-config \
    openssl-dev \
    git

WORKDIR /app

# Copy manifests
COPY Cargo.toml Cargo.lock ./

# Create dummy main to cache dependencies
RUN mkdir src && \
    echo "fn main() {}" > src/main.rs && \
    cargo build --release && \
    rm -rf src

# Copy source code
COPY . .

# Build application
RUN cargo build --release

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
COPY --from=builder /app/target/release/execution-plane /usr/local/bin/execution-plane

# Health check
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:9000/health || exit 1

# Change ownership to non-root user
RUN chown -R app:app /app

USER app

# Expose port
EXPOSE 9000

# Run service
CMD ["/usr/local/bin/execution-plane"]
