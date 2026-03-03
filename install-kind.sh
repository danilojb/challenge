#!/bin/bash

#═══════════════════════════════════════════════════════════════════════════
# Script de Instalação Automática: KIND (Kubernetes in Docker) no Fedora
# Uso: ./install-kind.sh
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
    newgrp docker
}

# PASSO 3: Instalar KIND
install_kind() {
    print_header "PASSO 3: Instalar KIND"
    
    if command -v kind &> /dev/null; then
        print_success "KIND já instalado: $(kind version)"
        return
    fi
    
    print_step "Baixando KIND..."
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64 2>/dev/null
    
    print_step "Instalando..."
    chmod +x ./kind
    sudo install -o root -g root -m 0755 kind /usr/local/bin/kind
    rm ./kind
    
    print_success "KIND instalado: $(kind version)"
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
    
    cd - >/dev/null
}

# PASSO 5: Criar cluster KIND
create_kind_cluster() {
    print_header "PASSO 5: Criar Cluster KIND"
    
    # Verificar se cluster já existe
    if kind get clusters 2>/dev/null | grep -q "kind"; then
        print_warning "Cluster 'kind' já existe"
        read -p "Deseja recriá-lo? (s/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            print_step "Deletando cluster existente..."
            kind delete cluster
        else
            print_success "Usando cluster existente"
            return
        fi
    fi
    
    # Criar arquivo de configuração
    print_step "Criando configuração do cluster..."
    cat > /tmp/kind-config.yaml << 'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: kind
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      - containerPort: 443
        hostPort: 443
        protocol: TCP
  - role: worker
  - role: worker
EOF

    print_step "Iniciando cluster KIND (isso pode levar 1-2 minutos)..."
    kind create cluster --config /tmp/kind-config.yaml
    
    print_success "Cluster KIND criado!"
}

# PASSO 6: Instalar Ingress Controller
install_ingress() {
    print_header "PASSO 6: Instalar Ingress Controller"
    
    print_step "Instalando Nginx Ingress Controller..."
    
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml >/dev/null 2>&1
    
    print_step "Aguardando Ingress Controller estar pronto..."
    kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=120s >/dev/null 2>&1
    
    print_success "Ingress Controller instalado"
}

# PASSO 7: Verificação final
verify_installation() {
    print_header "PASSO 7: Verificação Final"
    
    print_step "Verificando cluster..."
    kubectl get nodes
    
    print_step "Verificando pods..."
    kubectl get pods --all-namespaces | head -20
}

# PASSO 8: Próximos passos
next_steps() {
    print_header "✅ INSTALAÇÃO CONCLUÍDA!"
    
    echo -e "${GREEN}Seu Kubernetes (KIND) está pronto!${NC}\n"
    
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
    
    echo -e "${BLUE}📚 Documentação útil:${NC}"
    echo "  • COMECE_AQUI.md - Guia rápido em Português"
    echo "  • README.md - Guia completo"
    echo "  • CHEATSHEET.md - Comandos úteis do kubectl"
    echo ""
    
    echo -e "${BLUE}ℹ️  Informações do KIND:${NC}"
    echo "  • Ver cluster: kind get clusters"
    echo "  • Deletar cluster: kind delete cluster"
    echo "  • Documentação: https://kind.sigs.k8s.io/"
    echo ""
}

# MAIN
main() {
    clear
    
    echo -e "${BLUE}"
    cat << 'ASCII_ART'
╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║              Script de Instalação Automática: KIND + kubectl               ║
║                          Fedora Linux                                      ║
║                                                                            ║
║  KIND = Kubernetes In Docker -> roda Kubernetes em containers Docker       ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝
ASCII_ART
    echo -e "${NC}\n"
    
    echo "Este script vai:"
    echo "  ✓ Verificar pré-requisitos"
    echo "  ✓ Instalar Docker"
    echo "  ✓ Instalar KIND"
    echo "  ✓ Instalar kubectl"
    echo "  ✓ Criar cluster KIND"
    echo "  ✓ Instalar Ingress Controller"
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
    install_kind
    install_kubectl
    create_kind_cluster
    install_ingress
    verify_installation
    next_steps
}

# Executar
main "$@"
