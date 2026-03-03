#!/bin/bash

################################################################################
# Tech Challenge - Kubernetes Cleanup Script
# Remove todos os componentes do deployment
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

main() {
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "🗑️  Tech Challenge - Kubernetes Cleanup Script"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    
    log_warning "ATENÇÃO: Isso removerá TODOS os componentes do deployment!"
    echo ""
    read -p "Tem certeza? Digite 'sim' para confirmar: " -r
    echo
    if [[ ! $REPLY =~ ^sim$ ]]; then
        log_info "Abortado"
        exit 0
    fi
    echo ""
    
    # Remover em ordem reversa
    log_info "Removendo Ingress..."
    kubectl delete -f k8s/ingress.yaml --ignore-not-found=true || true
    log_success "Ingress removido"
    echo ""
    
    log_info "Removendo microsserviços..."
    kubectl delete -f k8s/analytics-service/ --ignore-not-found=true || true
    kubectl delete -f k8s/evaluation-service/ --ignore-not-found=true || true
    kubectl delete -f k8s/targeting-service/ --ignore-not-found=true || true
    kubectl delete -f k8s/flag-service/ --ignore-not-found=true || true
    kubectl delete -f k8s/auth-service/ --ignore-not-found=true || true
    log_success "Microsserviços removidos"
    echo ""
    
    log_info "Removendo bancos de dados..."
    kubectl delete -f k8s/databases/ --ignore-not-found=true || true
    log_success "Bancos de dados removidos"
    echo ""
    
    log_info "Removendo namespaces..."
    kubectl delete -f k8s/namespace.yaml --ignore-not-found=true || true
    log_success "Namespaces removidos"
    echo ""
    
    log_success "Cleanup completado!"
    echo ""
    
    # Verificar status
    log_info "Verificando status..."
    if kubectl get namespace tech-challenge &> /dev/null; then
        log_warning "tech-challenge namespace ainda existe (pode levar alguns segundos para dissaparecer)"
    else
        log_success "tech-challenge namespace foi removido"
    fi
    
    if kubectl get namespace tech-challenge-db &> /dev/null; then
        log_warning "tech-challenge-db namespace ainda existe (pode levar alguns segundos para dissaparecer)"
    else
        log_success "tech-challenge-db namespace foi removido"
    fi
}

main "$@"
