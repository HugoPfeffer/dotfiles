# Download and install nvm:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# in lieu of restarting the shell
\. "$HOME/.nvm/nvm.sh"

# Download and install Node.js:
nvm install 22

# Verify the Node.js version:
node -v # Should print "v22.18.0".
nvm current # Should print "v22.18.0".

# Verify npm version:
npm -v # Should print "10.9.3".

########################################################

# update & upgrade
sudo dnf update -y
sudo dnf upgrade -y

# Install development tools
sudo dnf install -y openssl-devel bzip2-devel libffi-devel wget tar gcc make
sudo dnf groupinstall "Development Tools" -y

# Install python 3.11
sudo dnf install python3.11 -y

# Install python 3.12
sudo dnf install python3.12 -y

# Add Python versions to alternatives
sudo alternatives --install /usr/bin/python python /usr/bin/python3.11 200
sudo alternatives --install /usr/bin/python python /usr/bin/python3.12 300
sudo alternatives --set python /usr/bin/python3.12

# Install uv and uvx
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Install Gemini-CLI
npm install -g @google/gemini-cli

# Install Claude Code
npm install -g @anthropic-ai/claude-code
