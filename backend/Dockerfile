# Use Python 3.9 slim image as our base
# The slim version provides a good balance between image size and functionality
FROM python:3.9-slim

# Set working directory in the container
# This is where our application code will live
WORKDIR /app

# Copy just the requirements file first
# This is a Docker best practice that allows us to cache pip install
COPY requirements.txt .

# Install system dependencies if needed (like postgresql-client)
# Then install Python packages
# The pip install command is configured to:
# - Use no cache to keep the image size down
# - Install in the main Python environment
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-client \
    && rm -rf /var/lib/apt/lists/* \
    && pip install --no-cache-dir -r requirements.txt

# Copy the rest of our application
# This happens after pip install to leverage Docker's cache
COPY . .

# Set environment variables
# PYTHONUNBUFFERED ensures our print statements are output properly
# PYTHONPATH helps Python find our application modules
ENV PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app

# Command to run the application
# We use 'python -m uvicorn' instead of just 'uvicorn' because:
# 1. It ensures we're using the Python interpreter we installed uvicorn with
# 2. It properly sets up the Python path
CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]