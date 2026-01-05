#!/bin/zsh
# SSH Agent initialization script
# Ensures a persistent SSH agent is running and the GitHub key is loaded

# Define the persistent socket location
SSH_AGENT_SOCK="$HOME/.ssh/ssh-agent.sock"
SSH_AGENT_ENV="$HOME/.ssh/ssh-agent.env"

# Function to check if the agent is running and responsive
is_agent_running() {
    if [ -S "$SSH_AUTH_SOCK" ]; then
        # Check if the agent responds to a query
        ssh-add -l &>/dev/null
        case $? in
            0|1)
                # 0 = has keys, 1 = no keys but agent is running
                return 0
                ;;
            2)
                # Agent not responding
                return 1
                ;;
        esac
    fi
    return 1
}

# Function to start a new SSH agent
start_ssh_agent() {
    echo "Starting new SSH agent..."
    # Start the agent with a persistent socket
    ssh-agent -s -a "$SSH_AGENT_SOCK" > "$SSH_AGENT_ENV"
    # Source the environment file to get SSH_AUTH_SOCK and SSH_AGENT_PID
    source "$SSH_AGENT_ENV" > /dev/null
}

# Function to load existing agent environment
load_agent_env() {
    if [ -f "$SSH_AGENT_ENV" ]; then
        source "$SSH_AGENT_ENV" > /dev/null
    fi
}

# Main logic
if ! is_agent_running; then
    # Try to load existing agent environment
    load_agent_env
    
    # Check again if agent is running after loading env
    if ! is_agent_running; then
        # Clean up stale socket and env files
        [ -S "$SSH_AGENT_SOCK" ] && rm -f "$SSH_AGENT_SOCK"
        [ -f "$SSH_AGENT_ENV" ] && rm -f "$SSH_AGENT_ENV"
        
        # Start a new agent
        start_ssh_agent
    fi
fi

# Ensure SSH_AUTH_SOCK points to our persistent socket
export SSH_AUTH_SOCK="$SSH_AGENT_SOCK"

# Check if the GitHub key is loaded
SSH_KEY="$HOME/.ssh/tuelz-nixos"
if [ -f "$SSH_KEY" ]; then
    # Get the fingerprint of the key file
    KEY_FINGERPRINT=$(ssh-keygen -lf "$SSH_KEY" 2>/dev/null | awk '{print $2}')
    
    # Check if this key is already loaded in the agent
    if ! ssh-add -l 2>/dev/null | grep -q "$KEY_FINGERPRINT"; then
        echo "Adding SSH key to agent..."
        ssh-add "$SSH_KEY" 2>/dev/null
    fi
fi

