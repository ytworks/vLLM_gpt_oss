#!/bin/bash
set -e

# Configuration
API_ENDPOINT="http://0.0.0.0:8000/v1/chat/completions"
MODEL_NAME="openai/gpt-oss-20b"
TEST_MESSAGE="Hello, how are you?"
TIMEOUT=30

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Error handling function
error_exit() {
    echo "ERROR: $1" >&2
    exit 1
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if server is reachable
check_server() {
    log "Checking if vLLM server is reachable at http://0.0.0.0:8000..."
    
    # Check if container exists and is running
    if docker ps --format '{{.Names}}' | grep -q "^vllm-gptoss$"; then
        log "vLLM container is running."
    else
        log "WARNING: vLLM container is not running."
        if docker ps -a --format '{{.Names}}' | grep -q "^vllm-gptoss$"; then
            log "Container exists but stopped. Checking status..."
            docker ps -a --filter name=vllm-gptoss --format "Status: {{.Status}}"
        fi
    fi
    
    # Simple connectivity test
    if ! curl -s -o /dev/null --connect-timeout 5 http://0.0.0.0:8000 2>/dev/null; then
        log "WARNING: Server at http://0.0.0.0:8000 is not responding."
        # Continue anyway - let the actual API call fail with its own error
    else
        log "Server is reachable."
    fi
}

# Main execution
main() {
    log "Testing vLLM GPT-OSS API..."
    
    # Check if curl is available
    if ! command_exists curl; then
        error_exit "curl is not installed. Please install curl to use this script."
    fi
    
    # Check server availability
    check_server
    
    # Prepare JSON payload
    JSON_PAYLOAD=$(cat <<EOF
{
  "model": "${MODEL_NAME}",
  "messages": [
    {
      "role": "user",
      "content": "${TEST_MESSAGE}"
    }
  ],
  "temperature": 0.7,
  "max_tokens": 100
}
EOF
)
    
    # Display request details
    log "Sending chat completion request..."
    echo "----------------------------------------"
    echo "Endpoint: ${API_ENDPOINT}"
    echo "Model: ${MODEL_NAME}"
    echo "Message: ${TEST_MESSAGE}"
    echo "----------------------------------------"
    
    # Send request and capture response
    log "Waiting for response (timeout: ${TIMEOUT}s)..."
    RESPONSE=$(curl -s -X POST ${API_ENDPOINT} \
        -H "Content-Type: application/json" \
        -d "${JSON_PAYLOAD}" \
        --max-time ${TIMEOUT} 2>&1) || {
        error_exit "Failed to get response from API. Server might be still initializing or unavailable."
    }
    
    # Display response
    echo ""
    log "Response received:"
    echo "----------------------------------------"
    
    # Format with jq if available
    if command_exists jq; then
        echo "${RESPONSE}" | jq . || echo "${RESPONSE}"
    else
        echo "${RESPONSE}"
        echo ""
        log "Tip: Install 'jq' for formatted JSON output"
    fi
    
    echo "----------------------------------------"
    
    # Extract and display just the assistant's message if jq is available
    if command_exists jq; then
        ASSISTANT_MESSAGE=$(echo "${RESPONSE}" | jq -r '.choices[0].message.content' 2>/dev/null)
        if [ ! -z "${ASSISTANT_MESSAGE}" ] && [ "${ASSISTANT_MESSAGE}" != "null" ]; then
            echo ""
            log "Assistant's response: ${ASSISTANT_MESSAGE}"
        fi
    fi
    
    log "API test completed successfully!"
}

# Run main function
main