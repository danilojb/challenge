#!/bin/bash

#═══════════════════════════════════════════════════════════════════════════
# Menu Interativo: Escolher qual Kubernetes instalar
# Uso: ./install-kubernetes.sh
#═══════════════════════════════════════════════════════════════════════════

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

clear

echo -e "${BLUE}"
cat << 'ASCII_ART'
╔══════════════════════════════════════════════════════════════════════════╗
║                                                                          ║
║                  🚀 INSTALADOR KUBERNETES FEDORA                        ║
║                                                                          ║
║              Escolha qual solução de Kubernetes você quer               ║
║                                                                          ║
╚══════════════════════════════════════════════════════════════════════════╝
ASCII_ART
echo -e "${NC}\n"

PS3=$'\n'"${CYAN}Escolha uma opção (1-4): ${NC}"

options=(
    "1️⃣  MINIKUBE (⭐ RECOMENDADO - Mais fácil, desenvolvimento)"
    "2️⃣  KIND - Container-native (Bom para CI/CD)"
    "3️⃣  WSL2 - Windows Subsystem Linux (🪟 Se você está em WSL com Root)"
    "4️⃣  KUBEADM (Produção, mais complexo)"
    "❌  SAIR"
)

select opt in "${options[@]}"
do
    case $opt in
        "1️⃣  MINIKUBE (⭐ RECOMENDADO - Mais fácil, desenvolvimento)")
            echo -e "\n${GREEN}Você escolheu: MINIKUBE${NC}\n"
            echo "Iniciando instalação automática do Minikube..."
            sleep 2
            exec ./install-minikube.sh
            break
            ;;
        "2️⃣  KIND - Container-native (Bom para CI/CD)")
            echo -e "\n${GREEN}Você escolheu: KIND${NC}\n"
            echo "Iniciando instalação automática do KIND..."
            sleep 2
            exec ./install-kind.sh
            break
            ;;
        "3️⃣  WSL2 - Windows Subsystem Linux (🪟 Se você está em WSL com Root)")
            echo -e "\n${GREEN}Você escolheu: WSL2${NC}\n"
            echo "Iniciando instalação otimizada para WSL..."
            sleep 2
            exec ./install-wsl.sh
            break
            ;;
        "4️⃣  KUBEADM (Produção, mais complexo)")
            echo -e "\n${GREEN}Você escolheu: KUBEADM${NC}\n"
            echo "Você será redirecionado para o guia de instalação manual."
            echo "Leia: INSTALAR_KUBERNETES.md (seção KUBEADM)"
            sleep 2
            less k8s/docs/INSTALAR_KUBERNETES.md
            break
            ;;
        "❌  SAIR")
            echo -e "\n${YELLOW}Saindo...${NC}\n"
            exit 0
            ;;
        *) 
            echo -e "\n${RED}Opção inválida. Tente novamente.${NC}\n"
            ;;
    esac
done
