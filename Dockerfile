# ============================================================
# DocIntel: PDF Analysis System for Adobe Hackathon
# Author: Vishal Kumar Sahu
# Version: 2.0.0
# ============================================================

# Use Alpine-based Python image for minimal vulnerabilities
FROM python:3.9-alpine3.18

# Add security and tracking labels
LABEL maintainer="Vishal Kumar Sahu" \
      description="Adobe Hackathon PDF Analysis System" \
      version="2.0.0" \
      security.updates="true"

# Set working directory
WORKDIR /app

# Install system dependencies and security updates
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
        gcc \
        musl-dev \
        python3-dev \
        libffi-dev \
        openssl-dev \
        make \
        g++ \
        jpeg-dev \
        zlib-dev \
        libpng-dev \
        freetype-dev \
    && rm -rf /var/cache/apk/*

# Install Python packages with security considerations
ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONUNBUFFERED=1

# Upgrade pip and install basic requirements
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir torch --index-url https://download.pytorch.org/whl/cpu

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && \
    pip check # Verify dependencies for security

# Download model for offline use
COPY download_model.py .
RUN python download_model.py

# Copy the rest of the application code
COPY . .

# Set environment variables for better security
ENV INPUT_DIR=/app/input \
    OUTPUT_DIR=/app/output \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100

# Create required directories with proper permissions
RUN mkdir -p /app/input /app/output /app/input/PDFs && \
    chmod -R 755 /app

# Create non-root user with specific UID/GID for better security
RUN groupadd -g 10001 appgroup && \
    useradd -u 10001 -g appgroup -s /sbin/nologin -m appuser && \
    chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser:appgroup

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import os; exit(0 if os.path.exists('/app') else 1)"

# Run application
CMD ["python", "main.py"]