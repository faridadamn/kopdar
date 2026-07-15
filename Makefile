# =============================================================================
# KopDar — Makefile
# =============================================================================

.PHONY: help dev dev-down dev-logs build build-backend build-admin \
        test test-backend test-admin db-migrate db-seed db-reset \
        deploy-staging deploy-prod clean

# Default target
.DEFAULT_GOAL := help

# Docker compose command (use docker compose v2 if available)
COMPOSE := docker compose

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------
help: ## Show this help
	@echo ""
	@echo "KopDar — Development Commands"
	@echo "=============================="
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""

# ---------------------------------------------------------------------------
# Development
# ---------------------------------------------------------------------------
dev: ## Start all services (docker-compose up -d)
	$(COMPOSE) up -d
	@echo ""
	@echo "✅ Services started!"
	@echo "   Backend:  http://localhost:8080"
	@echo "   Admin:    http://localhost:3000"
	@echo "   Postgres: localhost:5432"
	@echo "   Redis:    localhost:6379"

dev-down: ## Stop all services
	$(COMPOSE) down

dev-logs: ## Follow logs from all services
	$(COMPOSE) logs -f

dev-restart: ## Restart all services
	$(COMPOSE) restart

dev-ps: ## Show running services
	$(COMPOSE) ps

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------
build: build-backend build-admin ## Build all Docker images

build-backend: ## Build backend image
	$(COMPOSE) build backend

build-admin: ## Build admin image
	$(COMPOSE) build admin

# ---------------------------------------------------------------------------
# Test
# ---------------------------------------------------------------------------
test: test-backend test-admin ## Run all tests

test-backend: ## Run backend (Go) tests
	cd backend && go test -v -race ./...

test-backend-coverage: ## Run backend tests with coverage
	cd backend && go test -v -race -coverprofile=coverage.out ./...
	cd backend && go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report: backend/coverage.html"

test-admin: ## Run admin (React) tests
	cd admin && npm test -- --watchAll=false

test-flutter: ## Run Flutter tests
	cd mobile && flutter test

# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------
db-migrate: ## Run database migrations
	$(COMPOSE) exec backend /usr/local/bin/server migrate up

db-seed: ## Seed database with sample data
	$(COMPOSE) exec postgres bash /docker-entrypoint-initdb.d/init-db.sh --seed

db-reset: ## Drop + recreate + migrate + seed (⚠️ destructive)
	@echo "⚠️  This will destroy all data in the database!"
	@read -p "Continue? [y/N]: " confirm && [ "$$confirm" = "y" ] || exit 1
	$(COMPOSE) down -v
	$(COMPOSE) up -d postgres
	@echo "Waiting for PostgreSQL to be ready..."
	@sleep 5
	$(COMPOSE) up -d
	@echo "✅ Database reset complete."

db-shell: ## Open psql shell
	$(COMPOSE) exec postgres psql -U kopdar -d kopdar

# ---------------------------------------------------------------------------
# Lint
# ---------------------------------------------------------------------------
lint: lint-backend lint-admin ## Lint all code

lint-backend: ## Lint Go code
	cd backend && golangci-lint run

lint-admin: ## Lint React code
	cd admin && npm run lint

# ---------------------------------------------------------------------------
# Deploy (placeholders)
# ---------------------------------------------------------------------------
deploy-staging: ## Deploy to staging
	@echo "🚀 Deploying to staging..."
	@echo "TODO: Add staging deployment commands"
	@echo "  e.g., docker push to registry + kubectl apply"
	@exit 1

deploy-prod: ## Deploy to production
	@echo "🚀 Deploying to production..."
	@echo "TODO: Add production deployment commands"
	@echo "  e.g., docker push to registry + kubectl apply"
	@exit 1

# ---------------------------------------------------------------------------
# Clean
# ---------------------------------------------------------------------------
clean: ## Remove build artifacts and containers
	$(COMPOSE) down -v --remove-orphans
	docker system prune -f
	@echo "✅ Cleaned up."
