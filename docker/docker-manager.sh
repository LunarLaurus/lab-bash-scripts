#!/usr/bin/env bash
# ============================================================
#  Docker Installer / Updater / Manager for Linux
# ============================================================

set -e

# ---------------- Colors ----------------
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)

# ---------------- Helpers ----------------
show_header() {
    clear
    echo "${BOLD}${BLUE}=== Docker Management Menu ===${NORMAL}"
    echo
}

pause() {
    read -rp "Press [Enter] to continue..."
}

# ---------------- Docker Install / Update ----------------
check_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        echo "${YELLOW}Docker not found. Installing Docker...${NORMAL}"
        curl -fsSL https://get.docker.com | sh
        sudo systemctl enable docker
        sudo systemctl start docker
        echo "${GREEN}Docker installed successfully.${NORMAL}"
    else
        echo "${GREEN}Docker is already installed.${NORMAL}"
    fi
}

update_docker() {
    echo "${YELLOW}Updating Docker...${NORMAL}"
    sudo apt update
    sudo apt install --only-upgrade docker-ce docker-ce-cli containerd.io -y || true
    echo "${GREEN}Docker updated successfully.${NORMAL}"
    pause
}

# ---------------- Container Management ----------------
list_containers() {
    echo "${GREEN}Listing all containers...${NORMAL}"
    sudo docker ps -a
    pause
}

start_container() {
    read -rp "Enter container name or ID to start: " cid
    sudo docker start "$cid"
    echo "${GREEN}✅ Container started.${NORMAL}"
    pause
}

stop_container() {
    read -rp "Enter container name or ID to stop: " cid
    sudo docker stop "$cid"
    echo "${GREEN}✅ Container stopped.${NORMAL}"
    pause
}

restart_container() {
    read -rp "Enter container name or ID to restart: " cid
    sudo docker restart "$cid"
    echo "${GREEN}✅ Container restarted.${NORMAL}"
    pause
}

remove_container() {
    read -rp "Enter container name or ID to remove: " cid
    sudo docker rm "$cid"
    echo "${GREEN}✅ Container removed.${NORMAL}"
    pause
}

view_logs() {
    read -rp "Enter container name or ID to view logs: " cid
    echo "${GREEN}Viewing logs for $cid (Ctrl+C to exit)...${NORMAL}"
    sudo docker logs -f "$cid"
}

# ---------------- Verification Steps ----------------
verify_cli() {
    echo "${BOLD}${BLUE}=== Docker CLI Verification ===${NORMAL}"
    if command -v docker >/dev/null 2>&1; then
        echo "${GREEN}✅ Docker CLI is installed.${NORMAL}"
        docker --version
    else
        echo "${RED}❌ Docker CLI is missing.${NORMAL}"
    fi
    pause
}

verify_service() {
    echo "${BOLD}${BLUE}=== Docker Service Verification ===${NORMAL}"
    if systemctl is-active --quiet docker; then
        echo "${GREEN}✅ Docker service is running.${NORMAL}"
    else
        echo "${RED}❌ Docker service is not running.${NORMAL}"
    fi
    pause
}

start_service() {
    echo "${YELLOW}Starting Docker service...${NORMAL}"
    sudo systemctl enable docker
    sudo systemctl start docker
    echo "${GREEN}✅ Docker service started.${NORMAL}"
    pause
}

verify_user_group() {
    echo "${BOLD}${BLUE}=== Docker User Group Verification ===${NORMAL}"
    if groups $USER | grep -q "\bdocker\b"; then
        echo "${GREEN}✅ User '$USER' is in the docker group.${NORMAL}"
    else
        echo "${RED}❌ User '$USER' is NOT in the docker group.${NORMAL}"
    fi
    pause
}

add_user_group() {
    # Check if the docker group exists
    if ! getent group docker >/dev/null; then
        echo "${YELLOW}Docker group does not exist. Creating group...${NORMAL}"
        sudo groupadd docker
    fi

    echo "${YELLOW}Adding user '$USER' to docker group...${NORMAL}"
    sudo usermod -aG docker "$USER"
    echo "${GREEN}✅ User added. Log out and log back in for group changes to take effect.${NORMAL}"
    pause
}

verify_data_dir() {
    DATA_DIR=$(docker info --format '{{.DockerRootDir}}' 2>/dev/null || echo "/var/lib/docker")
    echo "${BOLD}${BLUE}=== Docker Data Directory Verification ===${NORMAL}"
    echo "Docker root directory: $DATA_DIR"
    if [[ -d "$DATA_DIR" && -w "$DATA_DIR" ]]; then
        echo "${GREEN}✅ Data directory exists and is writable.${NORMAL}"
    else
        echo "${RED}❌ Data directory missing or not writable.${NORMAL}"
    fi
    pause
}

fix_data_dir() {
    DATA_DIR=$(docker info --format '{{.DockerRootDir}}' 2>/dev/null || echo "/var/lib/docker")
    echo "${YELLOW}Ensuring Docker data directory exists: $DATA_DIR${NORMAL}"
    sudo mkdir -p "$DATA_DIR"

    # Use group 'docker' if it exists, otherwise use user's primary group
    if getent group docker >/dev/null; then
        TARGET_GROUP="docker"
    else
        TARGET_GROUP=$(id -gn "$USER")
        echo "${YELLOW}Docker group not found, using user's primary group '$TARGET_GROUP'${NORMAL}"
    fi

    sudo chown root:"$TARGET_GROUP" "$DATA_DIR"
    sudo chmod 711 "$DATA_DIR"
    echo "${GREEN}✅ Permissions fixed.${NORMAL}"
    pause
}

# ---------------- Main Menu ----------------
while true; do
    show_header
    echo "${BOLD}Choose an option:${NORMAL}"
    echo "1) Install Docker"
    echo "2) Update Docker"
    echo "3) List containers"
    echo "4) Start container"
    echo "5) Stop container"
    echo "6) Restart container"
    echo "7) Remove container"
    echo "8) View container logs"
    echo "9) Verify Docker CLI"
    echo "10) Verify Docker service"
    echo "11) Start Docker service"
    echo "12) Verify Docker user group"
    echo "13) Add user to Docker group"
    echo "14) Verify Docker data directory"
    echo "15) Fix Docker data directory permissions"
    echo "0) Exit"
    echo
    read -rp "Enter choice [0-15]: " option

    case "$option" in
        1) check_docker ;;
        2) update_docker ;;
        3) list_containers ;;
        4) start_container ;;
        5) stop_container ;;
        6) restart_container ;;
        7) remove_container ;;
        8) view_logs ;;
        9) verify_cli ;;
        10) verify_service ;;
        11) start_service ;;
        12) verify_user_group ;;
        13) add_user_group ;;
        14) verify_data_dir ;;
        15) fix_data_dir ;;
        0) echo "Exiting..."; exit 0 ;;
        *) echo "${RED}Invalid choice!${NORMAL}"; sleep 1 ;;
    esac
done
