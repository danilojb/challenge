#!/bin/bash

#═══════════════════════════════════════════════════════════════════════════
# Script de Instalação: KIND + kubectl para WSL2 com Root
# Otimizado para Windows Subsystem for Linux
# Uso: ./install-wsl.sh
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

# PASSO 1: Verificação de pré-requisitos WSL
check_wsl_prerequisites() {
    print_header "PASSO 1: Verificar Pré-requisitos WSL"
    
    # Verificar se é WSL
    if grep -qi microsoft /proc/version 2>/dev/null; then
        print_success "WSL detectado"
    else
        print_warning "Pode não ser WSL, mas continuaremos"
    fi
    
    # Verificar se é root
    if [[ $EUID -eq 0 ]]; then
        print_success "Executando como root (OK em WSL)"
    else
        print_warning "Não está como root, mas pode funcionar"
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

# PASSO 2: Preparar Sistema
prepare_system() {
    print_header "PASSO 2: Preparar Sistema WSL"
    
    print_step "Atualizando pacotes..."
    apt update >/dev/null 2>&1 || true
    apt upgrade -y >/dev/null 2>&1 || true
    
    print_step "Instalando dependências..."
    apt install -y curl wget git ca-certificates 2>/dev/null || print_warning "Alguns pacotes já instalados"
    
    print_success "Sistema preparado"
}

# PASSO 3: Verificar/Instalar Docker
setup_docker() {
    print_header "PASSO 3: Configurar Docker"
    
    if command -v docker &> /dev/null; then
        print_success "Docker já instalado: $(docker --version)"
        
        # Verificar se está rodando
        if docker ps &>/dev/null 2>&1; then
            print_success "Docker daemon rodando"
            return
        else
            print_step "Iniciando Docker daemon..."
            service docker start || systemctl start docker || true
            sleep 2
            if docker ps &>/dev/null 2>&1; then
                print_success "Docker iniciado"
            else
                print_warning "Docker pode não estar rodando. Tente depois: service docker start"
            fi
        fi
    else
        print_step "Instalando Docker..."
        apt install -y docker.io 2>/dev/null || true
        
        print_step "Iniciando Docker..."
        service docker start || systemctl start docker || true
        sleep 2
        
        print_success "Docker instalado e iniciado"
    fi
}

# PASSO 4: Instalar KIND
install_kind() {
    print_header "PASSO 4: Instalar KIND"
    
    if command -v kind &> /dev/null; then
        print_success "KIND já instalado: $(kind version)"
        return
    fi
    
    print_step "Baixando KIND..."
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64 2>/dev/null
    
    print_step "Instalando..."
    chmod +x ./kind
    mv ./kind /usr/local/bin/kind
    
    print_success "KIND instalado: $(kind version)"
}

# PASSO 5: Instalar kubectl
install_kubectl() {
    print_header "PASSO 5: Instalar kubectl"
    
    if command -v kubectl &> /dev/null; then
        print_success "kubectl já instalado"
        return
    fi
    
    print_step "Baixando kubectl..."
    cd /tmp
    LATEST_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt 2>/dev/null)
    curl -LO "https://dl.k8s.io/release/${LATEST_VERSION}/bin/linux/amd64/kubectl" 2>/dev/null
    
    print_step "Instalando..."
    chmod +x kubectl
    mv kubectl /usr/local/bin/kubectl
    
    print_success "kubectl instalado"
    
    cd - >/dev/null
}

# PASSO 6: Criar cluster KIND com WSL customization
create_kind_cluster() {
    print_header "PASSO 6: Criar Cluster KIND"
    
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
    
    # Criar arquivo de configuração otimizado para WSL
    print_step "Criando configuração do cluster (WSL otimizado)..."
    cat > /tmp/kind-config-wsl.yaml << 'EOF'
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
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
  - role: worker
  - role: worker
EOF

    print_step "Iniciando cluster KIND (2-3 minutos - aguarde)..."
    kind create cluster --config /tmp/kind-config-wsl.yaml
    
    print_success "Cluster KIND criado!"
    
    # Aguardar cluster estar pronto
    print_step "Aguardando cluster estar pronto..."
    kubectl wait --for=condition=Ready node --all --timeout=300s >/dev/null 2>&1
    
    print_success "Cluster pronto!"
}

# PASSO 7: Instalar Ingress Controller
install_ingress() {
    print_header "PASSO 7: Instalar Ingress Controller"
    
    print_step "Instalando Nginx Ingress Controller..."
    
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml >/dev/null 2>&1
    
    print_step "Aguardando Ingress Controller..."
    kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=120s >/dev/null 2>&1
    
    print_success "Ingress Controller instalado"
}

# PASSO 8: Verificação final
verify_installation() {
    print_header "PASSO 8: Verificação Final"
    
    print_step "Status do cluster:"
    kubectl get nodes
    
    print_step "Pods do sistema:"
    kubectl get pods -n kube-system | head -10
    
    print_step "Namespaces:"
    kubectl get namespaces
}

# PASSO 9: Próximos passos WSL
next_steps_wsl() {
    print_header "✅ INSTALAÇÃO CONCLUÍDA PARA WSL!"
    
    echo -e "${GREEN}Seu Kubernetes (KIND) está pronto em WSL!${NC}\n"
    
    echo -e "${BLUE}📝 Próximos passos (da máquina Windows):${NC}"
    echo ""
    echo "1️⃣  Para acessar de fora do WSL, use port-forward:"
    echo -e "   ${YELLOW}kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 80:80${NC}"
    echo ""
    echo "2️⃣  Depois acesse do navegador:"
    echo -e "   ${YELLOW}http://localhost${NC}"
    echo ""
    echo "3️⃣  Implante seus serviços:"
    echo -e "   ${YELLOW}cd /root/fiap/techChallenge/fase2/challenge/k8s${NC}"
    echo -e "   ${YELLOW}./deploy.sh 123456789012${NC}"
    echo ""
    echo "4️⃣  Verifique:"
    echo -e "   ${YELLOW}kubectl get pods -n tech-challenge${NC}"
    echo ""
    
    echo -e "${BLUE}💡 Dicas WSL:${NC}"
    echo "  • Docker está rodando em background"
    echo "  • KIND usa containers ao invés de VMs"
    echo "  • Port-forward permite acessar de Windows"
    echo "  • Reiniciar WSL: wsl --shutdown (no PowerShell)"
    echo ""
}

# MAIN
main() {
    clear
    
    echo -e "${BLUE}"
    cat << 'ASCII_ART'
╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║            🪟 Script Instalação: Kubernetes em WSL2 + Root                ║
║                                                                            ║
║                    Otimizado para Windows Subsystem Linux                  ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝
ASCII_ART
    echo -e "${NC}\n"
    
    echo "Este script vai (para WSL):"
    echo "  ✓ Preparar sistema WSL"
    echo "  ✓ Configurar Docker (nativo WSL)"
    echo "  ✓ Instalar KIND (melhor para WSL)"
    echo "  ✓ Instalar kubectl"
    echo "  ✓ Criar cluster K8s"
    echo "  ✓ Instalar Ingress"
    echo ""
    
    read -p "Deseja continuar? (s/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        print_warning "Instalação cancelada"
        exit 1
    fi
    
    # Executar etapas
    check_wsl_prerequisites
    prepare_system
    setup_docker
    install_kind
    install_kubectl
    create_kind_cluster
    install_ingress
    verify_installation
    next_steps_wsl
}

# Executar
main "$@"
