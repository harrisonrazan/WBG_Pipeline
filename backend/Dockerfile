# Use Python 3.9 slim image as our base
# The slim version provides a good balance between image size and functionality
FROM python:3.9-slim

# Set working directory in the container
WORKDIR /app

# Copy just the requirements file first
COPY requirements.txt .

# Install system dependencies and Python packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-client \
        dos2unix \ 
    && rm -rf /var/lib/apt/lists/* \
    && pip install --no-cache-dir -r requirements.txt

# Copy the rest of our application
COPY . .

# Fix line endings for shell scripts
RUN dos2unix scripts/start.sh && chmod +x scripts/start.sh

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

# Use the startup script
CMD ["/bin/bash", "./scripts/start.sh"]