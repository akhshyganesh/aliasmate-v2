FROM debian:bullseye-slim

# Install minimal dependencies
RUN apt-get update && apt-get install -y \
    curl \
    bash \
    jq \
    dialog \
    nano \
    git \
    vim \
    findutils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Debug info - list files before installation
RUN echo "Listing repository files:" && \
    find . -type f -name "*.sh" | sort || echo "No files found yet"

# Copy repository contents
COPY . /app

# Debug files in src directory
RUN echo "Files in src directory:" && \
    find ./src -type f -name "*.sh" | sort || echo "No src files found"

# Make all scripts executable first
RUN find . -type f -name "*.sh" -exec chmod +x {} \;

# Run the docker installation script
RUN chmod +x /app/scripts/docker_install.sh && \
    /app/scripts/docker_install.sh || \
    (echo "Installation failed. Debugging info:" && \
     find /usr/local/bin -type f -name "*.sh" | sort && \
     exit 1)

# Add welcome message
RUN echo "echo ''" >> /root/.bashrc
RUN echo "echo '┌──────────────────────────────────────┐'" >> /root/.bashrc
RUN echo "echo '│    AliasMate Test Environment        │'" >> /root/.bashrc
RUN echo "echo '└──────────────────────────────────────┘'" >> /root/.bashrc
RUN echo "echo ''" >> /root/.bashrc
RUN echo "echo 'Commands to try:'" >> /root/.bashrc
RUN echo "echo '  • aliasmate --help     # Show help'" >> /root/.bashrc
RUN echo "echo '  • aliasmate --tui      # Launch TUI'" >> /root/.bashrc
RUN echo "echo '  • am                   # Short alias for aliasmate'" >> /root/.bashrc
RUN echo "echo '  • test-aliasmate       # Test if aliasmate works'" >> /root/.bashrc
RUN echo "echo ''" >> /root/.bashrc

# Use bash as entrypoint
ENTRYPOINT ["/bin/bash"]
