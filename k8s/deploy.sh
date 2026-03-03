#!/bin/bash

################################################################################
# Tech Challenge - Kubernetes Deployment Script
# Automatiza o deployment de todos os microsserviços
################################################################################

set -e  # Exit on error

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
ECR_ACCOUNT_ID="${1:-123456789012}"
ECR_REGION="${2:-us-east-1}"
TIMEOUT=300

# Funções utilitárias
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Verificar pré-requisitos
check_prerequisites() {
    log_info "Verificando pré-requisitos..."
    
    # Verificar kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl não encontrado!"
        exit 1
    fi
    log_success "kubectl encontrado"
    
    # Verificar cluster
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Não foi possível conectar ao cluster Kubernetes!"
        exit 1
    fi
    log_success "Cluster Kubernetes acessível"
    
    # Verificar Ingress Controller
    if ! kubectl get namespace ingress-nginx &> /dev/null; then
        log_warning "Nginx Ingress Controller não encontrado. Instale com:"
        echo ""
        echo "  helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx"
        echo "  helm repo update"
        echo "  helm install nginx-ingress ingress-nginx/ingress-nginx"
        echo ""
        read -p "Continuar mesmo assim? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        log_success "Nginx Ingress Controller encontrado"
    fi
}

# Atualizar ECR Account ID
update_ecr_ids() {
    log_info "Atualizando ECR Account ID para: $ECR_ACCOUNT_ID"
    
    # Criar arquivo temporário para restaurar depois
    find */deployment.yaml -type f | while read file; do
        sed -i "s/<ECR_ACCOUNT_ID>/$ECR_ACCOUNT_ID/g" "$file"
        sed -i "s/<REGION>/$ECR_REGION/g" "$file"
    done
    
    log_success "ECR IDs atualizados"
}

# Criar namespaces
create_namespaces() {
    log_info "Criando namespaces..."
    kubectl apply -f namespace.yaml
    log_success "Namespaces criados"
}

# Deploy bancos de dados
deploy_databases() {
    log_info "Deployando bancos de dados e cache..."
    
    kubectl apply -f databases/auth-db.yaml
    log_success "Auth Database deployado"
    
    kubectl apply -f databases/flag-db.yaml
    log_success "Flag Database deployado"
    
    kubectl apply -f databases/target-db.yaml
    log_success "Target Database deployado"
    
    kubectl apply -f databases/redis.yaml
    log_success "Redis deployado"
    
    log_info "Aguardando bancos de dados ficarem prontos (até ${TIMEOUT}s)..."
    
    kubectl wait --for=condition=Ready pod -l app=auth-db -n tech-challenge-db --timeout=${TIMEOUT}s || true
    kubectl wait --for=condition=Ready pod -l app=flag-db -n tech-challenge-db --timeout=${TIMEOUT}s || true
    kubectl wait --for=condition=Ready pod -l app=target-db -n tech-challenge-db --timeout=${TIMEOUT}s || true
    kubectl wait --for=condition=Ready pod -l app=redis -n tech-challenge --timeout=${TIMEOUT}s || true
    
    log_success "Bancos de dados prontos"
}

# Deploy microsserviços
deploy_microservices() {
    log_info "Deployando microsserviços..."
    
    # Auth Service
    log_info "Deployando auth-service..."
    kubectl apply -f auth-service/secret.yaml
    kubectl apply -f auth-service/configmap.yaml
    kubectl apply -f auth-service/deployment.yaml
    kubectl apply -f auth-service/service.yaml
    log_success "auth-service deployado"
    
    # Aguardar auth-service ficar pronto
    log_info "Aguardando auth-service ficar pronto..."
    kubectl wait --for=condition=Ready pod -l app=auth-service -n tech-challenge --timeout=${TIMEOUT}s || true
    
    # Flag Service
    log_info "Deployando flag-service..."
    kubectl apply -f flag-service/secret.yaml
    kubectl apply -f flag-service/configmap.yaml
    kubectl apply -f flag-service/deployment.yaml
    kubectl apply -f flag-service/service.yaml
    log_success "flag-service deployado"
    
    # Targeting Service
    log_info "Deployando targeting-service..."
    kubectl apply -f targeting-service/secret.yaml
    kubectl apply -f targeting-service/configmap.yaml
    kubectl apply -f targeting-service/deployment.yaml
    kubectl apply -f targeting-service/service.yaml
    log_success "targeting-service deployado"
    
    # Evaluation Service
    log_info "Deployando evaluation-service..."
    kubectl apply -f evaluation-service/secret.yaml
    kubectl apply -f evaluation-service/configmap.yaml
    kubectl apply -f evaluation-service/deployment.yaml
    kubectl apply -f evaluation-service/service.yaml
    log_success "evaluation-service deployado"
    
    # Analytics Service
    log_info "Deployando analytics-service..."
    kubectl apply -f analytics-service/secret.yaml
    kubectl apply -f analytics-service/configmap.yaml
    kubectl apply -f analytics-service/deployment.yaml
    kubectl apply -f analytics-service/service.yaml
    log_success "analytics-service deployado"
    
    log_success "Todos os microsserviços deployados"
}

# Deploy Ingress
deploy_ingress() {
    log_info "Deployando Ingress..."
    kubectl apply -f ingress.yaml
    log_success "Ingress deployado"
}

# Status final
show_status() {
    echo ""
    echo "════════════════════════════════════════════════════════════"
    log_success "Deployment concluído com sucesso!"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    
    log_info "📊 Status dos Pods - Namespace: tech-challenge"
    kubectl get pods -n tech-challenge -o wide
    echo ""
    
    log_info "📊 Status dos Pods - Namespace: tech-challenge-db"
    kubectl get pods -n tech-challenge-db -o wide
    echo ""
    
    log_info "🔌 Services"
    kubectl get svc -n tech-challenge -o wide
    echo ""
    
    log_info "🌐 Ingress"
    kubectl get ingress -n tech-challenge -o wide
    echo ""
    
    INGRESS_IP=$(kubectl get ingress api-gateway -n tech-challenge -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "PENDING")
    if [ "$INGRESS_IP" != "PENDING" ]; then
        log_success "Ingress IP: $INGRESS_IP"
        echo ""
        log_info "Adicione ao seu /etc/hosts:"
        echo "  $INGRESS_IP  api.techChallenge.local"
        echo ""
        log_info "Endpoints disponíveis:"
        echo "  http://api.techChallenge.local/auth"
        echo "  http://api.techChallenge.local/flags"
        echo "  http://api.techChallenge.local/targets"
        echo "  http://api.techChallenge.local/evaluations"
        echo "  http://api.techChallenge.local/analytics"
    else
        log_warning "Ingress IP ainda não foi atribuído (status: PENDING)"
        echo ""
        log_info "Para minikube, use:"
        echo "  minikube service api-gateway -n tech-challenge"
    fi
    echo ""
}

# Teste de saúde
health_check() {
    log_info "Executando health checks..."
    
    # Aguardar mais um pouco para garantir que os services estão prontos
    sleep 5
    
    # Verificar se os pods estão rodando
    RUNNING_PODS=$(kubectl get pods -n tech-challenge --field-selector=status.phase=Running -o jsonpath='{.items[*].metadata.name}' | wc -w)
    EXPECTED_PODS=10  # 5 services * 2 replicas
    
    if [ "$RUNNING_PODS" -ge 8 ]; then
        log_success "Pelo menos 80% dos pods estão rodando ($RUNNING_PODS/$EXPECTED_PODS)"
    else
        log_warning "Apenas $RUNNING_PODS pods estão rodando (esperado: $EXPECTED_PODS)"
    fi
}

# Menu principal
main() {
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "🚀  Tech Challenge - Kubernetes Deployment Script"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    
    log_info "ECR Account ID: $ECR_ACCOUNT_ID"
    log_info "ECR Region: $ECR_REGION"
    echo ""
    
    check_prerequisites
    update_ecr_ids
    create_namespaces
    deploy_databases
    deploy_microservices
    deploy_ingress
    health_check
    show_status
}

# Executar
main "$@"
