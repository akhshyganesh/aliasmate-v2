# AliasMate v2 - Test Environment Dockerfile
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    jq \
    python3 \
    python3-pip \
    git \
    shellcheck \
    bc \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip3 install pyyaml

# Set working directory
WORKDIR /app

# Copy project files - we'll use the local files rather than downloading
COPY . .

# Make scripts executable
RUN chmod -R +x /app/scripts/*.sh /app/src/*.sh

# Environment variables
ENV ALIASMATE_TEST_MODE=true

# Entrypoint
ENTRYPOINT ["/bin/bash"]
