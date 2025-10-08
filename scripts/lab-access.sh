#!/bin/bash

# Script to automate Red Hat lab SSH key setup and access configuration
# Creates a lab-ssh command that requires no arguments to connect
#
# Usage: ./lab-access.sh <key_path> <jump_host> <target_host> [-p <port>] [-n <name>]
#
# Examples:
#   ./lab-access.sh ~/Downloads/rht_classroom.rsa cloud-user@148.62.94.29:22022 student@172.25.252.1
#   ./lab-access.sh ~/Downloads/rht_classroom.rsa cloud-user@148.62.94.29:22022 student@172.25.252.1 -p 53009
#   ./lab-access.sh ~/Downloads/rht_classroom.rsa cloud-user@148.62.94.29:22022 student@172.25.252.1 -p 53009 -n rhcsa_2.rsa

set -e

SSH_DIR="$HOME/.ssh"
BASHRC="$HOME/.bashrc"
DEFAULT_PORT="22"
DEFAULT_KEY_NAME="rht_classroom.rsa"

show_usage() {
    echo "Usage: $0 <key_path> <jump_host> <target_host> [-p <port>] [-n <name>]"
    echo ""
    echo "Mandatory Arguments:"
    echo "  key_path      Path to SSH key file (e.g., ~/Downloads/rht_classroom.rsa)"
    echo "  jump_host     Jump host in format user@ip:port (e.g., cloud-user@148.62.94.29:22022)"
    echo "  target_host   Target host in format user@ip (e.g., student@172.25.252.1)"
    echo ""
    echo "Optional Arguments:"
    echo "  -p <port>     Target host SSH port (default: 22)"
    echo "  -n <name>     Custom name for SSH key file (default: rht_classroom.rsa)"
    echo "  -h, --help    Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0 ~/Downloads/rht_classroom.rsa cloud-user@148.62.94.29:22022 student@172.25.252.1"
    echo "  $0 ~/Downloads/rht_classroom.rsa cloud-user@148.62.94.29:22022 student@172.25.252.1 -p 53009"
    echo "  $0 ~/Downloads/rht_classroom.rsa cloud-user@148.62.94.29:22022 student@172.25.252.1 -p 53009 -n rhcsa_2.rsa"
    exit 1
}

# Display help if requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_usage
fi

# Check for minimum required arguments
if [ $# -lt 3 ]; then
    echo "Error: Missing required arguments"
    echo ""
    show_usage
fi

# Parse mandatory positional arguments
KEY_PATH="$1"
JUMP_HOST="$2"
TARGET_HOST="$3"
shift 3

# Initialize optional arguments with defaults
TARGET_PORT="$DEFAULT_PORT"
KEY_NAME="$DEFAULT_KEY_NAME"

# Parse optional arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p)
            if [ -z "$2" ]; then
                echo "Error: -p requires a port number"
                show_usage
            fi
            TARGET_PORT="$2"
            shift 2
            ;;
        -n|--name)
            if [ -z "$2" ]; then
                echo "Error: -n/--name requires a key name"
                show_usage
            fi
            KEY_NAME="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            ;;
        *)
            echo "Error: Unknown option: $1"
            show_usage
            ;;
    esac
done

# Validate key file exists
# Function to validate inputs and setup SSH directory
validate_and_setup() {
    # Validate key file exists
    if [ ! -f "$KEY_PATH" ]; then
        echo "Error: SSH key file not found at $KEY_PATH"
        exit 1
    fi

    # Validate jump host format (user@ip:port)
    if ! [[ "$JUMP_HOST" =~ ^[^@]+@[^:]+:[0-9]+$ ]]; then
        echo "Error: Jump host must be in format user@ip:port (e.g., cloud-user@148.62.94.29:22022)"
        exit 1
    fi

    # Validate target host format (user@ip or user@hostname)
    if ! [[ "$TARGET_HOST" =~ ^[^@]+@[^@]+$ ]]; then
        echo "Error: Target host must be in format user@ip or user@hostname (e.g., student@172.25.252.1)"
        exit 1
    fi

    # Validate port is numeric
    if ! [[ "$TARGET_PORT" =~ ^[0-9]+$ ]]; then
        echo "Error: Port must be a number"
        exit 1
    fi

    # Create ~/.ssh directory if it doesn't exist
    if [ ! -d "$SSH_DIR" ]; then
        echo "Creating $SSH_DIR directory..."
        mkdir -p "$SSH_DIR"
        chmod 700 "$SSH_DIR"
    fi
}

# If $DEST_KEY or $DEFAULT_KEY_NAME exists in .ssh/, remove it before copying the new key
# Function to remove existing SSH keys
remove_existing_keys() {
    if [ -f "$SSH_DIR/$KEY_NAME" ]; then
        echo "Removing existing $SSH_DIR/$KEY_NAME..."
        rm "$SSH_DIR/$KEY_NAME"
    fi

    if [ -f "$SSH_DIR/$DEFAULT_KEY_NAME" ]; then
        echo "Removing existing $SSH_DIR/$DEFAULT_KEY_NAME..."
        rm "$SSH_DIR/$DEFAULT_KEY_NAME"
    fi
}

# Function for checking if the ip exists in the ~/.ssh/known_hosts file, if true, delete the ip/host entry from known_hosts
delete_known_hosts() {
    local host_entry="$1"
    
    # Extract host and port from formats like user@host:port or just host
    local host_part="${host_entry#*@}"  # Remove user@ if present
    
    # Check if there's a port specified
    if [[ "$host_part" == *":"* ]]; then
        local host="${host_part%:*}"
        local port="${host_part#*:}"
        
        # For non-standard ports, ssh-keygen expects [host]:port format
        if [ "$port" != "22" ]; then
            host_entry="[$host]:$port"
        else
            host_entry="$host"
        fi
    else
        host_entry="${host_part}"
    fi
    
    if [ -f "$SSH_DIR/known_hosts" ]; then
        echo "Removing $host_entry from known_hosts..."
        ssh-keygen -R "$host_entry" 2>/dev/null || true
    fi
}

# Function to remove existing 'lab' host entry from SSH config
remove_lab_ssh_config() {
    local ssh_config="$SSH_DIR/config"
    
    if [ -f "$ssh_config" ]; then
        echo "Removing existing 'lab' host entry from SSH config..."
        # Remove from "Host lab" to the next "Host" line or end of file
        sed -i '/^Host lab$/,/^Host /{ /^Host lab$/d; /^Host /!d; }; /^Host lab$/,${/^Host lab$/d;}' "$ssh_config"
    fi
}

# Function to create SSH config entry for lab host
create_ssh_config_entry() {
    local ssh_config="$SSH_DIR/config"
    local target_user="${TARGET_HOST%%@*}"
    local target_ip="${TARGET_HOST#*@}"
    
    echo "Creating SSH config entry for 'lab' host..."
    
    # Create SSH config if it doesn't exist
    touch "$ssh_config"
    chmod 600 "$ssh_config"
    
    # Add the lab host configuration
    cat >> "$ssh_config" << EOF

Host lab
    HostName $target_ip
    Port $TARGET_PORT
    User $target_user
    IdentityFile ~/.ssh/$KEY_NAME
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ProxyCommand ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p -p $JUMP_PORT $JUMP_USER@$JUMP_IP
EOF
}

# Move the key to ~/.ssh
# Function to setup SSH key and create lab-ssh command
setup_ssh_key_and_command() {
    DEST_KEY="$SSH_DIR/$KEY_NAME"
    echo "Copying SSH key to $DEST_KEY..."
    cp "$KEY_PATH" "$DEST_KEY"
    chmod 600 "$DEST_KEY"
    echo "Note: Original key preserved at $KEY_PATH"

    # Add key to ssh-agent
    echo "Adding key to ssh-agent..."
    if ! ssh-add "$DEST_KEY" 2>/dev/null; then
        echo "Warning: Could not add key to ssh-agent. You may need to start ssh-agent first."
    fi

    # Extract jump host details for ProxyCommand
    JUMP_USER="${JUMP_HOST%%@*}"
    JUMP_HOST_PORT="${JUMP_HOST#*@}"
    JUMP_IP="${JUMP_HOST_PORT%:*}"
    JUMP_PORT="${JUMP_HOST_PORT#*:}"
    
    # Create SSH config entry for lab host
    create_ssh_config_entry
}

# Remove old lab-ssh alias if it exists
remove_old_lab_ssh_alias() {
    if grep -q "^alias lab-ssh=" "$BASHRC" 2>/dev/null; then
        echo "Removing old lab-ssh alias..."
        sed -i "/^alias lab-ssh=/d" "$BASHRC"
    fi
}

# Remove old lab-ssh function if it exists
remove_old_lab_ssh_function() {
    if grep -q "^lab-ssh()" "$BASHRC" 2>/dev/null; then
        echo "Removing old lab-ssh function..."
        sed -i "/^lab-ssh()/,/^}/d" "$BASHRC"
    fi
}

main() {
    # Validate environment and setup initial configuration
    validate_and_setup

    # Clean up existing SSH keys to ensure fresh setup
    remove_existing_keys

    # Remove old host entries from known_hosts to prevent conflicts
    delete_known_hosts "$TARGET_HOST"
    delete_known_hosts "$JUMP_HOST"

    # Clean up any existing lab-ssh configurations
    remove_old_lab_ssh_alias
    remove_old_lab_ssh_function
    remove_lab_ssh_config

    # Setup new SSH key and SSH config
    setup_ssh_key_and_command
    
    echo ""
    echo "✓ Setup complete!"
    echo ""
    echo "You can now connect to the lab by simply running:"
    echo "  ssh lab"
    echo ""
    echo "SSH config created for 'lab' host with all connection details."
    echo ""
    echo "When prompted for a password, use: student"
}

# Run the main function
main