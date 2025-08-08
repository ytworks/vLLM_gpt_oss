# Design Document

## Architecture Overview

Three independent shell scripts that manage vLLM Docker container lifecycle and test its API:
- `start_server.sh`: Container initialization and startup
- `stop_server.sh`: Container cleanup
- `test_api.sh`: API endpoint testing

## Detailed Design

### 1. start_server.sh

#### Flow Design
```
1. Check if container "vllm-gptoss" exists
   ├─ If exists and running → stop it
   └─ If exists → remove it
2. Run new container with specified parameters
3. Wait for container to initialize (2-3 seconds)
4. Display container logs
5. Show success message with container status
```

#### Error Handling
- Check Docker daemon availability
- Verify GPU availability (warning if not available)
- Handle container start failures

#### Implementation Details
```bash
#!/bin/bash
# Container management functions
container_exists() { ... }
stop_container() { ... }
remove_container() { ... }

# Main execution flow
main() {
    # Pre-flight checks
    # Container cleanup
    # Start new container
    # Display logs and status
}
```

### 2. stop_server.sh

#### Flow Design
```
1. Check if container "vllm-gptoss" exists
   └─ If not exists → show message and exit
2. Stop container
3. Remove container
4. Show success message
```

#### Error Handling
- Handle case when container doesn't exist
- Handle permission errors

### 3. test_api.sh

#### Flow Design
```
1. Check if server is reachable (health check)
2. Prepare JSON payload
3. Send POST request using curl
4. Process response:
   ├─ If jq available → format JSON
   └─ Else → display raw response
5. Show request details for debugging
```

#### JSON Payload Structure
```json
{
  "model": "openai/gpt-oss-20b",
  "messages": [
    {
      "role": "user",
      "content": "Hello, how are you?"
    }
  ],
  "temperature": 0.7,
  "max_tokens": 100
}
```

#### Error Handling
- Check server availability before sending request
- Handle connection failures
- Display helpful error messages

## Common Design Patterns

### 1. Logging Function
```bash
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}
```

### 2. Error Handling Pattern
```bash
error_exit() {
    echo "ERROR: $1" >&2
    exit 1
}
```

### 3. Command Existence Check
```bash
command_exists() {
    command -v "$1" >/dev/null 2>&1
}
```

## File Structure
```
vLLM_gpt_oss/
├── start_server.sh
├── stop_server.sh
├── test_api.sh
└── .tmp/
    ├── requirements.md
    ├── design.md
    └── tasks.md
```

## Security Considerations
- Scripts use set -e for fail-fast behavior
- No sensitive data hardcoded
- Container runs with minimal required privileges

## Performance Considerations
- Container startup wait time optimized (2-3 seconds)
- Logs limited to last 50 lines to prevent overflow
- API test timeout set to 30 seconds

## Testing Strategy
1. Test start_server.sh with/without existing container
2. Test stop_server.sh with/without running container
3. Test test_api.sh with/without jq installed
4. Test error scenarios (no Docker, no GPU, server down)