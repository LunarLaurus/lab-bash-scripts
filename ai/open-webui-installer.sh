#!/bin/bash
set -e

OPENWEBUI_IMAGE="ghcr.io/open-webui/open-webui"
OPENWEBUI_VOLUME="open-webui"
OLLAMA_VOLUME="ollama"
CONTAINER_NAME="open-webui"

# Colors
BOLD=$(tput bold)
RESET=$(tput sgr0)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
CYAN=$(tput setaf 6)
RED=$(tput setaf 1)

# Helper: pause
pause() {
    read -rp "Press Enter to continue..."
}

# Detect GPU
detect_gpu() {
    if command -v nvidia-smi >/dev/null 2>&1; then
        echo "yes"
    else
        echo "no"
    fi
}

# Detect if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        echo "${RED}Docker is not running or not installed.${RESET}"
        echo "Please install Docker first:"
        echo "  sudo apt update && sudo apt install -y docker.io"
        echo "  sudo systemctl enable --now docker"
        exit 1
    fi
}

# Show main menu
main_menu() {
    clear
    echo "${BOLD}${CYAN}=== Open WebUI Installation Menu ===${RESET}"
    echo "1) Install Open WebUI (Bundled Ollama)"
    echo "2) Install Open WebUI (Remote Ollama)"
    echo "3) Install Open WebUI (OpenAI API only)"
    echo "4) Update Open WebUI container"
    echo "5) Remove Open WebUI container"
    echo "6) Exit"
    echo
    read -rp "Select an option: " choice
    case $choice in
        1) install_local ;;
        2) install_remote ;;
        3) install_openai ;;
        4) update_container ;;
        5) remove_container ;;
        6) exit 0 ;;
        *) echo "Invalid option"; pause ;;
    esac
    main_menu
}

install_local() {
    clear
    echo "${BOLD}${CYAN}Installing Open WebUI (Bundled Ollama)...${RESET}"
    check_docker

    GPU=$(detect_gpu)
    if [ "$GPU" == "yes" ]; then
        TAG=":ollama"
        GPU_FLAG="--gpus all"
        echo "${GREEN}GPU detected. Using GPU build.${RESET}"
    else
        TAG=":ollama"
        GPU_FLAG=""
        echo "${YELLOW}No GPU detected. Using CPU build.${RESET}"
    fi

    docker run -d -p 3000:8080 $GPU_FLAG \
        -v ${OLLAMA_VOLUME}:/root/.ollama \
        -v ${OPENWEBUI_VOLUME}:/app/backend/data \
        --add-host=host.docker.internal:host-gateway \
        --name ${CONTAINER_NAME} --restart always \
        ${OPENWEBUI_IMAGE}${TAG}

    echo "${GREEN}Open WebUI is now running on http://localhost:3000${RESET}"
    pause
}

install_remote() {
    clear
    echo "${BOLD}${CYAN}Installing Open WebUI (Remote Ollama)...${RESET}"
    check_docker
    read -rp "Enter remote Ollama URL (e.g. http://192.168.0.10:11434): " REMOTE_URL
    if [ -z "$REMOTE_URL" ]; then
        echo "${YELLOW}No URL provided, defaulting to local Ollama.${RESET}"
        REMOTE_URL="http://127.0.0.1:11434"
    fi

    docker run -d -p 3000:8080 \
        -v ${OPENWEBUI_VOLUME}:/app/backend/data \
        -e OLLAMA_BASE_URL=${REMOTE_URL} \
        --name ${CONTAINER_NAME} --restart always \
        ${OPENWEBUI_IMAGE}:main

    echo "${GREEN}Open WebUI connected to remote Ollama at ${REMOTE_URL}${RESET}"
    echo "Access it at: http://localhost:3000"
    pause
}

install_openai() {
    clear
    echo "${BOLD}${CYAN}Installing Open WebUI (OpenAI API only)...${RESET}"
    check_docker
    read -rp "Enter your OpenAI API key: " API_KEY

    docker run -d -p 3000:8080 \
        -v ${OPENWEBUI_VOLUME}:/app/backend/data \
        -e OPENAI_API_KEY=${API_KEY} \
        --name ${CONTAINER_NAME} --restart always \
        ${OPENWEBUI_IMAGE}:main

    echo "${GREEN}Open WebUI (OpenAI-only) installed.${RESET}"
    echo "Access it at: http://localhost:3000"
    pause
}

update_container() {
    clear
    echo "${BOLD}${CYAN}Updating Open WebUI...${RESET}"
    check_docker

    docker pull ${OPENWEBUI_IMAGE}:main
    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --run-once ${CONTAINER_NAME}

    echo "${GREEN}Open WebUI updated successfully.${RESET}"
    pause
}

remove_container() {
    clear
    echo "${BOLD}${RED}Removing Open WebUI container and volumes...${RESET}"
    check_docker
    docker stop ${CONTAINER_NAME} >/dev/null 2>&1 || true
    docker rm ${CONTAINER_NAME} >/dev/null 2>&1 || true
    docker volume rm ${OPENWEBUI_VOLUME} >/dev/null 2>&1 || true

    echo "${GREEN}Open WebUI removed successfully.${RESET}"
    pause
}

# Entry point
main_menu
