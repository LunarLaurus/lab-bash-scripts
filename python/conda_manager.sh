#!/bin/sh

CONDA_DIR="$HOME/miniconda"
eval "$($CONDA_DIR/bin/conda shell.bash hook 2>/dev/null)" || true

install_miniconda() {
  if [ ! -d "$CONDA_DIR" ]; then
    echo "Installing Miniconda..."
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
    bash miniconda.sh -b -p "$CONDA_DIR"
    rm miniconda.sh
    eval "$($CONDA_DIR/bin/conda shell.bash hook)"
    conda init
    echo "Miniconda installed."
  else
    echo "Miniconda already installed."
  fi
}

show_menu() {
  echo ""
  echo "===== Conda Environment Manager ====="
  echo "1. List environments"
  echo "2. Create new environment"
  echo "3. Activate environment"
  echo "4. Remove environment"
  echo "5. Duplicate environment"
  echo "6. Exit"
  echo "====================================="
  echo -n "Choose an option [1-6]: "
}

create_env() {
  echo -n "Enter new environment name: "
  read ENV_NAME
  echo -n "Enter Python version (e.g., 3.11): "
  read PY_VER
  conda create -y -n "$ENV_NAME" python="$PY_VER"
}

activate_env() {
  echo -n "Enter environment name to activate: "
  read ENV_NAME
  conda activate "$ENV_NAME"
}

remove_env() {
  echo -n "Enter environment name to remove: "
  read ENV_NAME
  conda remove -y --name "$ENV_NAME" --all
}

duplicate_env() {
  echo -n "Enter source environment name: "
  read SRC_ENV
  echo -n "Enter new environment name: "
  read NEW_ENV
  conda create -y -n "$NEW_ENV" --clone "$SRC_ENV"
}

main() {
  install_miniconda
  while true; do
    show_menu
    read CHOICE
    case "$CHOICE" in
      1) conda env list ;;
      2) create_env ;;
      3) activate_env ;;
      4) remove_env ;;
      5) duplicate_env ;;
      6) echo "Goodbye!"; exit 0 ;;
      *) echo "Invalid option. Try again." ;;
    esac
  done
}

main
