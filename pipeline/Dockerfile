FROM python:3.9

# Install Chromium and dependencies
RUN apt-get update && apt-get install -y \
    chromium \
    chromium-driver \
    libatk-bridge2.0-0 \
    libgtk-3-0 \
    libnss3 \
    libx11-xcb1 \
    libxss1 \
    libasound2 \
    fonts-freefont-ttf \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Tell pyppeteer to use the installed Chromium
ENV PYPPETEER_NO_DOWNLOAD=1
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

WORKDIR /app

# Cache requirements installation
COPY requirements.txt .
RUN pip install -r requirements.txt

# Create cache directory for HTML files
RUN mkdir -p /app/wb_html_cache && chmod 777 /app/wb_html_cache

# Copy application code
COPY . .

# Run the pipeline
CMD ["python", "src/pipeline.py"]