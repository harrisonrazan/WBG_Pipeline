#!/bin/bash

# Check if .env file exists
if [ ! -f .env ]; then
    echo "Creating new .env file..."
    # Generate a secure random password
    RANDOM_PASSWORD=$(openssl rand -base64 16)
    
    # Create .env file with default values
    cat > .env << EOF
# Application Ports
FRONTEND_PORT=3000
BACKEND_PORT=8000
API_URL=http://localhost:8000

# PostgreSQL Configuration
POSTGRES_USER=admin
POSTGRES_PASSWORD=$RANDOM_PASSWORD
POSTGRES_DB=pipeline_db
POSTGRES_PORT=5432
POSTGRES_HOST=postgres

# Pipeline Configuration
DATA_SOURCE_URL=https://your-data-source.com/data.csv
DATA_FETCH_INTERVAL=3600  # in seconds (1 hour)

# Connection string templates
# Note: Inside containers, use 'postgres' as host. For external connections, use 'localhost'
DATABASE_URL=postgresql://\${POSTGRES_USER}:\${POSTGRES_PASSWORD}@\${POSTGRES_HOST}:\${POSTGRES_PORT}/\${POSTGRES_DB}
EOF
    
    echo ".env file created with a secure random password"
else
    echo ".env file already exists"
fi

# Create .env.example for documentation
cat > .env.example << EOF
# Application Ports
FRONTEND_PORT=3000
BACKEND_PORT=8000
API_URL=http://localhost:8000

# PostgreSQL Configuration
POSTGRES_USER=admin
POSTGRES_PASSWORD=your_secure_password_here
POSTGRES_DB=pipeline_db
POSTGRES_PORT=5432
POSTGRES_HOST=postgres

# Pipeline Configuration
DATA_SOURCE_URL=https://your-data-source.com/data.csv
DATA_FETCH_INTERVAL=3600  # in seconds (1 hour)

# Connection string templates
# Note: Inside containers, use 'postgres' as host. For external connections, use 'localhost'
DATABASE_URL=postgresql://\${POSTGRES_USER}:\${POSTGRES_PASSWORD}@\${POSTGRES_HOST}:\${POSTGRES_PORT}/\${POSTGRES_DB}
EOF

# Set proper permissions for .env file
chmod 600 .env

echo "Environment setup complete!"