#!/bin/bash
# Setup script to install development tools in the ubuntu-desktop container
# Run with: ./isoclaude.sh setup

set -e

echo "=== Updating package lists ==="
apt-get update

echo "=== Installing prerequisites ==="
apt-get install -y \
    software-properties-common \
    curl \
    wget \
    gnupg \
    ca-certificates \
    build-essential \
    libffi-dev \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libncurses5-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    liblzma-dev

echo "=== Adding deadsnakes PPA for Python versions ==="
add-apt-repository -y ppa:deadsnakes/ppa
apt-get update

echo "=== Installing Python 3.12 with tkinter ==="
apt-get install -y python3.12 python3.12-venv python3.12-dev python3.12-tk

echo "=== Installing Python 3.13 with tkinter ==="
apt-get install -y python3.13 python3.13-venv python3.13-dev python3.13-tk

echo "=== Installing pip for both Python versions ==="
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.12
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.13

echo "=== Installing Poetry ==="
curl -sSL https://install.python-poetry.org | python3.12 -

# Add poetry to PATH
POETRY_PATH='export PATH="/config/.local/bin:$PATH"'
if ! grep -q "poetry" /config/.bashrc 2>/dev/null; then
    echo "$POETRY_PATH" >> /config/.bashrc
fi
echo 'export PATH="/config/.local/bin:$PATH"' > /etc/profile.d/poetry.sh

# Add clauded alias for skipping permissions
if ! grep -q "clauded" /config/.bashrc 2>/dev/null; then
    echo 'alias clauded="claude --dangerously-skip-permissions"' >> /config/.bashrc
fi

echo "=== Installing Rust ==="
# Install Rust for abc user
su - abc -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"

echo "=== Installing Node.js and Claude Code CLI ==="
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
npm install -g @anthropic-ai/claude-code

echo "=== Installing VS Code ==="
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/packages.microsoft.gpg
# Detect architecture for VS Code package
ARCH=$(dpkg --print-architecture)
echo "deb [arch=${ARCH} signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list
apt-get update
apt-get install -y code

echo "=== Installing VS Code extensions ==="
# Run as abc user since VS Code extensions install to user profile
su - abc -c "code --install-extension ms-python.python"
su - abc -c "code --install-extension ms-python.debugpy"
su - abc -c "code --install-extension rust-lang.rust-analyzer"
su - abc -c "code --install-extension anthropic.claude-code"

echo "=== Setting up SSH server ==="
apt-get install -y openssh-server
mkdir -p /var/run/sshd

# Configure SSH for the abc user (default webtop user)
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config

# Set password for abc user if not already set (default: isoclaude)
echo "abc:isoclaude" | chpasswd

# Ensure abc user has a proper shell
usermod -s /bin/bash abc

# Create startup script for SSH (linuxserver.io uses s6-overlay)
# Scripts in /config/custom-cont-init.d are run on container start
mkdir -p /config/custom-cont-init.d
cat > /config/custom-cont-init.d/99-start-ssh << 'SSHSCRIPT'
#!/bin/bash
mkdir -p /var/run/sshd
/usr/sbin/sshd
SSHSCRIPT
chmod +x /config/custom-cont-init.d/99-start-ssh

# Start SSH now
mkdir -p /var/run/sshd
/usr/sbin/sshd || true

echo "=== Verifying installations ==="
echo "Python 3.12: $(python3.12 --version)"
echo "Python 3.13: $(python3.13 --version)"
echo "Poetry: $(/config/.local/bin/poetry --version 2>/dev/null || echo 'run: source ~/.bashrc')"
echo "Rust: $(su - abc -c 'source ~/.cargo/env && rustc --version' 2>/dev/null || echo 'run: source ~/.cargo/env')"
echo "Node.js: $(node --version)"
echo "Claude: $(claude --version)"
echo "VS Code extensions: Python, Python Debugger, Rust Analyzer, Claude Code"

echo ""
echo "=== Setup complete! ==="
echo "Projects mounted at: /projects/"
echo "Access desktop at: http://localhost:3000"
echo "SSH access: ssh abc@localhost -p 2222 (password: isoclaude)"
echo ""
echo "All installations persist across restarts"
echo "IMPORTANT: Change the default SSH password with 'passwd abc'"

exit 0
