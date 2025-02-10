# Makefile for managing the application lifecycle
# The .PHONY declaration tells Make these are commands, not files
.PHONY: help setup start stop restart build rebuild clean logs test

# Default target when just running 'make'
help:
	@echo "Available commands:"
	@echo "  make setup    - Initialize environment and project setup"
	@echo "  make build    - Build all Docker containers"
	@echo "  make rebuild  - Force rebuild all Docker containers from scratch"
	@echo "  make start    - Start all services"
	@echo "  make stop     - Stop all services"
	@echo "  make restart  - Restart all services"
	@echo "  make logs     - View logs from all services"
	@echo "  make clean    - Remove all containers, volumes, and build cache"
	@echo "  make test     - Run tests across all services"

# Initialize project setup
setup:
	@echo "Setting up project environment..."
	@chmod +x scripts/setup-env.sh
	@./scripts/setup-env.sh

# Build all containers
build:
	@echo "Building Docker containers..."
	docker-compose build

# Force rebuild all containers from scratch
rebuild:
	@echo "Force rebuilding all containers..."
	docker-compose build --no-cache

# Start all services
start:
	@echo "Starting all services..."
	docker-compose up -d

# Stop all services
stop:
	@echo "Stopping all services..."
	docker-compose down

# Restart services
restart: stop start

# View logs
logs:
	@echo "Showing logs from all services..."
	docker-compose logs -f

# Clean up everything
clean:
	@echo "Cleaning up containers, volumes, and build cache..."
	docker-compose down -v
	docker system prune -af --volumes

# Run tests
test:
	@echo "Running tests..."
	docker-compose exec backend pytest
	docker-compose exec frontend npm test

# Individual service commands
.PHONY: backend frontend pipeline db

# Build and start individual services
backend:
	@echo "Building and starting backend service..."
	docker-compose up -d --build backend
	docker-compose logs -f backend

frontend:
	@echo "Building and starting frontend service..."
	docker-compose up -d --build frontend
	docker-compose logs -f frontend

pipeline:
	@echo "Building and starting pipeline service..."
	docker-compose up -d --build pipeline
	docker-compose logs -f pipeline

db:
	@echo "Building and starting database service..."
	docker-compose up -d --build postgres
	docker-compose logs -f postgres