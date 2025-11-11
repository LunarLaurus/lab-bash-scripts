#!/usr/bin/env bash
# ============================================================
#  OpenLLaMA / Ollama Linux Installation Menu
#  https://ollama.com
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
    echo "${BOLD}${BLUE}=== OpenLLaMA / Ollama Linux Setup Menu ===${NORMAL}"
    echo
}

pause() {
    read -rp "Press [Enter] to continue..."
}

install_ollama() {
    echo "${GREEN}Installing Ollama via automatic install script...${NORMAL}"
    curl -fsSL https://ollama.com/install.sh | sh
    echo "${GREEN}Ollama installed successfully.${NORMAL}"
    pause
}

manual_install() {
    echo "${YELLOW}Manual install options:${NORMAL}"
    echo "1) x86_64 (default)"
    echo "2) AMD GPU (ROCm)"
    echo "3) ARM64 (aarch64)"
    read -rp "Choose architecture [1-3]: " choice

    case "$choice" in
        2)
            echo "${GREEN}Installing Ollama for AMD GPU...${NORMAL}"
            curl -fsSL https://ollama.com/download/ollama-linux-amd64-rocm.tgz | sudo tar zx -C /usr
            ;;
        3)
            echo "${GREEN}Installing Ollama for ARM64...${NORMAL}"
            curl -fsSL https://ollama.com/download/ollama-linux-arm64.tgz | sudo tar zx -C /usr
            ;;
        *)
            echo "${GREEN}Installing Ollama for x86_64...${NORMAL}"
            curl -fsSL https://ollama.com/download/ollama-linux-amd64.tgz | sudo tar zx -C /usr
            ;;
    esac

    echo "${GREEN}Manual installation complete.${NORMAL}"
    pause
}

create_service() {
    echo "${GREEN}Creating Ollama service user and group...${NORMAL}"
    sudo useradd -r -s /bin/false -U -m -d /usr/share/ollama ollama || true
    sudo usermod -a -G ollama "$(whoami)" || true

    echo "${GREEN}Creating systemd service...${NORMAL}"
    cat <<EOF | sudo tee /etc/systemd/system/ollama.service >/dev/null
[Unit]
Description=Ollama Service
After=network-online.target

[Service]
ExecStart=/usr/bin/ollama serve
User=ollama
Group=ollama
Restart=always
RestartSec=3
Environment="PATH=/usr/local/bin:/usr/bin:/bin"

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable ollama
    echo "${GREEN}Service created and enabled.${NORMAL}"
    pause
}

start_ollama() {
    echo "${GREEN}Starting Ollama service...${NORMAL}"
    sudo systemctl start ollama
    sudo systemctl status ollama --no-pager
    pause
}

update_ollama() {
    echo "${GREEN}Updating Ollama...${NORMAL}"
    curl -fsSL https://ollama.com/install.sh | sh
    echo "${GREEN}Update complete.${NORMAL}"
    pause
}

install_cuda() {
    echo "${YELLOW}Opening CUDA installation page...${NORMAL}"
    xdg-open https://developer.nvidia.com/cuda-downloads || true
    echo "After installing, verify with: nvidia-smi"
    pause
}

install_rocm() {
    echo "${YELLOW}Opening ROCm installation page...${NORMAL}"
    xdg-open https://rocm.docs.amd.com/projects/install-on-linux/en/latest/tutorial/quick-start.html || true
    pause
}

view_logs() {
    echo "${GREEN}Viewing Ollama service logs (press Ctrl+C to exit)...${NORMAL}"
    sudo journalctl -e -u ollama
}

uninstall_ollama() {
    echo "${RED}Uninstalling Ollama...${NORMAL}"
    sudo systemctl stop ollama || true
    sudo systemctl disable ollama || true
    sudo rm -f /etc/systemd/system/ollama.service
    sudo rm -rf /usr/lib/ollama /usr/local/lib/ollama /lib/ollama 2>/dev/null || true
    sudo rm -f "$(which ollama)" 2>/dev/null || true
    sudo userdel ollama 2>/dev/null || true
    sudo groupdel ollama 2>/dev/null || true
    sudo rm -rf /usr/share/ollama 2>/dev/null || true
    echo "${GREEN}Ollama completely removed.${NORMAL}"
    pause
}

while true; do
    show_header
    echo "${BOLD}Choose an option:${NORMAL}"
    echo "1) Install Ollama (auto)"
    echo "2) Manual Install (choose architecture)"
    echo "3) Create & Enable System Service"
    echo "4) Start Ollama"
    echo "5) Update Ollama"
    echo "6) Install CUDA drivers (NVIDIA)"
    echo "7) Install ROCm drivers (AMD)"
    echo "8) View Ollama Logs"
    echo "9) Uninstall Ollama"
    echo "0) Exit"
    echo

    read -rp "Enter choice [0-9]: " option
    case "$option" in
        1) install_ollama ;;
        2) manual_install ;;
        3) create_service ;;
        4) start_ollama ;;
        5) update_ollama ;;
        6) install_cuda ;;
        7) install_rocm ;;
        8) view_logs ;;
        9) uninstall_ollama ;;
        0) echo "Exiting..."; exit 0 ;;
        *) echo "${RED}Invalid option!${NORMAL}"; sleep 1 ;;
    esac
done
