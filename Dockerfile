FROM debian:bullseye-slim

# Install minimal dependencies
RUN apt-get update && apt-get install -y \
    curl \
    bash \
    jq \
    dialog \
    nano \
    git \
    && rm -rf /var/lib/apt/lists/*

# Create a working directory
WORKDIR /app

# Clone the repository and install
RUN git clone https://github.com/akhshyganesh/aliasmate-v2.git && \
    cd aliasmate-v2 && \
    chmod +x scripts/docker_install.sh && \
    ./scripts/docker_install.sh

# Add a welcome message
RUN echo "echo 'Welcome to AliasMate Docker image!" >> /root/.bashrc
RUN echo "echo 'Run \"aliasmate --help\" to get started.'" >> /root/.bashrc

# Set entrypoint to bash
ENTRYPOINT ["/bin/bash"]
