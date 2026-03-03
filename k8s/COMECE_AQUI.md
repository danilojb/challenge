# 🚀 Comece Aqui - Kubernetes Tech Challenge

## ⚡ 5 Minutos para Deploy

### Passo 1: Preparação
```bash
cd k8s

# Ler a documentação principal
cat README.md | head -50
```

### Passo 2: Validar Manifests
```bash
# Verificar se tudo está OK
./validate.sh
```

### Passo 3: Atualizar ECR ID
```bash
# Substitua 123456789012 pelo seu AWS Account ID
sed -i 's/<ECR_ACCOUNT_ID>/123456789012/g' **/deployment.yaml

# Verificar
grep "dkr.ecr" **/deployment.yaml | head -2
```

### Passo 4: Deploy
```bash
# Fazer deploy automático (leva 2-3 minutos)
./deploy.sh 123456789012

# Ou fazer manualmente
kubectl apply -f namespace.yaml
kubectl apply -f databases/
kubectl apply -f */
kubectl apply -f ingress.yaml
```

### Passo 5: Verificar Status
```bash
# Ver todos os pods
kubectl get pods -n tech-challenge

# Aguardar fiquem prontos (Ready)
kubectl wait --for=condition=Ready pod -l app=auth-service -n tech-challenge --timeout=300s
```

### Passo 6: Testar
```bash
# Fazer port-forward
kubectl port-forward svc/auth-service 8001:8000 -n tech-challenge

# Em outro terminal, testar
curl http://localhost:8001/health
```

**Pronto! 🎉**

---

## 📋 O que foi criado?

### Microsserviços (5)
```
auth-service          → Autenticação
flag-service          → Bandeiras/Flags
targeting-service     → Alvo/Targeting
evaluation-service    → Avaliação
analytics-service     → Análises
```

### Bancos de Dados (3 + 1)
```
PostgreSQL ×3         → auth-db, flag-db, target-db
Redis ×1              → Cache para evaluation-service
```

### Configuração
```
Namespaces ×2         → tech-challenge (app) + tech-challenge-db (dados)
Services ×9           → 1 por microsserviço
Secrets ×8            → Senhas e chaves criptografadas
ConfigMaps ×8         → URLs e configurações
Ingress ×1            → Roteamento externo (/auth, /flags, etc)
```

---

## 🔧 Comandos Úteis

### Ver Status
```bash
# Todos os pods
kubectl get pods -n tech-challenge

# Com mais detalhes
kubectl get pods -n tech-challenge -o wide

# Em tempo real
kubectl get pods -n tech-challenge -w
```

### Ver Logs
```bash
# Log de um serviço
kubectl logs deployment/auth-service -n tech-challenge

# Em tempo real
kubectl logs -f deployment/auth-service -n tech-challenge

# Últimas 100 linhas
kubectl logs deployment/auth-service -n tech-challenge --tail=100
```

### Port Forward
```bash
# Acessar um serviço localmente
kubectl port-forward svc/auth-service 8001:8000 -n tech-challenge

# Depois em outro terminal:
curl http://localhost:8001/health
```

### Descrever Pod
```bash
# Ver detalhes de um pod
kubectl describe pod auth-service-xyz -n tech-challenge

# Ver eventos
kubectl get events -n tech-challenge --sort-by='.lastTimestamp'
```

### Entrar em um Pod
```bash
# Abrir terminal no pod
kubectl exec -it <pod-name> -n tech-challenge -- /bin/bash
```

---

## 🧪 Testes Rápidos

### Test 1: Health Check
```bash
# Em um terminal:
kubectl port-forward svc/auth-service 8001:8000 -n tech-challenge

# Em outro terminal:
curl http://localhost:8001/health
# Resposta esperada: 200 OK
```

### Test 2: Conectividade Entre Serviços
```bash
# Testar do dentro do cluster
./troubleshoot.sh connectivity

# Ou manualmente:
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n tech-challenge -- \
  wget -qO- http://auth-service.tech-challenge.svc.cluster.local:8000/health
```

### Test 3: Banco de Dados
```bash
# Testar conexão com PostgreSQL
./troubleshoot.sh dbtest auth

# Ou
kubectl run -it --rm debug --image=postgres:15 --restart=Never -n tech-challenge -- \
  psql -h auth-db.tech-challenge-db.svc.cluster.local -U auth -d authdb -c "SELECT version();"
```

---

## 📊 Arquitetura Visual

```
┌─────────────────────────────────────┐
│         Internet                    │
└────────────────┬────────────────────┘
                 │ (HTTP/HTTPS)
                 ▼
        ┌────────────────────┐
        │ Nginx Ingress      │
        │ (NodePort/LoadBal) │
        └────────────────────┘
                 │
    ┌────────────┼────────────┐
    │            │            │
    ▼            ▼            ▼
/auth  /flags  /targets  /eval  /analytics
    │            │            │
    ▼            ▼            ▼
 [Services ClusterIP / Discovery DNS]
    │            │            │
    ▼            ▼            ▼
[5 Pods × 2 Replicas cada]
    │            │            │
    ├────────────┼────────────┤
    │            │            │
    ▼            ▼            ▼
[auth-db]  [flag-db]  [target-db]  [redis]
```

---

## 🔑 Variáveis de Ambiente

### Auth Service
```
PORT=8000
MASTER_KEY=admin-secreto-123
DATABASE_URL=postgres://auth:auth@auth-db:5432/authdb
```

### Flag Service
```
PORT=8000
AUTH_SERVICE_URL=http://auth-service:8000
DATABASE_URL=postgres://flag:flag@flag-db:5432/flagdb
```

### Targeting Service
```
PORT=8000
AUTH_SERVICE_URL=http://auth-service:8000
DATABASE_URL=postgres://target:target@target-db:5432/targetdb
```

### Evaluation Service
```
PORT=8000
REDIS_URL=redis://redis:6379
FLAG_SERVICE_URL=http://flag-service:8000
TARGETING_SERVICE_URL=http://targeting-service:8000
AWS_REGION=us-east-1
```

### Analytics Service
```
PORT=8000
AWS_REGION=us-east-1
AWS_DYNAMODB_TABLE=analytics
AWS_SQS_URL=http://localstack:4566/...
```

---

## ❌ Problemas Comuns

### Pod não inicia (Pending)
```bash
# Ver o que está acontecendo
kubectl describe pod <pod-name> -n tech-challenge

# Possíveis causas:
# - Recursos insuficientes (aumento de replicas)
# - Imagem não encontrada (verificar ECR ID)
# - Volume não disponível (Dev/PV issue)
```

### Pod fica em CrashLoopBackOff
```bash
# Ver logs do erro
kubectl logs <pod-name> -n tech-challenge

# Possíveis causas:
# - Erro na aplicação (bug no código)
# - Variável de ambiente faltando
# - Porto já em uso
```

### Conexão com banco falha
```bash
# Testar DNS
kubectl run -it --rm debug --image=busybox --restart=Never -- \
  nslookup auth-db.tech-challenge-db.svc.cluster.local

# Testar conectividade
./troubleshoot.sh dbtest auth
```

### Ingress não responde
```bash
# Verificar Ingress
kubectl describe ingress api-gateway -n tech-challenge

# Verificar NodePort do Nginx
kubectl get svc -n ingress-nginx

# Adicionar ao /etc/hosts:
# <INGRESS-IP>  api.techChallenge.local
```

---

## 🛠️ Usar Makefile

```bash
# Ver todos os comando
make help

# Deploy
make deploy ECR_ID=123456789012

# Status
make status

# Logs
make logs SERVICE=auth-service

# Port forward
make forward SERVICE=auth-service PORT=8001

# Testes
make test-connectivity
make test-db DB=auth

# Limpeza
make clean
```

---

## 🛠️ Usar Scripts

```bash
# Validar YAML
./validate.sh

# Deploy (automático)
./deploy.sh 123456789012 us-east-1

# Limpeza
./cleanup.sh

# Debug interativo
./troubleshoot.sh
```

---

## 📚 Documentação Detalhada

Se precisa de mais informações, veja:

| Arquivo | Para Quem |
|---------|----------|
| README.md | Setup completo |
| QUICK_REF.md | Referência rápida |
| ARCHITECTURE.md | Entender a arquitetura |
| BEST_PRACTICES.md | Produção segura |
| TESTING.md | Testar APIs |
| CHEATSHEET.md | Comandos kubectl |
| INDEX.md | Índice completo |

---

## ✅ Checklist de Verificação

Após deploy, verificar:

- [ ] Todos os pods em "Running" + "Ready"
- [ ] Services resolvem via DNS
- [ ] Port forward funciona
- [ ] Health checks passam
- [ ] Banco de dados conecta
- [ ] Ingress roteia corretamente
- [ ] Logs não mostram erros

---

## 🆘 Suporte Rápido

**Terminal interativo de debug:**
```bash
./troubleshoot.sh
```

**Ver tudo:**
```bash
./troubleshoot.sh status
```

**Problemas específicos:**
```bash
./troubleshoot.sh logs auth-service
./troubleshoot.sh describe auth-service-xyz
./troubleshoot.sh forward auth-service 8001
./troubleshoot.sh connectivity
./troubleshoot.sh dbtest auth
```

---

## 🎯 Próximos Passos

1. Deploy e testar
2. Ler BEST_PRACTICES.md para segurança
3. Configurar monitoramento
4. Adicionar persistência (PersistentVolumes)
5. Configurar logging centralizado

---

**Pronto para começar? Execute:**

```bash
cd k8s
./validate.sh
./deploy.sh 123456789012
```

**Boa sorte! 🚀**
