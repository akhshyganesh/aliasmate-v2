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
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone and setup the repository
COPY . /app
RUN chmod +x /app/scripts/docker_install.sh && \
    /app/scripts/docker_install.sh

# Add welcome message
RUN echo "echo ''" >> /root/.bashrc
RUN echo "echo 'AliasMate Test Environment'" >> /root/.bashrc
RUN echo "echo '======================'" >> /root/.bashrc
RUN echo "echo 'Try: aliasmate --help'" >> /root/.bashrc
RUN echo "echo ''" >> /root/.bashrc

# Use bash as entrypoint
ENTRYPOINT ["/bin/bash"]
