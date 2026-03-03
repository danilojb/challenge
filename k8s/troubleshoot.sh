#!/bin/bash

################################################################################
# Tech Challenge - Kubernetes Troubleshooting Guide & Utilities
# Funções para debugar e monitorar o deployment
################################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

# 1. Verificar status geral do cluster
status_cluster() {
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "🔍 Status do Cluster Kubernetes"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    
    log_info "Informações do Cluster:"
    kubectl cluster-info
    echo ""
    
    log_info "Nodes:"
    kubectl get nodes -o wide
    echo ""
    
    log_info "Pods (tech-challenge):"
    kubectl get pods -n tech-challenge -o wide
    echo ""
    
    log_info "Pods (tech-challenge-db):"
    kubectl get pods -n tech-challenge-db -o wide
    echo ""
}

# 2. Ver logs de um serviço
service_logs() {
    local service=$1
    if [ -z "$service" ]; then
        log_error "Uso: logs <service-name>"
        echo "Serviços disponíveis: auth flag targeting evaluation analytics"
        return 1
    fi
    
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "📋 Logs: $service-service"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    
    kubectl logs deployment/$service-service -n tech-challenge -f --all-containers=true
}

# 3. Descrever um pod
describe_pod() {
    local pod=$1
    if [ -z "$pod" ]; then
        log_error "Uso: describe <pod-name>"
        return 1
    fi
    
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "📝 Descrição do Pod: $pod"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    
    kubectl describe pod $pod -n tech-challenge
}

# 4. Usar port-forward
port_forward_service() {
    local service=$1
    local port=$2
    
    if [ -z "$service" ] || [ -z "$port" ]; then
        log_error "Uso: forward <service> <port>"
        echo "Exemplo: forward auth-service 8001"
        return 1
    fi
    
    echo ""
    log_info "Port-forwarding $service para localhost:$port"
    log_info "Pressione Ctrl+C para parar"
    echo ""
    
    kubectl port-forward svc/$service $port:8000 -n tech-challenge
}

# 5. Testar conectividade entre serviços
connectivity_test() {
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "🌐 Teste de Conectividade entre Serviços"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    
    log_info "Testando conectividade interna..."
    
    # Usar um pod debug
    log_info "Criando pod debug..."
    kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n tech-challenge -- \
        /bin/sh -c "
        echo '--- Testando auth-service ---'
        curl -v http://auth-service.tech-challenge.svc.cluster.local:8000/health || echo 'Falha'
        
        echo ''
        echo '--- Testando flag-service ---'
        curl -v http://flag-service.tech-challenge.svc.cluster.local:8000/health || echo 'Falha'
        
        echo ''
        echo '--- Testando targeting-service ---'
        curl -v http://targeting-service.tech-challenge.svc.cluster.local:8000/health || echo 'Falha'
        
        echo ''
        echo '--- Testando evaluation-service ---'
        curl -v http://evaluation-service.tech-challenge.svc.cluster.local:8000/health || echo 'Falha'
        
        echo ''
        echo '--- Testando analytics-service ---'
        curl -v http://analytics-service.tech-challenge.svc.cluster.local:8000/health || echo 'Falha'
        "
}

# 6. Testar banco de dados
db_test() {
    local db=$1
    if [ -z "$db" ]; then
        log_error "Uso: dbtest <auth|flag|target>"
        return 1
    fi
    
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "🗄️  Teste de Conexão: $db-db"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    
    case $db in
        auth)
            log_info "Testando conexão com auth-db..."
            kubectl run -it --rm db-test --image=postgres:15 --restart=Never -n tech-challenge -- \
                psql -h auth-db.tech-challenge-db.svc.cluster.local -U auth -d authdb -c "SELECT version();"
            ;;
        flag)
            log_info "Testando conexão com flag-db..."
            kubectl run -it --rm db-test --image=postgres:15 --restart=Never -n tech-challenge -- \
                psql -h flag-db.tech-challenge-db.svc.cluster.local -U flag -d flagdb -c "SELECT version();"
            ;;
        target)
            log_info "Testando conexão com target-db..."
            kubectl run -it --rm db-test --image=postgres:15 --restart=Never -n tech-challenge -- \
                psql -h target-db.tech-challenge-db.svc.cluster.local -U target -d targetdb -c "SELECT version();"
            ;;
        *)
            log_error "Banco desconhecido: $db"
            ;;
    esac
}

# 7. Ver recursos
resource_usage() {
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "📊 Uso de Recursos"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    
    log_info "Nodes:"
    kubectl top nodes
    echo ""
    
    log_info "Pods (tech-challenge):"
    kubectl top pods -n tech-challenge
    echo ""
    
    log_info "Pods (tech-challenge-db):"
    kubectl top pods -n tech-challenge-db
    echo ""
}

# 8. Interface interativa
interactive_menu() {
    while true; do
        echo ""
        echo "════════════════════════════════════════════════════════════"
        echo "🛠️  Tech Challenge - Kubernetes Troubleshooting"
        echo "════════════════════════════════════════════════════════════"
        echo ""
        echo "1. Status geral do cluster"
        echo "2. Ver logs de um serviço"
        echo "3. Descrever um pod"
        echo "4. Port-forward para um serviço"
        echo "5. Teste de conectividade"
        echo "6. Teste de banco de dados"
        echo "7. Uso de recursos"
        echo "8. Sair"
        echo ""
        read -p "Escolha uma opção: " option
        
        case $option in
            1) status_cluster ;;
            2) 
                read -p "Nome do serviço (auth/flag/targeting/evaluation/analytics): " svc
                service_logs "$svc-service" ;;
            3)
                read -p "Nome do pod: " pod
                describe_pod "$pod" ;;
            4)
                read -p "Nome do serviço: " svc
                read -p "Porta local: " port
                port_forward_service "$svc" "$port" ;;
            5) connectivity_test ;;
            6)
                read -p "Banco de dados (auth/flag/target): " db
                db_test "$db" ;;
            7) resource_usage ;;
            8) 
                log_info "Saindo..."
                exit 0 ;;
            *)
                log_error "Opção inválida"
                ;;
        esac
    done
}

# Menu de linha de comando
if [ $# -eq 0 ]; then
    interactive_menu
else
    case $1 in
        status) status_cluster ;;
        logs) service_logs $2 ;;
        describe) describe_pod $2 ;;
        forward) port_forward_service $2 $3 ;;
        connectivity) connectivity_test ;;
        dbtest) db_test $2 ;;
        resources) resource_usage ;;
        *)
            echo "Uso: $0 [comando] [argumentos]"
            echo ""
            echo "Comandos:"
            echo "  status                 - Status geral do cluster"
            echo "  logs <service>         - Ver logs de um serviço"
            echo "  describe <pod>         - Descrever um pod"
            echo "  forward <service> <port> - Port-forward para um serviço"
            echo "  connectivity           - Teste de conectividade"
            echo "  dbtest <db>           - Teste de banco de dados"
            echo "  resources              - Uso de recursos"
            echo ""
            echo "Sem argumentos abre o menu interativo"
            ;;
    esac
fi
