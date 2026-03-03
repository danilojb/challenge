# 🚀 Quick Reference - Tech Challenge K8s

## ⚡ Começar em 5 Minutos

```bash
cd k8s

# 1. Validar
./validate.sh

# 2. Deploy (substitua com seu ECR ID)
./deploy.sh 123456789012

# 3. Aguarder
kubectl rollout status deployment/auth-service -n tech-challenge

# 4. Verificar
kubectl get pods -n tech-challenge

# 5. Testar
kubectl port-forward svc/auth-service 8001:8000 -n tech-challenge
# Em outro terminal:
curl http://localhost:8001/health
```

---

## 📋 Estrutura Rápida

```
5 Microssiviços: auth | flag | targeting | evaluation | analytics
3 Banks: PostgreSQL ×3 + Redis ×1
2 Namespaces: tech-challenge | tech-challenge-db
9 Services (ClusterIP)
8 Secrets + 8 ConfigMaps
1 Ingress (roteamento /auth, /flags, etc)
```

---

## 🔑 Variáveis de Ambiente

### Auth Service
```
PORT=8000
MASTER_KEY=admin-secreto-123
DATABASE_URL=postgres://auth:auth@auth-db...
```

### Flag Service
```
PORT=8000
AUTH_SERVICE_URL=http://auth-service:8000
DATABASE_URL=postgres://flag:flag@flag-db...
```

### Targeting Service
```
PORT=8000
AUTH_SERVICE_URL=http://auth-service:8000
DATABASE_URL=postgres://target:target@target-db...
```

### Evaluation Service
```
PORT=8000
REDIS_URL=redis://redis:6379
FLAG_SERVICE_URL=http://flag-service:8000
TARGETING_SERVICE_URL=http://targeting-service:8000
AWS_REGION=us-east-1
AWS_SQS_URL=http://localstack:4566/...
```

### Analytics Service
```
PORT=8000
AWS_REGION=us-east-1
AWS_DYNAMODB_TABLE=analytics
AWS_SQS_URL=http://localstack:4566/...
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test
```

---

## 📊 Status Comandos

```bash
# Todos os pods
kubectl get pods -n tech-challenge

# Com mais detalhes
kubectl get pods -n tech-challenge -o wide

# Apenas rodando
kubectl get pods -n tech-challenge --field-selector=status.phase=Running

# Apenas falhando
kubectl get pods -n tech-challenge --field-selector=status.phase=Failed

# Services
kubectl get svc -n tech-challenge

# ConfigMaps
kubectl get configmap -n tech-challenge

# Secrets
kubectl get secrets -n tech-challenge

# Ingress
kubectl get ingress -n tech-challenge

# Eventos
kubectl get events -n tech-challenge --sort-by='.lastTimestamp'
```

---

## 🔍 Debug Rápido

```bash
# Logs
kubectl logs -f deployment/auth-service -n tech-challenge

# Describir pod
kubectl describe pod <pod-name> -n tech-challenge

# Terminal no pod
kubectl exec -it <pod-name> -n tech-challenge -- /bin/bash

# Port forward
kubectl port-forward svc/auth-service 8001:8000 -n tech-challenge

# Copy arquivo
kubectl cp tech-challenge/<pod>:/file.txt ./file.txt

# Ver recurso em YAML
kubectl get pod <pod> -n tech-challenge -o yaml

# Watch em tempo real
kubectl get pods -n tech-challenge -w
```

---

## 📍 URLs de Teste

```
Auth:       http://api.techChallenge.local/auth/health
Flags:      http://api.techChallenge.local/flags/health
Targets:    http://api.techChallenge.local/targets/health
Evaluation: http://api.techChallenge.local/evaluations/health
Analytics:  http://api.techChallenge.local/analytics/health
```

---

## 🔧 Makefile Commands

```bash
make help                     # Ver todos
make deploy ECR_ID=...       # Deploy
make validate                # Validar
make clean                   # Remover
make status                  # Status dos pods
make logs SERVICE=auth       # Logs
make resources               # CPU/RAM
make forward SERVICE=... PORT=...  # Port-forward
make test-connectivity       # Testar conectividade
make test-db DB=auth         # Testar banco
```

---

## 🆘 Problemas Comuns

| Problema | Solução |
|----------|---------|
| Pod stuck "Pending" | `kubectl describe pod <name>` - check node resources |
| Pod stuck "CrashLoopBackOff" | `kubectl logs <pod>` - check application errors |
| Conexão DB falha | `./troubleshoot.sh dbtest <db>` |
| Conexão entre serviços com erro | `./troubleshoot.sh connectivity` |
| Ingress não responde | `kubectl describe ingress api-gateway -n tech-challenge` |

---

## 🎯 Deployment Flow

```
1. Validar:     ./validate.sh
2. Criar NS:    kubectl apply -f namespace.yaml
3. Criar DBs:   kubectl apply -f databases/
4. Esperar:     kubectl wait --for=condition=Ready pod -l app=redis
5. Criar Apps:  kubectl apply -f *-service/
6. Criar ING:   kubectl apply -f ingress.yaml
7. Testar:      curl http://localhost:8001/health
```

---

## 🔐 Secrets Encoding

```bash
# Codificar
echo -n "valor" | base64

# Decodificar
kubectl get secret <name> -n tech-challenge \
  -o jsonpath='{.data.key}' | base64 -d

# Atualizar
kubectl patch secret <name> -n tech-challenge \
  -p '{"data":{"key":"'$(echo -n "novo_valor" | base64)'"}}'
```

---

## 📈 Escalar

```bash
# Aumentar replicas
kubectl scale deployment/auth-service \
  --replicas=5 -n tech-challenge

# HPA automático (se configurado)
kubectl get hpa -n tech-challenge
```

---

## 🔄 Atualizar Deployment

```bash
# Método 1: Imagem
kubectl set image deployment/auth-service \
  auth-service=new-image:tag -n tech-challenge

# Método 2: Edit
kubectl edit deployment/auth-service -n tech-challenge

# Ver status
kubectl rollout status deployment/auth-service -n tech-challenge

# Voltar
kubectl rollout undo deployment/auth-service -n tech-challenge
```

---

## 📊 Monitoramento

```bash
# CPU/RAM dos nodes
kubectl top nodes

# CPU/RAM dos pods
kubectl top pods -n tech-challenge

# Ver alertas
kubectl describe node <node-name>

# Status do API server
kubectl get componentstatuses
```

---

## 🗑️ Limpeza

```bash
# Remove específico
kubectl delete deployment/auth-service -n tech-challenge

# Remove tudo no namespace
kubectl delete all --all -n tech-challenge

# Remove namespace inteiro
kubectl delete namespace tech-challenge

# Remove via arquivo
kubectl delete -f k8s/
```

---

## 📞 Referências Rápidas

- **README.md** - Setup completo
- **BEST_PRACTICES.md** - Segurança/Produção
- **CHEATSHEET.md** - Comandos detalhados
- **ARCHITECTURE.md** - Design da solução
- **TESTING.md** - Testes de API

---

**Última referência: 2024**
