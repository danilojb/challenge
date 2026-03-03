#!/bin/bash

#═══════════════════════════════════════════════════════════════════════════
# Script de Instalação Automática: Minikube + kubectl no Fedora
# Uso: ./install-minikube.sh
#═══════════════════════════════════════════════════════════════════════════

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções auxiliares
print_header() {
    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} $1"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_step() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📍 $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# PASSO 1: Verificação de pré-requisitos
check_prerequisites() {
    print_header "PASSO 1: Verificar Pré-requisitos"
    
    # Verificar se é root (permitido em WSL)
    if [[ $EUID -eq 0 ]]; then
        print_warning "Você está como root (OK em WSL)"
    fi
    
    # Verificar Sistema Operacional
    if ! grep -q "Fedora" /etc/os-release 2>/dev/null; then
        print_warning "Este script é otimizado para Fedora."
        read -p "Continuar mesmo assim? (s/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Ss]$ ]]; then
            exit 1
        fi
    else
        print_success "Sistema Fedora detectado"
    fi
    
    # Verificar virtualização (pode não funcionar em WSL, mas continua)
    print_step "Verificando suporte a virtualização..."
    if grep -q -E 'vmx|svm' /proc/cpuinfo; then
        print_success "Virtualização ativa"
    else
        print_warning "Virtualização não detectada (OK se estiver em WSL)"
    fi
    
    # Verificar internet
    print_step "Verificando conectividade..."
    if ping -c 1 8.8.8.8 &> /dev/null; then
        print_success "Conectividade OK"
    else
        print_error "Sem conexão com internet"
        exit 1
    fi
}

# PASSO 2: Instalar Docker
install_docker() {
    print_header "PASSO 2: Instalar Docker"
    
    if command -v docker &> /dev/null; then
        print_success "Docker já instalado: $(docker --version)"
        return
    fi
    
    print_step "Instalando Docker..."
    
    sudo dnf install -y dnf-plugins-core >/dev/null 2>&1
    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo >/dev/null 2>&1
    sudo dnf install -y docker-ce docker-ce-cli containerd.io >/dev/null 2>&1
    
    print_success "Docker instalado"
    
    # Iniciar Docker
    print_step "Iniciando serviço Docker..."
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Configurar permissões
    print_step "Configurando permissões..."
    sudo usermod -aG docker $USER
    
    print_warning "IMPORTANTE: Você precisa fazer logout e login para as permissões serem aplicadas"
    print_warning "Ou execute: newgrp docker"
    newgrp docker
}

# PASSO 3: Instalar Minikube
install_minikube() {
    print_header "PASSO 3: Instalar Minikube"
    
    if command -v minikube &> /dev/null; then
        print_success "Minikube já instalado: $(minikube version)"
        return
    fi
    
    print_step "Baixando Minikube..."
    cd /tmp
    curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64 2>/dev/null
    
    print_step "Instalando..."
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
    
    print_success "Minikube instalado: $(minikube version)"
}

# PASSO 4: Instalar kubectl
install_kubectl() {
    print_header "PASSO 4: Instalar kubectl"
    
    if command -v kubectl &> /dev/null; then
        print_success "kubectl já instalado: $(kubectl version --client --short 2>/dev/null)"
        return
    fi
    
    print_step "Baixando kubectl..."
    cd /tmp
    LATEST_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt 2>/dev/null)
    curl -LO "https://dl.k8s.io/release/${LATEST_VERSION}/bin/linux/amd64/kubectl" 2>/dev/null
    
    print_step "Instalando..."
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    
    print_success "kubectl instalado"
}

# PASSO 5: Iniciar Minikube
start_minikube() {
    print_header "PASSO 5: Iniciar Minikube"
    
    print_warning "Isso pode levar 2-3 minutos na primeira execução..."
    print_step "Iniciando cluster..."
    
    minikube start --driver=docker
    
    print_success "Minikube iniciado!"
    
    print_step "Verificando status..."
    minikube status
}

# PASSO 6: Verificação final
verify_installation() {
    print_header "PASSO 6: Verificação Final"
    
    print_step "Verificando cluster..."
    kubectl get nodes
    
    print_step "Adicionando Ingress Controller..."
    minikube addons enable ingress
    print_success "Ingress Controller ativo"
    
    print_step "Informações do cluster:"
    kubectl cluster-info
}

# PASSO 7: Próximos passos
next_steps() {
    print_header "✅ INSTALAÇÃO CONCLUÍDA!"
    
    echo -e "${GREEN}Seu Kubernetes (Minikube) está pronto!${NC}\n"
    
    echo -e "${BLUE}📝 Próximos passos:${NC}"
    echo ""
    echo "1️⃣  Navegue para o diretório dos manifestos:"
    echo -e "   ${YELLOW}cd /root/fiap/techChallenge/fase2/challenge/k8s${NC}"
    echo ""
    echo "2️⃣  Valide os manifestos:"
    echo -e "   ${YELLOW}./validate.sh${NC}"
    echo ""
    echo "3️⃣  Implante seus serviços (substitua o ID da sua conta AWS):"
    echo -e "   ${YELLOW}./deploy.sh 123456789012${NC}"
    echo ""
    echo "4️⃣  Verifique o status:"
    echo -e "   ${YELLOW}kubectl get pods -n tech-challenge${NC}"
    echo ""
    echo "5️⃣  Para acessar o dashboard do Minikube:"
    echo -e "   ${YELLOW}minikube dashboard${NC}"
    echo ""
    
    echo -e "${BLUE}📚 Documentação útil:${NC}"
    echo "  • COMECE_AQUI.md - Guia rápido em Português"
    echo "  • README.md - Guia completo"
    echo "  • CHEATSHEET.md - Comandos úteis do kubectl"
    echo ""
}

# MAIN
main() {
    clear
    
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                                                                  ║"
    echo "║     Script de Instalação Automática: Minikube + kubectl          ║"
    echo "║                    Fedora Linux                                  ║"
    echo "║                                                                  ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"
    
    echo "Este script vai:"
    echo "  ✓ Verificar pré-requisitos"
    echo "  ✓ Instalar Docker"
    echo "  ✓ Instalar Minikube"
    echo "  ✓ Instalar kubectl"
    echo "  ✓ Iniciar o cluster"
    echo ""
    
    read -p "Deseja continuar? (s/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        print_warning "Instalação cancelada"
        exit 1
    fi
    
    # Executar etapas
    check_prerequisites
    install_docker
    install_minikube
    install_kubectl
    start_minikube
    verify_installation
    next_steps
}

# Executar
main "$@"
