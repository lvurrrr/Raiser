#!/bin/bash

set -e

echo "=========================================="
echo "        RAISER INSTALL SETUP"
echo "=========================================="

# Vérifie root
if [ "$EUID" -ne 0 ]; then
    echo "[!] Lance ce script avec sudo."
    exit 1
fi

USER_NAME=${SUDO_USER:-$USER}

echo
echo "[+] Mise à jour du système..."
apt update

echo
echo "[+] Installation des dépendances..."
apt install -y \
    docker.io \
    hping3 \
    sudo \
    iputils-ping \
    nano \
    curl

echo
echo "[+] Activation de Docker..."
systemctl enable docker
systemctl restart docker

echo
echo "[+] Ajout de $USER_NAME au groupe docker..."
usermod -aG docker "$USER_NAME"

echo
echo "[+] Activation des capacités RAW pour hping3..."

if command -v setcap >/dev/null 2>&1; then
    setcap cap_net_raw,cap_net_admin=eip /usr/sbin/hping3 2>/dev/null || true
    setcap cap_net_raw,cap_net_admin=eip /usr/bin/hping3 2>/dev/null || true
fi

echo
echo "[+] Vérification Docker..."

docker info >/dev/null

echo
echo "[+] Nettoyage des anciens conteneurs RAISER..."

docker rm -f $(docker ps -aq --filter "name=raiser_node_") 2>/dev/null || true

echo
echo "[+] Suppression de l'ancienne image..."

docker rmi raiser-image 2>/dev/null || true

echo
echo "=========================================="
echo "Installation terminée."
echo
echo "IMPORTANT :"
echo "Déconnecte-toi puis reconnecte-toi"
echo "afin que le groupe docker soit pris en compte."
echo
echo "Ensuite relance RAISER."
echo "=========================================="
