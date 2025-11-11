#!/usr/bin/env bash
# ============================================================
#  Portainer CE Installer / Updater / Manager for Linux
#  https://www.portainer.io/
# ============================================================

set -e

BOLD=$(tput bold)
NORMAL=$(tput sgr0)
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)

show_header() {
    clear
    echo "${BOLD}${BLUE}=== Portainer CE Setup & Management Menu ===${NORMAL}"
    echo
}

pause() {
    read -rp "Press [Enter] to continue..."
}

check_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        echo "${YELLOW}Docker not found. Installing Docker...${NORMAL}"
        curl -fsSL https://get.docker.com | sh
        sudo systemctl enable docker
        sudo systemctl start docker
        echo "${GREEN}Docker installed successfully.${NORMAL}"
    else
        echo "${GREEN}Docker already installed.${NORMAL}"
    fi
}

# ------------------------------------------------------------
# Installation
# ------------------------------------------------------------
install_portainer() {
    check_docker

    echo
    echo "${YELLOW}Choose Portainer deployment type:${NORMAL}"
    echo "1) Default (HTTPS 9443 + Edge 8000)"
    echo "2) With legacy HTTP (9000 + HTTPS 9443 + Edge 8000)"
    read -rp "Select [1-2]: " ports

    echo "${YELLOW}Creating Docker volume...${NORMAL}"
    sudo docker volume create portainer_data >/dev/null || true

    echo "${YELLOW}Pulling latest Portainer CE image...${NORMAL}"
    sudo docker pull portainer/portainer-ce:lts

    echo "${YELLOW}Starting Portainer CE container...${NORMAL}"

    case "$ports" in
        2)
            sudo docker run -d \
                -p 8000:8000 \
                -p 9000:9000 \
                -p 9443:9443 \
                --name portainer \
                --restart=always \
                -v /var/run/docker.sock:/var/run/docker.sock \
                -v portainer_data:/data \
                portainer/portainer-ce:lts
            ;;
        *)
            sudo docker run -d \
                -p 8000:8000 \
                -p 9443:9443 \
                --name portainer \
                --restart=always \
                -v /var/run/docker.sock:/var/run/docker.sock \
                -v portainer_data:/data \
                portainer/portainer-ce:lts
            ;;
    esac

    echo
    echo "${GREEN}✅ Portainer CE installed successfully.${NORMAL}"
    echo "Access it at:"
    echo "  ${BOLD}https://localhost:9443${NORMAL} (secure)"
    echo "  or ${BOLD}http://localhost:9000${NORMAL} if legacy HTTP enabled."
    echo
    echo "Default credentials setup on first visit."
    pause
}

# ------------------------------------------------------------
# Updating
# ------------------------------------------------------------
update_portainer() {
    check_docker
    echo "${YELLOW}Updating Portainer CE...${NORMAL}"
    sudo docker pull portainer/portainer-ce:lts
    sudo docker stop portainer || true
    sudo docker rm portainer || true

    echo "${YELLOW}Re-deploying container with existing data volume...${NORMAL}"
    sudo docker run -d \
        -p 8000:8000 \
        -p 9443:9443 \
        --name portainer \
        --restart=always \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v portainer_data:/data \
        portainer/portainer-ce:lts

    echo "${GREEN}✅ Portainer updated and restarted.${NORMAL}"
    pause
}

# ------------------------------------------------------------
# Management
# ------------------------------------------------------------
view_logs() {
    echo "${GREEN}Viewing Portainer logs (Ctrl+C to exit)...${NORMAL}"
    sudo docker logs -f portainer
}

restart_portainer() {
    echo "${GREEN}Restarting Portainer...${NORMAL}"
    sudo docker restart portainer
    echo "${GREEN}✅ Restarted.${NORMAL}"
    pause
}

# ------------------------------------------------------------
# Uninstall
# ------------------------------------------------------------
uninstall_portainer() {
    echo "${RED}Uninstalling Portainer CE...${NORMAL}"
    sudo docker stop portainer || true
    sudo docker rm portainer || true

    echo
    read -rp "Do you also want to delete all Portainer data? [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        sudo docker volume rm portainer_data || true
        echo "${YELLOW}Data volume removed.${NORMAL}"
    else
        echo "${YELLOW}Keeping Portainer data volume.${NORMAL}"
    fi

    echo "${GREEN}✅ Portainer removed.${NORMAL}"
    pause
}

# ------------------------------------------------------------
# Info / Status
# ------------------------------------------------------------
show_status() {
    echo "${GREEN}Checking Portainer status...${NORMAL}"
    if sudo docker ps --format '{{.Names}}' | grep -q portainer; then
        sudo docker ps | grep portainer
        echo
        echo "${GREEN}Portainer is running.${NORMAL}"
    else
        echo "${RED}Portainer is not running.${NORMAL}"
    fi
    pause
}

# ------------------------------------------------------------
# Main Menu Loop
# ------------------------------------------------------------
while true; do
    show_header
    echo "${BOLD}Choose an option:${NORMAL}"
    echo "1) Install Portainer CE"
    echo "2) Update Portainer"
    echo "3) View Logs"
    echo "4) Restart Portainer"
    echo "5) Check Status"
    echo "6) Uninstall Portainer"
    echo "0) Exit"
    echo
    read -rp "Enter choice [0-6]: " option

    case "$option" in
        1) install_portainer ;;
        2) update_portainer ;;
        3) view_logs ;;
        4) restart_portainer ;;
        5) show_status ;;
        6) uninstall_portainer ;;
        0) echo "Exiting..."; exit 0 ;;
        *) echo "${RED}Invalid choice!${NORMAL}"; sleep 1 ;;
    esac
done
