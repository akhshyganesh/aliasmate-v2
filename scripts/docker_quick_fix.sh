#!/usr/bin/env bash
# Quick fix for Docker installation issues

echo "Fixing AliasMate Docker installation..."

# Create scripts directory
mkdir -p /usr/local/share/aliasmate

# Fix main executable
cat > /usr/local/bin/aliasmate << 'EOF'
#!/usr/bin/env bash
# Fixed wrapper for AliasMate

SCRIPTS_DIR="/usr/local/share/aliasmate"
cd "$SCRIPTS_DIR"
exec bash "$SCRIPTS_DIR/main.sh" "$@"
EOF
chmod +x /usr/local/bin/aliasmate

# Copy scripts to the right location
if [ -d "/usr/local/bin/aliasmate-scripts" ]; then
    cp -r /usr/local/bin/aliasmate-scripts/* /usr/local/share/aliasmate/
elif [ -d "/usr/local/bin" ]; then
    # Look for script files directly in /usr/local/bin
    find /usr/local/bin -maxdepth 1 -name "*.sh" -exec cp {} /usr/local/share/aliasmate/ \;
    
    # Copy core directory if it exists
    if [ -d "/usr/local/bin/core" ]; then
        mkdir -p /usr/local/share/aliasmate/core
        cp -r /usr/local/bin/core/* /usr/local/share/aliasmate/core/
    fi
fi

# Make everything executable
find /usr/local/share/aliasmate -type f -name "*.sh" -exec chmod +x {} \;

# Create am alias
if ! grep -q "alias am=" /root/.bashrc; then
    echo -e "\n# AliasMate shortcut alias" >> /root/.bashrc
    echo "alias am='aliasmate'" >> /root/.bashrc
fi

# Source .bashrc
echo "source ~/.bashrc"
echo "Installation fixed! Try: aliasmate --help"
