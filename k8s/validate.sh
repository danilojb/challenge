#!/bin/bash

################################################################################
# Tech Challenge - Kubernetes Manifests Validator
# Valida e faz dry-run dos manifestos antes do deployment
################################################################################

set -e

# Cores
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

validate_yaml() {
    local file=$1
    log_info "Validando: $file"
    
    if kubectl apply -f "$file" --dry-run=client -o yaml > /dev/null 2>&1; then
        log_success "✓ YAML válido"
        return 0
    else
        log_error "✗ YAML inválido"
        kubectl apply -f "$file" --dry-run=client -o yaml
        return 1
    fi
}

check_secrets_encoded() {
    local secret_file=$1
    log_info "Verificando encoding de secrets: $secret_file"
    
    if grep -q "^  [a-z-]*: [A-Za-z0-9+/]*=$" "$secret_file"; then
        log_success "Secrets parecem estar em base64"
        return 0
    else
        log_warning "Alguns valores podem não estar em base64"
        grep "data:" -A 10 "$secret_file"
        return 1
    fi
}

main() {
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "🔍 Tech Challenge - Kubernetes Manifests Validator"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    
    local errors=0
    local warnings=0
    
    # Validar namespaces
    log_info "Validando namespaces..."
    validate_yaml k8s/namespace.yaml || ((errors++))
    echo ""
    
    # Validar cada serviço
    for service in auth-service flag-service targeting-service evaluation-service analytics-service; do
        log_info "Validando $service..."
        
        if [ -f "k8s/$service/secret.yaml" ]; then
            check_secrets_encoded "k8s/$service/secret.yaml" || ((warnings++))
        fi
        
        for manifest in k8s/$service/*.yaml; do
            validate_yaml "$manifest" || ((errors++))
        done
        echo ""
    done
    
    # Validar databases
    log_info "Validando bancos de dados..."
    for db_file in k8s/databases/*.yaml; do
        validate_yaml "$db_file" || ((errors++))
    done
    echo ""
    
    # Validar ingress
    log_info "Validando Ingress..."
    validate_yaml k8s/ingress.yaml || ((errors++))
    echo ""
    
    # Resumo
    echo "════════════════════════════════════════════════════════════"
    if [ $errors -eq 0 ]; then
        log_success "Todos os manifestos são válidos!"
    else
        log_error "Encontrados $errors erros!"
        exit 1
    fi
    
    if [ $warnings -gt 0 ]; then
        log_warning "Encontrados $warnings avisos"
    fi
    echo ""
}

main "$@"
