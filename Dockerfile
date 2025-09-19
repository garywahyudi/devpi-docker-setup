FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install devpi server, web UI, and client CLI
RUN pip install --no-cache-dir devpi-server devpi-web devpi-client

WORKDIR /app
VOLUME ["/data"]
EXPOSE 3141

# Copy scripts
COPY init.sh /app/init.sh
RUN chmod +x /app/init.sh

# Use init.sh as entrypoint
ENTRYPOINT ["/app/init.sh"]
