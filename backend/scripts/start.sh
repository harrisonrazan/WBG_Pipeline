#!/bin/bash
set -e  # Exit on any error

echo "Starting backend initialization..."

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL..."
until pg_isready -h postgres -p 5432; do
    echo "PostgreSQL is unavailable - sleeping"
    sleep 1
done

echo "PostgreSQL is up - executing initialization script..."

# Run the initialization script
python /app/app/initialize.py

if [ $? -eq 0 ]; then
    echo "Initialization successful - starting FastAPI application..."
    # Start FastAPI with reload enabled and access to the host network
    exec python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload --log-level info
else
    echo "Initialization failed - check the logs for details"
    exit 1
fi