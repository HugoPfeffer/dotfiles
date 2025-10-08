#!/bin/bash

# Script to automate Red Hat lab SSH key setup
# Usage: ./lab-access.sh <path/to/rht_classroom.rsa> [-n|--name <custom_name>] [-h|--help]

set -e

# Default key name
KEY_NAME="rht_classroom.rsa"
SSH_DIR="$HOME/.ssh"

# Parse arguments
show_usage() {
    echo "Usage: $0 <path/to/rht_classroom.rsa> [-n|--name <custom_name>] [-h|--help]"
    echo "Options:"
    echo "  -n, --name <name>    Specify a custom name for the key file (default: rht_classroom.rsa)"
    echo "  -h, --help           Display this help message and exit"
    echo ""
    echo "Examples:"
    echo "  $0 ~/Downloads/rht_classroom.rsa"
    echo "  $0 ~/Downloads/rht_classroom.rsa -n rhcsa_2.rsa"
    exit 1
}

# Display help if requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_usage
fi

# Check if at least one argument is provided
if [ $# -eq 0 ]; then
    show_usage
fi

KEY_PATH="$1"
shift

# Parse optional name argument
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            KEY_NAME="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            ;;
    esac
done

# Validate key file exists
if [ ! -f "$KEY_PATH" ]; then
    echo "Error: Key file not found at $KEY_PATH"
    exit 1
fi

# Create ~/.ssh directory if it doesn't exist
if [ ! -d "$SSH_DIR" ]; then
    echo "Creating $SSH_DIR directory..."
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
fi

# Move the key to ~/.ssh
DEST_KEY="$SSH_DIR/$KEY_NAME"
echo "Moving key to $DEST_KEY..."
cp "$KEY_PATH" "$DEST_KEY"

# Set correct permissions
echo "Setting permissions..."
chmod 0600 "$DEST_KEY"

# Add key to ssh-agent
echo "Adding key to ssh-agent..."
if ! ssh-add "$DEST_KEY" 2>/dev/null; then
    echo "Warning: Could not add key to ssh-agent. You may need to start ssh-agent first."
fi

# Setup alias in .bashrc
BASHRC="$HOME/.bashrc"
ALIAS_NAME="lab-ssh"
SSH_COMMAND="ssh -i ~/.ssh/$KEY_NAME -J cloud-user@148.62.93.250:22022 student@172.25.252.1 -p 53009"
ALIAS_LINE="alias $ALIAS_NAME=\"$SSH_COMMAND\""

echo "Setting up alias in $BASHRC..."

# Remove old alias if it exists
if grep -q "^alias $ALIAS_NAME=" "$BASHRC" 2>/dev/null; then
    echo "Removing old $ALIAS_NAME alias..."
    sed -i "/^alias $ALIAS_NAME=/d" "$BASHRC"
fi

# Add new alias
echo "$ALIAS_LINE" >> "$BASHRC"

# Source bashrc for current session
echo "Activating alias for current session..."
alias "$ALIAS_NAME"="$SSH_COMMAND"

echo ""
echo " Setup complete!"
echo ""
echo "You can now connect to the lab by running:"
echo "  $ALIAS_NAME"
echo ""
echo "When prompted for a password, use: student"
