#!/bin/bash
set -e

# Configuration
CONTAINER_NAME="vllm-gptoss"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Error handling function
error_exit() {
    echo "ERROR: $1" >&2
    exit 1
}

# Check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        error_exit "Docker daemon is not running. Please start Docker first."
    fi
}

# Check if container exists
container_exists() {
    docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
}

# Check if container is running
container_running() {
    docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"
}

# Main execution
main() {
    log "Stopping vLLM GPT-OSS server..."
    
    # Check Docker
    check_docker
    
    # Check if container exists
    if ! container_exists; then
        log "Container '${CONTAINER_NAME}' does not exist. Nothing to stop."
        exit 0
    fi
    
    # Stop container if running
    if container_running; then
        log "Stopping container '${CONTAINER_NAME}'..."
        docker stop ${CONTAINER_NAME}
        log "Container stopped successfully."
    else
        log "Container '${CONTAINER_NAME}' is not running."
    fi
    
    # Remove container
    log "Removing container '${CONTAINER_NAME}'..."
    docker rm ${CONTAINER_NAME}
    log "Container removed successfully."
    
    log "vLLM GPT-OSS server has been stopped and cleaned up."
}

# Run main function
main