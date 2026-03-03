.PHONY: help deploy validate clean logs status forward test-connectivity test-db resources

help:
	@echo "────────────────────────────────────────────────────────────"
	@echo "Tech Challenge - Kubernetes Commands"
	@echo "────────────────────────────────────────────────────────────"
	@echo ""
	@echo "Deployment:"
	@echo "  make deploy              Fazer deploy de todos os serviços"
	@echo "  make validate            Validar os manifestos YAML"
	@echo "  make clean               Remover todos os recursos"
	@echo ""
	@echo "Monitoramento:"
	@echo "  make status              Ver status geral do cluster"
	@echo "  make logs SERVICE=auth   Ver logs de um serviço"
	@echo "  make resources           Ver uso de recursos"
	@echo ""
	@echo "Debugging:"
	@echo "  make forward SERVICE=auth PORT=8001  Port-forward para um serviço"
	@echo "  make test-connectivity   Testar conectividade entre serviços"
	@echo "  make test-db DB=auth     Testar conexão com banco de dados"
	@echo ""
	@echo "Configuração:"
	@echo "  make set-ecr-id ECR_ID=123456789012  Atualizar ECR ID"
	@echo ""

deploy:
	@echo "🚀 Iniciando deployment..."
	@./deploy.sh $(ECR_ID)

validate:
	@echo "🔍 Validando manifestos..."
	@./validate.sh

clean:
	@echo "🗑️  Removendo recursos..."
	@./cleanup.sh

status:
	@echo "📊 Status do cluster..."
	@./troubleshoot.sh status

logs:
	@./troubleshoot.sh logs $(SERVICE)-service

resources:
	@./troubleshoot.sh resources

forward:
	@./troubleshoot.sh forward $(SERVICE) $(PORT)

test-connectivity:
	@./troubleshoot.sh connectivity

test-db:
	@./troubleshoot.sh dbtest $(DB)

set-ecr-id:
	@echo "🔄 Atualizando ECR ID para: $(ECR_ID)"
	@find . -name "deployment.yaml" -exec sed -i 's/<ECR_ACCOUNT_ID>/$(ECR_ID)/g' {} \;
	@echo "✅ ECR ID atualizado"

# Criar namespaces
namespace:
	@echo "📦 Criando namespaces..."
	@kubectl apply -f namespace.yaml

# Deploy individual dos componentes
deploy-databases:
	@echo "🗄️  Deployando bancos de dados..."
	@kubectl apply -f databases/

deploy-services:
	@echo "🔧 Deployando microsserviços..."
	@kubectl apply -f auth-service/
	@kubectl apply -f flag-service/
	@kubectl apply -f targeting-service/
	@kubectl apply -f evaluation-service/
	@kubectl apply -f analytics-service/

deploy-ingress:
	@echo "🌐 Deployando Ingress..."
	@kubectl apply -f ingress.yaml

# Verificar status dos pods
pods:
	@echo "📋 Pods em tech-challenge:"
	@kubectl get pods -n tech-challenge -o wide

pods-db:
	@echo "📋 Pods em tech-challenge-db:"
	@kubectl get pods -n tech-challenge-db -o wide

# Services
services:
	@echo "🔌 Services:"
	@kubectl get svc -n tech-challenge -o wide

# Ingress
ingress:
	@echo "🌐 Ingress:"
	@kubectl get ingress -n tech-challenge -o wide

# Describe um pod específico
describe:
	@kubectl describe pod $(POD) -n tech-challenge

# Shell em um pod
shell:
	@kubectl exec -it $(POD) -n tech-challenge -- /bin/bash

# Escalabilidade
scale:
	@echo "Escalando deployment $(SERVICE) para $(REPLICAS) réplicas..."
	@kubectl scale deployment/$(SERVICE) -n tech-challenge --replicas=$(REPLICAS)

# Restart de um deployment
restart:
	@echo "🔄 Reiniciando $(SERVICE)..."
	@kubectl rollout restart deployment/$(SERVICE) -n tech-challenge

# Histórico de rollout
rollout-history:
	@kubectl rollout history deployment/$(SERVICE) -n tech-challenge

# Rollback de um deployment
rollback:
	@echo "⏮️  Fazendo rollback de $(SERVICE)..."
	@kubectl rollout undo deployment/$(SERVICE) -n tech-challenge

# Checar eventos
events:
	@kubectl get events -n tech-challenge --sort-by='.lastTimestamp'

# Apply customizado (útil para atualizações)
apply-auth:
	@kubectl apply -f auth-service/secret.yaml
	@kubectl apply -f auth-service/configmap.yaml
	@kubectl apply -f auth-service/deployment.yaml
	@kubectl apply -f auth-service/service.yaml

apply-flag:
	@kubectl apply -f flag-service/secret.yaml
	@kubectl apply -f flag-service/configmap.yaml
	@kubectl apply -f flag-service/deployment.yaml
	@kubectl apply -f flag-service/service.yaml

apply-targeting:
	@kubectl apply -f targeting-service/secret.yaml
	@kubectl apply -f targeting-service/configmap.yaml
	@kubectl apply -f targeting-service/deployment.yaml
	@kubectl apply -f targeting-service/service.yaml

apply-evaluation:
	@kubectl apply -f evaluation-service/secret.yaml
	@kubectl apply -f evaluation-service/configmap.yaml
	@kubectl apply -f evaluation-service/deployment.yaml
	@kubectl apply -f evaluation-service/service.yaml

apply-analytics:
	@kubectl apply -f analytics-service/secret.yaml
	@kubectl apply -f analytics-service/configmap.yaml
	@kubectl apply -f analytics-service/deployment.yaml
	@kubectl apply -f analytics-service/service.yaml

# Teste de saúde dos serviços
health-check:
	@echo "🏥 Verificando saúde dos serviços..."
	@for service in auth flag targeting evaluation analytics; do \
		echo "Testando $$service-service..."; \
		kubectl run -it --rm health-check-$$service --image=curlimages/curl --restart=Never -n tech-challenge -- \
			curl -s http://$$service-service.tech-challenge.svc.cluster.local:8000/health > /dev/null && echo "✅ OK" || echo "❌ FALHA"; \
	done

# Exportar manifestos aplicados
export-manifests:
	@mkdir -p ./exported
	@echo "📥 Exportando manifestos aplicados..."
	@kubectl get all -n tech-challenge -o yaml > ./exported/tech-challenge.yaml
	@kubectl get all -n tech-challenge-db -o yaml > ./exported/tech-challenge-db.yaml
	@echo "✅ Manifestos exportados em ./exported/"

# Backup de dados
backup-secrets:
	@mkdir -p ./backups
	@echo "🔐 Fazendo backup de secrets..."
	@kubectl get secrets -n tech-challenge -o yaml > ./backups/tech-challenge-secrets.yaml
	@kubectl get secrets -n tech-challenge-db -o yaml > ./backups/tech-challenge-db-secrets.yaml
	@echo "✅ Backup concluído em ./backups/"

# Restore de dados
restore-secrets:
	@echo "🔄 Restaurando secrets..."
	@kubectl apply -f ./backups/tech-challenge-secrets.yaml
	@kubectl apply -f ./backups/tech-challenge-db-secrets.yaml
	@echo "✅ Secrets restaurados"
