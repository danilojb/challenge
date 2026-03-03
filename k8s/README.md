# Kubernetes Manifests - Tech Challenge

## 📋 Visão Geral

Este diretório contém todos os manifestos do Kubernetes necessários para implantar a arquitetura de microsserviços do Tech Challenge em um cluster K8s.

## 🏗️ Estrutura dos Manifestos

```
k8s/
├── namespace.yaml                 # Namespaces: tech-challenge e tech-challenge-db
├── ingress.yaml                   # Ingress para roteamento de tráfego externo
├── auth-service/
│   ├── secret.yaml               # Secrets com MASTER_KEY e DATABASE_URL
│   ├── configmap.yaml            # ConfigMap com PORT e LOG_LEVEL
│   ├── deployment.yaml           # Deployment com 2 replicas, probes e limits
│   └── service.yaml              # ClusterIP Service
├── flag-service/
│   ├── secret.yaml
│   ├── configmap.yaml
│   ├── deployment.yaml
│   └── service.yaml
├── targeting-service/
│   ├── secret.yaml
│   ├── configmap.yaml
│   ├── deployment.yaml
│   └── service.yaml
├── evaluation-service/
│   ├── secret.yaml
│   ├── configmap.yaml
│   ├── deployment.yaml
│   └── service.yaml
├── analytics-service/
│   ├── secret.yaml
│   ├── configmap.yaml
│   ├── deployment.yaml
│   └── service.yaml
└── databases/
    ├── auth-db.yaml             # PostgreSQL + Secret + Service
    ├── flag-db.yaml             # PostgreSQL + Secret + Service
    ├── target-db.yaml           # PostgreSQL + Secret + Service
    └── redis.yaml               # Redis + Service
```

## 🔐 Boas Práticas Implementadas

### 1. **Namespaces**
- `tech-challenge`: Namespace para os microsserviços
- `tech-challenge-db`: Namespace isolado para bancos de dados

### 2. **Secrets (Base64 Encoded)**
- ✅ Senhas de banco de dados
- ✅ MASTER_KEY de autenticação
- ✅ Credenciais AWS
- ✅ Chaves de API
- ✅ URLs de conexão com dados sensíveis

**Baseados em:**
```yaml
data:
  master-key: <base64-encoded>         # admin-secreto-123
  database-url: <base64-encoded>       # postgres://user:pass@host/db
  aws-secret-access-key: <base64-encoded>
```

### 3. **ConfigMaps**
- URLs de serviços internos (usando DNS interno do Kubernetes)
- Portas e configurações não-sensíveis
- Variáveis de ambiente reutilizáveis

**Exemplo:**
```yaml
data:
  AUTH_SERVICE_URL: "http://auth-service.tech-challenge.svc.cluster.local:8000"
  FLAG_SERVICE_URL: "http://flag-service.tech-challenge.svc.cluster.local:8000"
```

### 4. **Recursos (Requests e Limits)**

Cada container tem limits garantidos:

```yaml
resources:
  requests:              # Mínimo garantido
    cpu: 100m
    memory: 128Mi
  limits:                # Máximo permitido
    cpu: 500m
    memory: 512Mi
```

### 5. **Probes (Healthchecks)**

**LivenessProbe:** Reinicia o pod se falhar
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8000
  initialDelaySeconds: 15
  periodSeconds: 10
  failureThreshold: 3
```

**ReadinessProbe:** Remove do balanceamento de carga se falhar
```yaml
readinessProbe:
  httpGet:
    path: /health
    port: 8000
  initialDelaySeconds: 10
  periodSeconds: 5
  failureThreshold: 2
```

### 6. **Deployments**
- ✅ 2 replicas por padrão (alta disponibilidade)
- ✅ RollingUpdate strategy
- ✅ Pod Anti-Affinity (distribuir entre nodes)
- ✅ Variáveis de ambiente injetadas de Secrets/ConfigMaps
- ✅ Security Context

### 7. **Services**
- ✅ Tipo: ClusterIP (simples, eficiente)
- ✅ DNS interno Kubernetes para comunicação entre serviços
- ✅ Named ports para melhor legibilidade

### 8. **Ingress**
- ✅ Nginx Ingress Controller
- ✅ Rate limiting: 100 requisições/min
- ✅ CORS habilitado
- ✅ TLS pronto (com cert-manager)
- ✅ Roteamento por caminho:
  - `/auth` → auth-service
  - `/flags` → flag-service
  - `/targets` → targeting-service
  - `/evaluations` → evaluation-service
  - `/analytics` → analytics-service

## 🚀 Instruções de Deployment

### Pré-requisitos

1. **Cluster Kubernetes rodando:**
   ```bash
   kubectl cluster-info
   ```

2. **Nginx Ingress Controller instalado:**
   ```bash
   helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
   helm repo update
   helm install nginx-ingress ingress-nginx/ingress-nginx
   ```

3. **Cert-Manager (para HTTPS):**
   ```bash
   kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
   ```

### 1. Criar Namespaces
```bash
kubectl apply -f k8s/namespace.yaml
```

### 2. Imagens no ECR
Antes de fazer deploy, substitua `<ECR_ACCOUNT_ID>` em todos os deployments:

```bash
# Para cada service
sed -i 's/<ECR_ACCOUNT_ID>/123456789012/g' k8s/*/deployment.yaml

# Verificar
grep "dkr.ecr" k8s/*/deployment.yaml
```

### 3. Deploy dos Bancos de Dados
```bash
# Auth Database
kubectl apply -f k8s/databases/auth-db.yaml

# Flag Database
kubectl apply -f k8s/databases/flag-db.yaml

# Target Database
kubectl apply -f k8s/databases/target-db.yaml

# Redis
kubectl apply -f k8s/databases/redis.yaml

# Aguardar poderes ficarem prontos
kubectl wait --for=condition=Ready pod -l app=auth-db -n tech-challenge-db --timeout=300s
kubectl wait --for=condition=Ready pod -l app=flag-db -n tech-challenge-db --timeout=300s
kubectl wait --for=condition=Ready pod -l app=target-db -n tech-challenge-db --timeout=300s
kubectl wait --for=condition=Ready pod -l app=redis -n tech-challenge --timeout=300s
```

### 4. Deploy dos Microsserviços
```bash
# Auth Service
kubectl apply -f k8s/auth-service/

# Flag Service (após auth estar pronto)
kubectl wait --for=condition=Ready pod -l app=auth-service -n tech-challenge --timeout=300s
kubectl apply -f k8s/flag-service/

# Targeting Service
kubectl apply -f k8s/targeting-service/

# Evaluation Service
kubectl apply -f k8s/evaluation-service/

# Analytics Service
kubectl apply -f k8s/analytics-service/
```

### 5. Deploy do Ingress
```bash
kubectl apply -f k8s/ingress.yaml
```

### 6. Verificar o Deployment
```bash
# Verificar namespaces
kubectl get namespaces

# Verificar pods
kubectl get pods -n tech-challenge
kubectl get pods -n tech-challenge-db

# Verificar services
kubectl get svc -n tech-challenge
kubectl get svc -n tech-challenge-db

# Verificar ingress
kubectl get ingress -n tech-challenge

# Descrever um pod (para debug)
kubectl describe pod <pod-name> -n tech-challenge
```

## 🔄 Script de Deploy Automatizado

```bash
#!/bin/bash

echo "🚀 Iniciando deployment no Kubernetes..."

# 1. Namespaces
echo "📦 Criando namespaces..."
kubectl apply -f k8s/namespace.yaml

# Substituir ID da conta ECR
ECR_ID=${1:-123456789012}
echo "🔄 Atualizando ECR_ACCOUNT_ID para: $ECR_ID"
sed -i "s/<ECR_ACCOUNT_ID>/$ECR_ID/g" k8s/*/deployment.yaml

# 2. Databases
echo "🗄️  Deployando bancos de dados..."
kubectl apply -f k8s/databases/

# Aguardar
kubectl wait --for=condition=Ready pod -l app=auth-db -n tech-challenge-db --timeout=300s || true
kubectl wait --for=condition=Ready pod -l app=flag-db -n tech-challenge-db --timeout=300s || true
kubectl wait --for=condition=Ready pod -l app=target-db -n tech-challenge-db --timeout=300s || true
kubectl wait --for=condition=Ready pod -l app=redis -n tech-challenge --timeout=300s || true

# 3. Microsserviços
echo "🔧 Deployando microsserviços..."
kubectl apply -f k8s/auth-service/
kubectl apply -f k8s/flag-service/
kubectl apply -f k8s/targeting-service/
kubectl apply -f k8s/evaluation-service/
kubectl apply -f k8s/analytics-service/

# 4. Ingress
echo "🌐 Configurando Ingress..."
kubectl apply -f k8s/ingress.yaml

echo "✅ Deployment concluído!"
echo ""
echo "📊 Status dos pods:"
kubectl get pods -n tech-challenge -n tech-challenge-db

echo ""
echo "🌐 Ingress:"
kubectl get ingress -n tech-challenge
```

Salvar como `deploy.sh`:
```bash
chmod +x deploy.sh
./deploy.sh 123456789012  # Seu ECR Account ID
```

## 🔍 Troubleshooting

### Os pods não estão iniciando
```bash
# Ver logs
kubectl logs <pod-name> -n tech-challenge

# Ver eventos
kubectl describe pod <pod-name> -n tech-challenge

# Ver status detalhado
kubectl get pods -n tech-challenge -o wide
```

### Conexão com banco de dados falhando
```bash
# Testar conectividade para auth-db
kubectl run -it --rm debug --image=postgres:15 --restart=Never -- \
  psql -h auth-db.tech-challenge-db.svc.cluster.local -U auth -d authdb

# Sair com Ctrl+D
```

### Ingress não roteando corretamente
```bash
# Verificar ingress
kubectl describe ingress api-gateway -n tech-challenge

# Verificar NodePort do Nginx Ingress
kubectl get svc -n ingress-nginx

# Testar locally
kubectl port-forward -n ingress-nginx svc/nginx-ingress-ingress-nginx-controller 8080:80
# Depois: curl http://localhost:8080/auth
```

## 🔐 Atualizar Secrets na Produção

```bash
# Codificar um novo valor em base64
echo -n "new-password" | base64

# Atualizar um secret
kubectl patch secret auth-service-secret -n tech-challenge \
  -p '{"data":{"master-key":"'$(echo -n "new-value" | base64)'"}}'

# Forçar restart dos pods
kubectl rollout restart deployment/auth-service -n tech-challenge
```

## 📊 Monitoramento

### Ver uso de recursos
```bash
kubectl top nodes
kubectl top pods -n tech-challenge
```

### Ver logs em tempo real
```bash
kubectl logs -f deployment/auth-service -n tech-challenge
```

### Port-forward para teste local
```bash
# Auth Service
kubectl port-forward svc/auth-service 8001:8000 -n tech-challenge

# Flag Service
kubectl port-forward svc/flag-service 8002:8000 -n tech-challenge

# Depois: curl http://localhost:8001/health
```

## 🗑️ Remover Deployment

```bash
# Remover tudo em ordem reversa
kubectl delete -f k8s/ingress.yaml
kubectl delete -f k8s/analytics-service/
kubectl delete -f k8s/evaluation-service/
kubectl delete -f k8s/targeting-service/
kubectl delete -f k8s/flag-service/
kubectl delete -f k8s/auth-service/
kubectl delete -f k8s/databases/
kubectl delete -f k8s/namespace.yaml
```

## 📝 Notas Importantes

1. **Secrets em Produção:** Use AWS Secrets Manager ou Vault em produção, não base64 simples.
2. **Persistent Volumes:** Adicione PVs para dados persistentes dos bancos.
3. **Network Policies:** Implemente para maior segurança.
4. **Resource Quotas:** Configure quotas por namespace.
5. **Logging:** Configure ELK, CloudWatch ou similar.
6. **Monitoring:** Use Prometheus + Grafana.

## 📞 Referências

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [Cert-Manager](https://cert-manager.io/)
- [Docker Image Registry](https://docs.aws.amazon.com/AmazonECR/latest/userguide/)
