FROM debian:bullseye-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    bash \
    jq \
    dialog \
    nano \
    git \
    vim \
    findutils \
    sed \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy repository contents
COPY . /app

# Make all scripts executable
RUN find . -type f -name "*.sh" -exec chmod +x {} \;

# Run the docker installation script
RUN chmod +x /app/scripts/docker_install.sh && \
    /app/scripts/docker_install.sh

# Add better welcome message with clear instructions
RUN echo "# AliasMate welcome message" > /root/.welcome.sh && \
    echo 'echo ""' >> /root/.welcome.sh && \
    echo 'echo -e "┌──────────────────────────────────────┐"' >> /root/.welcome.sh && \
    echo 'echo -e "│    AliasMate Test Environment        │"' >> /root/.welcome.sh && \
    echo 'echo -e "└──────────────────────────────────────┘"' >> /root/.welcome.sh && \
    echo 'echo ""' >> /root/.welcome.sh && \
    echo 'echo -e "Commands to try:"' >> /root/.welcome.sh && \
    echo 'echo -e "  • aliasmate --help     # Show help"' >> /root/.welcome.sh && \
    echo 'echo -e "  • aliasmate --tui      # Launch TUI"' >> /root/.welcome.sh && \
    echo 'echo -e "  • am --version         # Show version (shortcut alias)"' >> /root/.welcome.sh && \
    echo 'echo -e "  • test-aliasmate       # Run test script"' >> /root/.welcome.sh && \
    echo 'echo ""' >> /root/.welcome.sh && \
    chmod +x /root/.welcome.sh && \
    echo "source /root/.welcome.sh" >> /root/.bashrc

# Set bash as default shell and make it source .bashrc
RUN echo '[ -f ~/.bashrc ] && source ~/.bashrc' > /root/.bash_profile

# Use bash login shell as entrypoint to ensure .bashrc is sourced
ENTRYPOINT ["/bin/bash", "-l"]
