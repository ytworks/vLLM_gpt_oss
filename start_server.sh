#!/bin/bash
set -e

# Configuration
CONTAINER_NAME="vllm-gptoss"
IMAGE_NAME="vllm/vllm-openai:gptoss"
MODEL_NAME="openai/gpt-oss-20b"
PORT_MAPPING="8000:8000"

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

# Stop container
stop_container() {
    log "Stopping existing container..."
    docker stop "${CONTAINER_NAME}" >/dev/null 2>&1 || true
}

# Remove container
remove_container() {
    log "Removing existing container..."
    docker rm "${CONTAINER_NAME}" >/dev/null 2>&1 || true
}

# Main execution
main() {
    log "Starting vLLM GPT-OSS server setup..."
    
    # Check Docker
    check_docker
    
    # Check GPU availability (warning only)
    if ! docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi >/dev/null 2>&1; then
        log "WARNING: GPU might not be available. The server may run slower."
    fi
    
    # Handle existing container
    if container_exists; then
        if container_running; then
            log "Container '${CONTAINER_NAME}' is already running."
            stop_container
        fi
        remove_container
    fi
    
    # Start new container
    log "Starting new container '${CONTAINER_NAME}'..."
    docker run -d \
        --gpus all \
        -p ${PORT_MAPPING} \
        --ipc=host \
        --name ${CONTAINER_NAME} \
        ${IMAGE_NAME} \
        --model ${MODEL_NAME}
    
    if [ $? -eq 0 ]; then
        log "Container started successfully!"
        
        # Wait for initialization
        log "Waiting for server to initialize..."
        sleep 3
        
        # Show container logs
        log "Container logs (last 50 lines):"
        echo "----------------------------------------"
        docker logs --tail 50 ${CONTAINER_NAME}
        echo "----------------------------------------"
        
        # Show container status
        log "Container status:"
        docker ps --filter name=${CONTAINER_NAME} --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
        log "vLLM server is ready at http://localhost:8000"
        log "Use './test_api.sh' to test the API"
    else
        error_exit "Failed to start container"
    fi
}

# Run main function
main