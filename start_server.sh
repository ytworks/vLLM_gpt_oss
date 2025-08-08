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
    
    # Check GPU availability and show info
    log "Checking GPU availability..."
    if docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi >/dev/null 2>&1; then
        log "GPU detected. Showing GPU info:"
        docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi --query-gpu=name,memory.total,memory.free --format=csv
    else
        log "WARNING: GPU might not be available. The server may run slower or fail to start."
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
    CONTAINER_ID=$(docker run -d \
        --gpus all \
        -p ${PORT_MAPPING} \
        --ipc=host \
        --name ${CONTAINER_NAME} \
        -e VLLM_USE_V1=0 \
        ${IMAGE_NAME} \
        --model ${MODEL_NAME})
    
    if [ $? -eq 0 ]; then
        log "Container started successfully! (ID: ${CONTAINER_ID:0:12})"
        
        # Wait for initialization and check if container is still running
        log "Waiting for server to initialize (this may take a while)..."
        
        # Wait for the API to become available (up to 60 seconds)
        WAIT_TIME=0
        MAX_WAIT=60
        while [ $WAIT_TIME -lt $MAX_WAIT ]; do
            if curl -s -o /dev/null --connect-timeout 2 http://localhost:8000/v1/models 2>/dev/null; then
                log "API is now available!"
                break
            fi
            echo -n "."
            sleep 2
            WAIT_TIME=$((WAIT_TIME + 2))
        done
        echo ""
        
        if [ $WAIT_TIME -ge $MAX_WAIT ]; then
            log "WARNING: API did not become available within ${MAX_WAIT} seconds"
            log "The server might still be initializing. Check logs with: docker logs -f ${CONTAINER_NAME}"
        fi
        
        # Check if container is still running after waiting
        if ! container_running; then
            log "ERROR: Container stopped unexpectedly. Checking logs for errors..."
            echo "----------------------------------------"
            docker logs ${CONTAINER_NAME} 2>&1
            echo "----------------------------------------"
            
            # Check exit code
            EXIT_CODE=$(docker inspect ${CONTAINER_NAME} --format='{{.State.ExitCode}}')
            log "Container exit code: ${EXIT_CODE}"
            
            error_exit "Container failed to stay running. The vLLM server crashed during initialization."
        fi
        
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