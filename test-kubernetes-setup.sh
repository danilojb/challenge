#!/bin/bash

#═══════════════════════════════════════════════════════════════════════════
# Verificador de Instalação: Valida se K8s, kubectl e Docker estão OK
# Uso: ./test-kubernetes-setup.sh
#═══════════════════════════════════════════════════════════════════════════

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

tests_passed=0
tests_failed=0

print_test() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━════${NC}"
    echo -e "${BLUE}🧪 Teste: $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━════${NC}\n"
}

test_pass() {
    echo -e "${GREEN}✅ PASSOU${NC}\n"
    ((tests_passed++))
}

test_fail() {
    echo -e "${RED}❌ FALHOU${NC}\n"
    ((tests_failed++))
}

clear
echo -e "${BLUE}"
cat << 'ASCII_ART'
╔══════════════════════════════════════════════════════════════════════════╗
║                                                                          ║
║                  🔧 VERIFICADOR DE INSTALAÇÃO K8S                      ║
║                                                                          ║
║              Validando: Docker, kubectl, Minikube/KIND                  ║
║                                                                          ║
╚══════════════════════════════════════════════════════════════════════════╝
ASCII_ART
echo -e "${NC}\n"

# Teste 1: Docker
print_test "Docker instalado e rodando"
if command -v docker &> /dev/null; then
    docker_version=$(docker --version 2>/dev/null)
    echo "$docker_version"
    if docker ps &>/dev/null; then
        echo -e "${GREEN}Docker daemon rodando${NC}"
        test_pass
    else
        echo -e "${RED}Docker daemon NÃO está rodando${NC}"
        echo "Solução: sudo systemctl start docker"
        test_fail
    fi
else
    echo -e "${RED}Docker NÃO instalado${NC}"
    test_fail
fi

# Teste 2: kubectl
print_test "kubectl instalado"
if command -v kubectl &> /dev/null; then
    kubectl_version=$(kubectl version --client --short 2>/dev/null)
    echo "$kubectl_version"
    test_pass
else
    echo -e "${RED}kubectl NÃO instalado${NC}"
    test_fail
fi

# Teste 3: Minikube
print_test "Minikube instalado"
if command -v minikube &> /dev/null; then
    minikube_version=$(minikube version)
    echo "$minikube_version"
    test_pass
else
    echo -e "${YELLOW}⚠️  Minikube NÃO instalado (Pode estar usando KIND)${NC}"
fi

# Teste 4: KIND
print_test "KIND instalado"
if command -v kind &> /dev/null; then
    kind_version=$(kind version)
    echo "$kind_version"
    test_pass
else
    echo -e "${YELLOW}⚠️  KIND NÃO instalado (Pode estar usando Minikube)${NC}"
fi

# Teste 5: Cluster conectado
print_test "Cluster Kubernetes acessível"
if command -v kubectl &> /dev/null; then
    if kubectl cluster-info &>/dev/null 2>&1; then
        nodes=$(kubectl get nodes 2>/dev/null)
        echo "$nodes"
        test_pass
    else
        echo -e "${YELLOW}⚠️  Cluster NÃO conectado${NC}"
        echo "Solução: Execute 'minikube start' ou 'kind create cluster'"
    fi
else
    echo "kubectl não disponível - pulando teste"
fi

# Teste 6: Nodes Ready
print_test "Nodes no estado Ready"
if command -v kubectl &> /dev/null; then
    ready_nodes=$(kubectl get nodes 2>/dev/null | grep -c "Ready" || true)
    total_nodes=$(kubectl get nodes 2>/dev/null | wc -l)
    
    if [ "$ready_nodes" -gt 0 ]; then
        echo "Nodes Ready: $ready_nodes / $((total_nodes - 1))"
        test_pass
    else
        echo -e "${YELLOW}⚠️  Nenhum node no estado Ready${NC}"
        echo "Aguarde alguns segundos e tente novamente"
    fi
fi

# Teste 7: Namespaces
print_test "Namespaces padrão existem"
if command -v kubectl &> /dev/null; then
    namespaces=$(kubectl get namespaces 2>/dev/null | grep -E "default|kube-system")
    if [ ! -z "$namespaces" ]; then
        echo "$namespaces"
        test_pass
    else
        echo -e "${RED}Namespaces não encontrados${NC}"
        test_fail
    fi
fi

# Teste 8: API Server
print_test "API Server respondendo"
if command -v kubectl &> /dev/null; then
    if kubectl api-versions &>/dev/null 2>&1; then
        api_versions=$(kubectl api-versions | wc -l)
        echo "API resources disponíveis: $api_versions"
        test_pass
    else
        echo -e "${RED}API Server não respondendo${NC}"
        test_fail
    fi
fi

# Teste 9: CoreDNS
print_test "CoreDNS operational (resolução de DNS)"
if command -v kubectl &> /dev/null; then
    coredns=$(kubectl get deployment -n kube-system coredns 2>/dev/null | grep -c "coredns" || echo "0")
    if [ "$coredns" -gt 0 ]; then
        echo "CoreDNS encontrado"
        test_pass
    else
        echo -e "${YELLOW}⚠️  CoreDNS não encontrado (pode estar inicializando)${NC}"
    fi
fi

# Teste 10: Ingress Controller (opcional)
print_test "Ingress Controller (opcional)"
if command -v kubectl &> /dev/null; then
    ingress=$(kubectl get deployments -A 2>/dev/null | grep -i ingress || echo "")
    if [ ! -z "$ingress" ]; then
        echo "Ingress Controller encontrado:"
        echo "$ingress"
        test_pass
    else
        echo -e "${YELLOW}⚠️  Ingress Controller não instalado (será instalado na implantação)${NC}"
    fi
fi

# Resumo
echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}                        📊 RESUMO DOS TESTES"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "Total de testes: $((tests_passed + tests_failed))"
echo -e "${GREEN}✅ Passou: $tests_passed${NC}"
echo -e "${RED}❌ Falhou: $tests_failed${NC}\n"

if [ "$tests_failed" -eq 0 ]; then
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}        🎉 TUDO PRONTO! Kubernetes está instalado!          ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}\n"
    
    echo -e "${BLUE}📝 Próximos passos:${NC}"
    echo ""
    echo "1. Navegue até o diretório de manifestos:"
    echo -e "   ${YELLOW}cd /root/fiap/techChallenge/fase2/challenge/k8s${NC}"
    echo ""
    echo "2. Valide seus manifestos:"
    echo -e "   ${YELLOW}./validate.sh${NC}"
    echo ""
    echo "3. Implante seus serviços:"
    echo -e "   ${YELLOW}./deploy.sh 123456789012${NC}"
    echo ""
    
else
    echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}       ⚠️  ALGUNS TESTES FALHARAM. Leia os erros acima       ${NC}"
    echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}\n"
    
    echo -e "${YELLOW}Sugestões de solução:${NC}"
    echo ""
    echo "1. Se Docker não está rodando:"
    echo -e "   ${YELLOW}sudo systemctl start docker${NC}"
    echo ""
    echo "2. Se Minikube não está rodando:"
    echo -e "   ${YELLOW}minikube start${NC}"
    echo ""
    echo "3. Se KIND não está rodando:"
    echo -e "   ${YELLOW}kind create cluster${NC}"
    echo ""
    echo "4. Para mais detalhes, execute novamente:"
    echo -e "   ${YELLOW}$0${NC}"
    echo ""
fi

echo "Escrito em: $(date)"
echo ""
