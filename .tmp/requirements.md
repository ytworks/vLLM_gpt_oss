# Requirements Document

## Project Overview
Create shell scripts to manage and test a vLLM server running in Docker with the GPT-OSS model.

## Functional Requirements

### FR1: Server Start Script (start_server.sh)
- **FR1.1**: Execute Docker command to run vLLM server with specified parameters
- **FR1.2**: Add -d option for background execution
- **FR1.3**: Specify container name as "vllm-gptoss"
- **FR1.4**: Check and remove existing container with same name before starting
- **FR1.5**: Display container logs after startup

### FR2: Server Stop Script (stop_server.sh)
- **FR2.1**: Stop the vllm-gptoss container
- **FR2.2**: Remove the vllm-gptoss container after stopping

### FR3: API Test Script (test_api.sh)
- **FR3.1**: Send POST request to /v1/chat/completions endpoint
- **FR3.2**: Include test message "Hello, how are you?" in JSON payload
- **FR3.3**: Display response
- **FR3.4**: Format response with jq if available

## Non-Functional Requirements

### NFR1: Script Independence
- Each script must be independently executable

### NFR2: Error Handling
- Scripts should handle common error cases gracefully

### NFR3: Usability
- Scripts should provide clear feedback about their actions

## Technical Constraints

### TC1: Docker Configuration
- Must use exact Docker image: vllm/vllm-openai:gptoss
- Must map port 8000:8000
- Must use --gpus all flag
- Must use --ipc=host flag
- Must pass --model openai/gpt-oss-20b as argument

### TC2: API Configuration
- API endpoint: http://localhost:8000/v1/chat/completions
- Request format: OpenAI-compatible chat completion format

## Success Criteria

1. start_server.sh successfully launches the vLLM server in background
2. stop_server.sh cleanly stops and removes the container
3. test_api.sh successfully sends request and displays response
4. All scripts are executable and work independently