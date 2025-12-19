VERSION := $(shell cat VERSION | tr -d '\n' | tr -d ' ')

.PHONY: help build version version-show version-bump-patch version-bump-minor version-bump-major version-tag version-tags \
	dev dev-up dev-down dev-logs dev-status dev-reset smoke-test \
	contracts contracts-validate contracts-generate contracts-clean \
	container-build container-build-amd64 container-build-arm64 container-push container-clean \
	container-build-control-plane container-build-connector-gateway container-build-execution-plane container-build-agent container-build-indexer \
	lint lint-go lint-rust lint-ts fmt fmt-go fmt-rust fmt-ts

help:
	@echo "AI Workflow Governance Platform - Make Targets"
	@echo ""
	@echo "Quick Start:"
	@echo "  make dev                      Start full dev environment (docker + services)"
	@echo "  make smoke-test               Run smoke tests on dev environment"
	@echo ""
	@echo "Development:"
	@echo "  make dev-up                   Start docker containers (Postgres, Redis, MinIO)"
	@echo "  make dev-down                 Stop docker containers"
	@echo "  make dev-logs [SERVICE=name]  View container logs (SERVICE=postgres|redis|minio)"
	@echo "  make dev-status               Show container status"
	@echo "  make dev-reset                Stop containers and remove volumes (fresh start)"
	@echo ""
	@echo "Build:"
	@echo "  make build                    Build all services (Go, Rust, TS)"
	@echo ""
	@echo "Container Images:"
	@echo "  make container-build          Build all service images (amd64 + arm64)"
	@echo "  make container-build-amd64    Build images for amd64 only (faster)"
	@echo "  make container-build-arm64    Build images for arm64 only"
	@echo "  make container-push           Push images to registry (requires registry config)"
	@echo "  make container-clean          Remove all local images"
	@echo ""
	@echo "Individual service images:"
	@echo "  make container-build-control-plane"
	@echo "  make container-build-connector-gateway"
	@echo "  make container-build-execution-plane"
	@echo "  make container-build-agent"
	@echo "  make container-build-indexer"
	@echo ""
	@echo "Code Quality & Linting:"
	@echo "  make lint                     Run all linters (Go, Rust, TypeScript)"
	@echo "  make lint-go                  Run golangci-lint on Go services"
	@echo "  make lint-rust                Run cargo clippy on Rust services"
	@echo "  make lint-ts                  Run ESLint on TypeScript/JavaScript"
	@echo "  make fmt                      Format all code (Go, Rust, TypeScript)"
	@echo "  make fmt-go                   Format Go code (gofmt, goimports)"
	@echo "  make fmt-rust                 Format Rust code (rustfmt)"
	@echo "  make fmt-ts                   Format TypeScript/JavaScript (prettier)"
	@echo ""
	@echo "Contracts:"
	@echo "  make contracts                Validate and regenerate all contract stubs"
	@echo "  make contracts-validate       Validate OpenAPI, JSON schemas, connector manifests"
	@echo "  make contracts-generate       Regenerate OpenAPI stubs, event validators"
	@echo "  make contracts-clean          Remove generated files (regenerate on next make contracts)"
	@echo ""
	@echo "Version Management:"
	@echo "  make version                  Show current version"
	@echo "  make version-bump-patch       Bump patch version (0.1.0 → 0.1.1)"
	@echo "  make version-bump-minor       Bump minor version (0.1.0 → 0.2.0)"
	@echo "  make version-bump-major       Bump major version (0.1.0 → 1.0.0)"
	@echo "  make version-tag              Create git tag for current version"
	@echo "  make version-tags             Show component Docker tags"
	@echo ""
	@echo "Release:"
	@echo "  See RELEASE-CHECKLIST.md for full release workflow"
	@echo ""
	@echo "Documentation:"
	@echo "  See docs/START-HERE.md for quick start"
	@echo "  See VERSIONING-QUICKSTART.md for version management"
	@echo "  See docs/CONTRACTS.md for contract workflow"

# Development environment commands
dev: dev-up build smoke-test
	@echo ""
	@echo "✓ Development environment is ready!"
	@echo ""
	@echo "Available services:"
	@echo "  PostgreSQL:        localhost:5432 (user: postgres, password: postgres)"
	@echo "  Redis:             localhost:6379"
	@echo "  MinIO S3:          localhost:9000 (console: http://localhost:9001)"
	@echo "  MinIO Console:     http://localhost:9001 (user: minio, password: minio123)"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Review docs/START-HERE.md for architecture overview"
	@echo "  2. Implement your first feature or workflow"
	@echo "  3. See VERSIONING-QUICKSTART.md for release process"

dev-up:
	@echo "Starting development infrastructure..."
	docker-compose up -d
	@echo "Waiting for services to be healthy..."
	@sleep 5
	@docker-compose ps

dev-down:
	@echo "Stopping development infrastructure..."
	docker-compose down

dev-logs:
	@if [ -z "$(SERVICE)" ]; then \
		docker-compose logs -f; \
	else \
		docker-compose logs -f $(SERVICE); \
	fi

dev-status:
	@echo "Container Status:"
	@docker-compose ps
	@echo ""
	@echo "Health Check Summary:"
	@echo -n "  PostgreSQL: "; docker-compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1 && echo "✓ OK" || echo "✗ Not ready"
	@echo -n "  Redis:      "; docker-compose exec -T redis redis-cli ping > /dev/null 2>&1 && echo "✓ OK" || echo "✗ Not ready"
	@echo -n "  MinIO:      "; curl -s -f http://localhost:9000/minio/health/live > /dev/null 2>&1 && echo "✓ OK" || echo "✗ Not ready"

dev-reset:
	@echo "Resetting development environment (removing volumes)..."
	docker-compose down -v
	@echo "✓ Development environment reset. Run 'make dev' to restart."

smoke-test:
	@echo "Running smoke tests..."
	@chmod +x ./smoke-test.sh
	@./smoke-test.sh

build:
	cd services/control-plane && go build ./...
	cd services/connector-gateway && go build ./...
	cd services/execution-plane && cargo build
	cd services/agent && cargo build

version:
	@./version.sh show

version-show:
	@./version.sh show

version-bump-patch:
	./version.sh bump patch

version-bump-minor:
	./version.sh bump minor

version-bump-major:
	./version.sh bump major

version-tag:
	./version.sh tag

version-tags:
	@./version.sh tags

# Contract validation and generation
contracts: contracts-validate contracts-generate
	@echo ""
	@echo "✓ All contracts validated and stubs regenerated"
	@echo ""
	@echo "Check git diff to see generated changes:"
	@echo "  git diff services/ apps/"
	@echo ""
	@echo "Verify uncommitted generated files:"
	@echo "  git status | grep generated"

contracts-validate:
	@echo "Validating contract files..."
	@chmod +x ./scripts/validate-contracts.sh
	@./scripts/validate-contracts.sh

contracts-generate:
	@echo "Generating contract stubs..."
	@chmod +x ./scripts/generate-contracts.sh
	@./scripts/generate-contracts.sh
	@echo "✓ Contract stubs generated"
	@echo ""
	@echo "Regenerated files:"
	@echo "  - services/*/generated/ (OpenAPI server stubs)"
	@echo "  - apps/web/generated/ (OpenAPI client + types)"
	@echo "  - contracts/generated/ (event validators, connector loaders)"

contracts-clean:
	@echo "Removing generated contract files..."
	@find services -type d -name "generated" -exec rm -rf {} + 2>/dev/null || true
	@find apps -type d -name "generated" -exec rm -rf {} + 2>/dev/null || true
	@find contracts -type d -name "generated" -exec rm -rf {} + 2>/dev/null || true
	@echo "✓ Generated files removed"
	@echo "Run 'make contracts' to regenerate"

# ===== Container Build Targets =====

DOCKER_REGISTRY ?= ghcr.io/aic-sos
DOCKER_TAGS ?= latest,v${VERSION}
BUILD_PLATFORMS ?= linux/amd64

.PHONY: container-build-control-plane
container-build-control-plane:
	@echo "Building control-plane (${BUILD_PLATFORMS})..."
	docker buildx build \
		--platform ${BUILD_PLATFORMS} \
		--tag ${DOCKER_REGISTRY}/control-plane:latest \
		--tag ${DOCKER_REGISTRY}/control-plane:v${VERSION} \
		--file services/control-plane/Dockerfile \
		--progress=plain \
		services/control-plane

.PHONY: container-build-connector-gateway
container-build-connector-gateway:
	@echo "Building connector-gateway (${BUILD_PLATFORMS})..."
	docker buildx build \
		--platform ${BUILD_PLATFORMS} \
		--tag ${DOCKER_REGISTRY}/connector-gateway:latest \
		--tag ${DOCKER_REGISTRY}/connector-gateway:v${VERSION} \
		--file services/connector-gateway/Dockerfile \
		--progress=plain \
		services/connector-gateway

.PHONY: container-build-execution-plane
container-build-execution-plane:
	@echo "Building execution-plane (${BUILD_PLATFORMS})..."
	docker buildx build \
		--platform ${BUILD_PLATFORMS} \
		--tag ${DOCKER_REGISTRY}/execution-plane:latest \
		--tag ${DOCKER_REGISTRY}/execution-plane:v${VERSION} \
		--file services/execution-plane/Dockerfile \
		--progress=plain \
		services/execution-plane

.PHONY: container-build-agent
container-build-agent:
	@echo "Building agent (${BUILD_PLATFORMS})..."
	docker buildx build \
		--platform ${BUILD_PLATFORMS} \
		--tag ${DOCKER_REGISTRY}/agent:latest \
		--tag ${DOCKER_REGISTRY}/agent:v${VERSION} \
		--file services/agent/Dockerfile \
		--progress=plain \
		services/agent

.PHONY: container-build-indexer
container-build-indexer:
	@echo "Building indexer (${BUILD_PLATFORMS})..."
	docker buildx build \
		--platform ${BUILD_PLATFORMS} \
		--tag ${DOCKER_REGISTRY}/indexer:latest \
		--tag ${DOCKER_REGISTRY}/indexer:v${VERSION} \
		--file services/indexer/Dockerfile \
		--progress=plain \
		services/indexer

.PHONY: container-build-amd64
container-build-amd64:
	@echo "Building all containers for linux/amd64..."
	$(MAKE) BUILD_PLATFORMS=linux/amd64 container-build-control-plane
	$(MAKE) BUILD_PLATFORMS=linux/amd64 container-build-connector-gateway
	$(MAKE) BUILD_PLATFORMS=linux/amd64 container-build-execution-plane
	$(MAKE) BUILD_PLATFORMS=linux/amd64 container-build-agent
	$(MAKE) BUILD_PLATFORMS=linux/amd64 container-build-indexer
	@echo "✓ All containers built for amd64"

.PHONY: container-build-arm64
container-build-arm64:
	@echo "Building all containers for linux/arm64..."
	$(MAKE) BUILD_PLATFORMS=linux/arm64 container-build-control-plane
	$(MAKE) BUILD_PLATFORMS=linux/arm64 container-build-connector-gateway
	$(MAKE) BUILD_PLATFORMS=linux/arm64 container-build-execution-plane
	$(MAKE) BUILD_PLATFORMS=linux/arm64 container-build-agent
	$(MAKE) BUILD_PLATFORMS=linux/arm64 container-build-indexer
	@echo "✓ All containers built for arm64"

.PHONY: container-build
container-build: container-build-amd64
	@echo "✓ Container build complete (linux/amd64)"
	@echo ""
	@echo "To build for multiple architectures:"
	@echo "  make BUILD_PLATFORMS='linux/amd64,linux/arm64' container-build"
	@echo ""
	@echo "To push images to registry:"
	@echo "  make container-push"
	@echo ""
	@echo "To load images into local Docker:"
	@echo "  docker buildx build --load --platform linux/amd64 -t control-plane:local services/control-plane"

.PHONY: container-push
container-push:
	@echo "Pushing container images to ${DOCKER_REGISTRY}..."
	@echo "Note: Requires docker login and buildx with push capability"
	@echo ""
	@echo "Example:"
	@echo "  docker buildx build --push --platform linux/amd64,linux/arm64 \\"
	@echo "    -t ${DOCKER_REGISTRY}/control-plane:v${VERSION} \\"
	@echo "    services/control-plane"
	@echo ""
	@echo "Or use: make BUILD_PLATFORMS='linux/amd64,linux/arm64' container-push"

.PHONY: container-clean
container-clean:
	@echo "Cleaning container build cache..."
	docker buildx prune --force
	@echo "✓ Container build cache cleaned"
	@echo ""
	@echo "To remove built images, use:"
	@echo "  docker rmi ${DOCKER_REGISTRY}/*:latest"

# ===== Linting & Code Quality Targets =====

.PHONY: lint
lint: lint-go lint-rust lint-ts
	@echo "✓ All linters passed"

.PHONY: lint-go
lint-go:
	@echo "Linting Go code with golangci-lint..."
	@if command -v golangci-lint &> /dev/null; then \
		golangci-lint run ./services/control-plane ./services/connector-gateway ./services/indexer; \
	else \
		echo "⚠ golangci-lint not installed. Install with:"; \
		echo "  https://golangci-lint.run/usage/install/"; \
		echo "  Or run: go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest"; \
		exit 1; \
	fi
	@echo "✓ Go linting complete"

.PHONY: lint-rust
lint-rust:
	@echo "Linting Rust code with cargo clippy..."
	@if [ -f services/execution-plane/Cargo.toml ] || [ -f services/agent/Cargo.toml ]; then \
		cd services/execution-plane && cargo clippy --all-targets --all-features -- -D warnings; \
		cd ../agent && cargo clippy --all-targets --all-features -- -D warnings; \
	else \
		echo "⚠ No Rust services found"; \
	fi
	@echo "✓ Rust linting complete"

.PHONY: lint-ts
lint-ts:
	@echo "Linting TypeScript/JavaScript code with ESLint..."
	@if command -v eslint &> /dev/null; then \
		eslint apps/web --ext .ts,.tsx,.js,.jsx; \
	elif [ -f apps/web/node_modules/.bin/eslint ]; then \
		apps/web/node_modules/.bin/eslint apps/web --ext .ts,.tsx,.js,.jsx; \
	else \
		echo "⚠ ESLint not installed. Install with:"; \
		echo "  cd apps/web && npm install"; \
		exit 1; \
	fi
	@echo "✓ TypeScript/JavaScript linting complete"

.PHONY: fmt
fmt: fmt-go fmt-rust fmt-ts
	@echo "✓ All code formatted"

.PHONY: fmt-go
fmt-go:
	@echo "Formatting Go code with gofmt and goimports..."
	@if command -v goimports &> /dev/null; then \
		goimports -w ./services/control-plane ./services/connector-gateway ./services/indexer; \
	else \
		echo "⚠ goimports not installed. Install with:"; \
		echo "  go install golang.org/x/tools/cmd/goimports@latest"; \
		gofmt -w ./services/control-plane ./services/connector-gateway ./services/indexer; \
	fi
	@echo "✓ Go formatting complete"

.PHONY: fmt-rust
fmt-rust:
	@echo "Formatting Rust code with rustfmt..."
	@if [ -f services/execution-plane/Cargo.toml ] || [ -f services/agent/Cargo.toml ]; then \
		cd services/execution-plane && cargo fmt; \
		cd ../agent && cargo fmt; \
	else \
		echo "⚠ No Rust services found"; \
	fi
	@echo "✓ Rust formatting complete"

.PHONY: fmt-ts
fmt-ts:
	@echo "Formatting TypeScript/JavaScript code with Prettier..."
	@if command -v prettier &> /dev/null; then \
		prettier --write apps/web; \
	elif [ -f apps/web/node_modules/.bin/prettier ]; then \
		apps/web/node_modules/.bin/prettier --write apps/web; \
	else \
		echo "⚠ Prettier not installed. Install with:"; \
		echo "  cd apps/web && npm install"; \
		exit 1; \
	fi
	@echo "✓ TypeScript/JavaScript formatting complete"
